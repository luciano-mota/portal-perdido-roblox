--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local services=script.Parent:WaitForChild("Services")
local Data=require(services.PlayerDataService)
local Classes=require(services.ClassService)
local World=require(services.WorldBuilder)
local Quests=require(services.QuestService)
local Enemies=require(services.EnemyService)
local Expedition=require(services.ExpeditionService)
local Regions=require(services.Regions)
local Travel=require(services.TravelService)
local folder=ReplicatedStorage:FindFirstChild("GameRemotes")
if not folder then folder=Instance.new("Folder") folder.Name="GameRemotes" folder.Parent=ReplicatedStorage end
local function remote(name: string): RemoteEvent
	local found=folder:FindFirstChild(name)
	if found and found:IsA("RemoteEvent") then return found end
	local event=Instance.new("RemoteEvent") event.Name=name event.Parent=folder return event
end
local choose=remote("ChooseClass")
local attack=remote("AttackEnemy")
local skill=remote("UseSkill")
local dash=remote("Dash")
local notify=remote("Notify")
local block=remote("Block")
local kick=remote("Kick")
local crouch=remote("Crouch")
World.build()
local world=workspace:WaitForChild("PortalChapter") :: Model
Classes.spawnResolver=Travel.spawnFor
Expedition.init()
Classes.init(choose)
Quests.init(notify,Enemies.isAlive)
Enemies.init(attack,skill,dash,notify,Quests,block,kick,crouch)
Data.init(function(player)
	Classes.register(player)
	Quests.register(player)
end)
-- Regiões 2–6 depois do Vale e dos serviços: quem entra já joga enquanto elas são montadas.
Regions.build(world)
-- Templates das criaturas geradas: reconstruídos dos dados versionados se faltarem no lugar.
require(services.CreatureMeshes).ensure()
Enemies.spawnRegional()
Travel.init(world,notify)

local Players=game:GetService("Players")
local Campaign=require(ReplicatedStorage.Shared.Config.Campaign)
local REGION_NAMES={Lumen="Vale de Lúmen",CrystalAbyss="Abismo de Cristal",HourDesert="Deserto das Horas",EclipseCitadel="Cidadela do Eclipse"}
-- Início da expedição: na Rota B cada um desperta na região sorteada (o Vale fica onde está).
Expedition.onBegin(function(route,assignment)
	if route~="B" then
		for player in assignment do notify:FireClient(player,{kind="toast",text="Jornada iniciada: fase a fase, a partir do Vale de Lúmen."}) end
		return
	end
	for player,region in assignment do
		local companions=0
		for other,otherRegion in assignment do if other~=player and otherRegion==region then companions+=1 end end
		local note="O apagão espalhou o grupo. Você despertou "..(if companions==0 then "sozinho(a)" else "com "..companions.." companheiro(s)").." em "..(REGION_NAMES[region] or region)..". Vença o guardião daqui para reencontrar os outros."
		if region=="Lumen" then notify:FireClient(player,{kind="toast",text=note})
		else Travel.send(player,region,nil,note) end
	end
end)
-- Chefão final de uma região vencido: abre a passagem (Rota A: progresso do perfil e heróis;
-- Rota B: ramo resolvido). A visão do Regente é disparada pelo EnemyService.
local HERO_BY_PHASE={[1]="Brawler",[2]="Arcanist",[3]="Shade"}
local HERO_NAMES={Brawler="LUTADOR SOLAR",Arcanist="ARCANISTA",Shade="VÉU"}
-- Recompensa única por chefão das fases 2–6 (o Vale já paga pelas cinco missões). Quem estava
-- na arena recebe uma vez por conta; repetir a fase não duplica (chave "phase<n>").
local PHASE_REWARD={[2]=150,[3]=200,[4]=250,[5]=300,[6]=500}
local function rewardBoss(region: any,center: Vector3)
	local amount=PHASE_REWARD[region.order]
	if not amount then return end
	local key="phase"..region.order
	for _,player in Players:GetPlayers() do
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") or (root.Position-center).Magnitude>220 then continue end
		local paid=false
		Data.mutate(player,function(profile)
			if not profile.rewards[key] then profile.rewards[key]=true profile.coins+=amount paid=true end
		end)
		if paid then
			task.delay(4,function() notify:FireClient(player,{kind="quest",text="FASE "..region.order.." CONCLUÍDA · "..region.name,coins=amount}) end)
			task.spawn(Data.save,player,false)
		end
	end
