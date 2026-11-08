--!strict
-- Conexões entre as seis regiões (docs/CAMPAIGN_SIX_PHASES.md).
-- Cada região construída tem: marcador "Arrival" (e, na Convergência, "Arrival_<origem>"),
-- pontos seguros (Kind=SafePoint) e um modelo "ExitGate" com a peça "Rift" do prompt.
-- O servidor decide destino e liberação; o cliente só pede pelo ProximityPrompt.
--
-- Estado da sessão (não persistido ainda): região atual e último ponto seguro de cada jogador.
-- Persistir progresso de campanha e a rota congelada da expedição é etapa de jogabilidade.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Campaign=require(ReplicatedStorage.Shared.Config.Campaign)
local Chapter=require(ReplicatedStorage.Shared.Config.Chapter)
local Data=require(script.Parent.PlayerDataService)
local Enemies=require(script.Parent.EnemyService)
local Expedition=require(script.Parent.ExpeditionService)
local TweenService=game:GetService("TweenService")

local Travel={}

type RegionInfo={model: Model?, arrivals: {[string]: CFrame}, safe: {BasePart}}
local regions: {[string]: RegionInfo}={}
local current: {[Player]: string}={}
local lastSafe: {[Player]: CFrame}={}
local lastUse: {[Player]: number}={}
-- Cura nos pontos seguros das regiões 2–6 (o Vale tem as Fontes de Lúmen), com recarga.
local lastHeal: {[Player]: number}={}
local HEAL_COOLDOWN=20
local notify: RemoteEvent?=nil

local function message(player: Player,text: string)
	player:SetAttribute("QuestMessage",text)
	if notify then notify:FireClient(player,{kind="toast",text=text}) end
end

local function route(): string
	local value=workspace:GetAttribute("CampaignRoute")
	return if value=="B" then "B" else "A"
end

function Travel.regionOf(player: Player): string
	return current[player] or "Lumen"
end

-- Ponto de renascimento fora do Vale (o Vale usa os checkpoints do capítulo).
function Travel.spawnFor(player: Player): CFrame?
	-- Eliminado na Rota B: acompanha a expedição do terraço do seu ramo na Convergência.
	if Expedition.isEliminated(player) then
		local convergence=regions.Convergence
		local branch=Expedition.regionOf(player)
		if convergence then return (branch and convergence.arrivals[branch]) or convergence.arrivals.default end
	end
	local id=current[player]
	if not id or id=="Lumen" then return nil end
	return lastSafe[player] or (regions[id] and regions[id].arrivals.default)
end

local function setRegion(player: Player,id: string,safe: CFrame?)
	current[player]=id
	lastSafe[player]=safe
	player:SetAttribute("Region",id)
end

-- Leva o jogador ao ponto de chegada de `id`. `from` escolhe a chegada específica (Convergência).
function Travel.send(player: Player,id: string,from: string?,note: string?): boolean
	local info=regions[id]
	local character=player.Character
	if not info or not character then return false end
	local target=(from and info.arrivals[from]) or info.arrivals.default
	if id=="Lumen" then target=CFrame.new(Chapter.Checkpoints.Village) end
	if not target then return false end
	-- StreamingEnabled: pedir a região antes de mover, para o chão já existir no cliente.
	pcall(function() player:RequestStreamAroundAsync(target.Position,8) end)
	if player.Character~=character then return false end
	local root=character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then root.AssemblyLinearVelocity=Vector3.zero end
	character:PivotTo(target)
	setRegion(player,id,if id=="Lumen" then nil else target)
	if id=="Convergence" and route()=="B" and not Expedition.branchesResolved() and not note then
		note="Vocês chegaram primeiro. Aguardem: outros viajantes ainda lutam em suas regiões."
	end
	-- O nome da região aparece na faixa do cliente (RegionAtmosphere); aqui só notas extras.
	if note then message(player,note) end
	return true
end

local function unlocked(player: Player,fromId: string): (boolean,string?)
	if workspace:GetAttribute("CampaignOpenGates")==true then return true,nil end
	local region=Campaign.get(fromId)
	if not region then return false,nil end
	if Expedition.isEliminated(player) then return false,"Você caiu nesta expedição. Acompanhe o grupo até o fim." end
	-- Só se passa de fase vencendo o chefão da região (Rota A: progresso do perfil;
	-- Rota B: ramo resolvido nesta expedição).
	if route()=="B" then
		if Expedition.isResolved(fromId) then return true,nil end
	else
		local profile=Data.get(player)
		if profile and ((profile.phase or 0)>=region.order or (fromId=="Lumen" and profile.quest>5)) then return true,nil end
	end
	if fromId=="Lumen" then return false,"A passagem só desperta depois que o Guardião de Raízes cair e o Fragmento da Aurora for recolhido." end
	return false,"A passagem só desperta quando o guardião desta região for vencido."
end

local function bindGate(fromId: string,rift: BasePart)
	local prompt=Instance.new("ProximityPrompt")
	prompt.Name="Travel" prompt.ActionText="Atravessar" prompt.ObjectText="Passagem"
	prompt.HoldDuration=0.6 prompt.MaxActivationDistance=14 prompt.RequiresLineOfSight=false
	prompt.Parent=rift
	prompt.Triggered:Connect(function(player)
		local now=os.clock()
		if now-(lastUse[player] or -math.huge)<2 then return end
		lastUse[player]=now
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") or (root.Position-rift.Position).Magnitude>22 then return end
		local ok,reason=unlocked(player,fromId)
		if not ok then message(player,reason or "A passagem está fechada.") return end
		local nextId=Campaign.nextRegion(fromId,route())
		if not nextId then
			-- Domínio do Vazio: o Portal Primordial (aberto pela queda do Regente) leva de volta ao Vale.
			Travel.send(player,"Lumen",nil,"Por um instante, vocês veem o ginásio da escola do outro lado do portal... e despertam de novo no Vale de Lúmen. Fale com Ilyra.")
			return
		end
		Travel.send(player,nextId,fromId)
	end)