end
Enemies.onBossDefeated=function(regionId: string,center: Vector3)
	local region=Campaign.get(regionId)
	if not region then return end
	rewardBoss(region,center)
	if Expedition.route()=="B" then
		Expedition.resolve(regionId)
		return
	end
	for _,player in Players:GetPlayers() do
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") or (root.Position-center).Magnitude>220 then continue end
		Data.mutate(player,function(profile) profile.phase=math.max(profile.phase or 0,region.order) end)
		local hero=HERO_BY_PHASE[region.order]
		if hero and Classes.unlock(player,hero) then
			task.delay(16,function() notify:FireClient(player,{kind="quest",text="NOVO HERÓI: "..HERO_NAMES[hero].." — disponível nos pontos seguros",coins=0}) end)
		end
		task.spawn(Data.save,player,false)
	end
end
-- Rota B: morrer elimina da expedição atual (a conta não perde nada).
local function watchDeaths(player: Player)
	player.CharacterAdded:Connect(function(character)
		local humanoid=character:WaitForChild("Humanoid",10)
		if humanoid and humanoid:IsA("Humanoid") then
			humanoid.Died:Connect(function()
				if Expedition.route()=="B" and Expedition.isMember(player) and not Expedition.isEliminated(player) then
					Expedition.eliminate(player)
					notify:FireClient(player,{kind="toast",text="Você caiu nesta expedição. Acompanhe o grupo da Convergência."})
				end
			end)
		end
	end)
end
Players.PlayerAdded:Connect(watchDeaths)
for _,player in Players:GetPlayers() do watchDeaths(player) end

-- Controles de toque configuráveis: o cliente envia o layout; o servidor valida, guarda no
-- perfil (persistido com o restante) e devolve como atributo. Sem efeito em jogabilidade.
local ControlLayout=require(ReplicatedStorage.Shared.ControlLayout)
local lastControlsSave: {[Player]: number}={}
remote("SaveControls").OnServerEvent:Connect(function(player: Player,value: any)
	local now=os.clock()
	if now-(lastControlsSave[player] or -math.huge)<2 then return end
	lastControlsSave[player]=now
	-- nil = voltar ao padrão.
	local clean=if value==nil then nil else ControlLayout.sanitize(value)
	if value~=nil and not clean then return end
	Data.mutate(player,function(profile) profile.controls=clean end)
	task.spawn(Data.save,player,false)
end)
Players.PlayerRemoving:Connect(function(player) lastControlsSave[player]=nil end)
-- Ganchos de QA apenas no Studio: BindableFunction em ServerStorage não é acessível
-- pelo cliente e não existe em servidores publicados. Usado por testes via MCP, que
-- executam em outra VM e não compartilham o estado dos módulos.
if game:GetService("RunService"):IsStudio() then
	local qa=Instance.new("BindableFunction") qa.Name="QAFixtures"
	qa.OnInvoke=function(op: string,player: Player?,value: any)
		if op=="beginSolo" then Expedition.MinimumPlayers=1 return Expedition.tryBegin() end
		if op=="travel" and player and typeof(value)=="string" then return Travel.send(player,value) end
		if op=="hurtEnemy" and player and typeof(value)=="table" and typeof(value.id)=="string" and typeof(value.amount)=="number" then return Enemies.debugDamage(player,value.id,value.amount) end
		if op=="setPhase" and player and typeof(value)=="number" then Data.mutate(player,function(profile) profile.phase=value end) Classes.publishAvailable(player) return value end
		if op=="distribute" and typeof(value)=="number" then
			local fake={} for i=1,value do table.insert(fake,{UserId=i,Name="P"..i}) end
			local result=Expedition.distribute(fake :: any,os.clock()*1000) local counts={}
			for _,region in result do counts[region]=(counts[region] or 0)+1 end return counts
		end
		if op=="openGates" then workspace:SetAttribute("CampaignOpenGates",value==true) return value==true end
		if op=="setQuest" and player and typeof(value)=="number" then
			Data.mutate(player,function(profile) profile.quest=value end) return Data.get(player).quest
		end
		return nil
	end
	qa.Parent=game:GetService("ServerStorage")
end
print("[PortalPerdido] Capítulo 1 pronto: cinco missões, três classes, floresta, templo e Guardião.")