end

-- Portal escondido (sem luz, sem colisão, sem prompt) até o encontro `encounter` ser vencido;
-- depois da visão do Regente ele surge devagar. Na fase 5 isso faz a arena parecer o fim.
function Travel.conceal(gate: Instance,encounter: string)
	local parts: {BasePart}={}
	for _,item in gate:GetDescendants() do
		if item:IsA("BasePart") then
			item:SetAttribute("RevealTransparency",item.Transparency)
			item:SetAttribute("RevealCollide",item.CanCollide)
			item.Transparency=1 item.CanCollide=false
			table.insert(parts,item)
		elseif item:IsA("ProximityPrompt") or item:IsA("BillboardGui") or item:IsA("Light") then
			(item :: any).Enabled=false
		end
	end
	gate:SetAttribute("Concealed",true)
	task.spawn(function()
		while Enemies.isAlive(encounter) do task.wait(1) end
		-- Espera a fenda do Regente (2,4 s + 11 s) antes de revelar o caminho.
		task.wait(14)
		for _,part in parts do
			TweenService:Create(part,TweenInfo.new(3),{Transparency=part:GetAttribute("RevealTransparency") or 0}):Play()
			part.CanCollide=part:GetAttribute("RevealCollide")==true
		end
		for _,item in gate:GetDescendants() do
			if item:IsA("ProximityPrompt") or item:IsA("BillboardGui") or item:IsA("Light") then (item :: any).Enabled=true end
		end
		gate:SetAttribute("Concealed",false)
		if notify then notify:FireAllClients({kind="toast",text="Um portal se abre no alto da escadaria. O verdadeiro inimigo espera além dele."}) end
	end)
end

function Travel.init(world: Model,remote: RemoteEvent)
	notify=remote
	for _,region in Campaign.Regions do
		local model=if region.id=="Lumen" then world else world:FindFirstChild(region.id)
		local info: RegionInfo={model=if model and model:IsA("Model") then model else nil,arrivals={},safe={}}
		regions[region.id]=info
		if not model then
			if region.id~="Lumen" then warn("[PortalPerdido][Travel] Região sem cenário: "..region.id) end
			continue
		end
		for _,item in model:GetDescendants() do
			if item:IsA("BasePart") and item:GetAttribute("Kind")=="SafePoint" then
				table.insert(info.safe,item)
				if item.Name=="Arrival" then info.arrivals.default=item.CFrame
				elseif item.Name:sub(1,8)=="Arrival_" then info.arrivals[item.Name:sub(9)]=item.CFrame end
			end
		end
		local gate=model:FindFirstChild("ExitGate",true)
		local rift=gate and gate:FindFirstChild("Rift")
		if rift and rift:IsA("BasePart") then bindGate(region.id,rift)
		else warn("[PortalPerdido][Travel] Região sem portal de saída: "..region.id) end
		if gate and region.exitRevealedBy then Travel.conceal(gate,region.exitRevealedBy) end
	end
	workspace:SetAttribute("CampaignRoute",workspace:GetAttribute("CampaignRoute") or "A")
	-- Região atual por posição, último ponto seguro alcançado e quedas no vazio de cada região.
	task.spawn(function()
		while true do
			for _,player in Players:GetPlayers() do
				local character=player.Character
				local root=character and character:FindFirstChild("HumanoidRootPart")
				local humanoid=character and character:FindFirstChildOfClass("Humanoid")
				if not character or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health<=0 then continue end
				local region=Campaign.regionAt(root.Position)
				if current[player]~=region.id then setRegion(player,region.id,regions[region.id] and regions[region.id].arrivals.default) end
				if region.id=="Lumen" then continue end
				local info=regions[region.id]
				if root.Position.Y<region.origin.Y+region.voidY then
					local safe=lastSafe[player] or (info and info.arrivals.default)
					if safe then
						root.AssemblyLinearVelocity=Vector3.zero
						character:PivotTo(safe)
						humanoid:TakeDamage(math.max(0,math.min(10,humanoid.Health-1)))
						message(player,"O vazio devolveu você ao último ponto seguro.")
					end
				elseif info then
					for _,point in info.safe do
						local radius=(point:GetAttribute("Radius") :: number?) or 8
						if (point.Position-root.Position).Magnitude<radius then
							lastSafe[player]=point.CFrame
							if humanoid.Health<humanoid.MaxHealth and os.clock()-(lastHeal[player] or -math.huge)>=HEAL_COOLDOWN and not Enemies.threatNear(root.Position,40) then
								lastHeal[player]=os.clock()
								humanoid.Health=humanoid.MaxHealth
								message(player,"Ponto seguro: vida restaurada.")
							end
							break
						end
					end
				end
			end
			task.wait(0.4)
		end
	end)
	Players.PlayerRemoving:Connect(function(player) current[player]=nil lastSafe[player]=nil lastUse[player]=nil lastHeal[player]=nil end)
end

return Travel
