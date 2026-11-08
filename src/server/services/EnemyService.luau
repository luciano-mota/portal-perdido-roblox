--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local PathfindingService=game:GetService("PathfindingService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Chapter=require(ReplicatedStorage.Shared.Config.Chapter)
local Classes=require(ReplicatedStorage.Shared.Config.Classes)
local Art=require(ReplicatedStorage.Shared.Art)
local Data=require(script.Parent.PlayerDataService)
local Expedition=require(script.Parent.ExpeditionService)
local Service={}
-- Chamado quando cai um chefão final de região (definition.vision = id da região).
Service.onBossDefeated=nil :: ((string,Vector3) -> ())?
local records: {[string]: any}={}
local lastAttack: {[Player]: number}={}
local lastSkill: {[Player]: number}={}
local lastDash: {[Player]: number}={}
local lastKick: {[Player]: number}={}
local notify: RemoteEvent
local quests: any

local function playerRoot(player: Player): (BasePart?,Humanoid?)
	local p=Data.get(player)
	local character=player.Character
	if not p or not p.classId or not character then return nil,nil end
	local root=character:FindFirstChild("HumanoidRootPart")
	local humanoid=character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health<=0 then return nil,nil end
	return root,humanoid
end

-- Chão do vale em camadas: terreno e peças do mundo (pisos de platôs, ilhas, pedras).
local function groundParams(): RaycastParams
	local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
	local world=workspace:FindFirstChild("PortalChapter")
	params.FilterDescendantsInstances=if world then {world,workspace.Terrain} else {workspace.Terrain}
	-- Copas, névoa e flores não colidem: não contam como chão.
	params.RespectCanCollide=true
	return params
end

local function groundAt(position: Vector3): number
	local hit=workspace:Raycast(Vector3.new(position.X,position.Y+60,position.Z),Vector3.new(0,-(position.Y+160),0),groundParams())
	return if hit then hit.Position.Y else Chapter.GroundY
end

-- Criaturas andam no plano do encontro: só avançam onde há piso perto dessa cota,
-- para não caminhar no ar além da borda de platôs, ilhas e garganta.
local function hasFloor(record: any,position: Vector3): boolean
	local from=Vector3.new(position.X,record.groundY+4,position.Z)
	local hit=workspace:Raycast(from,Vector3.new(0,-7,0),groundParams())
	return hit~=nil and hit.Position.Y>record.groundY-2.5
end

local function lineOfSight(player: Player, record: any): boolean
	local root=playerRoot(player)
	if not root then return false end
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	-- Não existe PvP: companheiros não são cobertura contra ataques aliados.
	-- A geometria do mundo continua no raio, preservando paredes/obstáculos.
	-- Criaturas agrupadas não podem se tornar cobertura mútua invulnerável.
	-- O alvo mais próximo continua recebendo o golpe; cenário permanece no raio.
	local excluded: {Instance}={workspace.PortalEnemies}
	for _,ally in Players:GetPlayers() do
		if ally.Character then table.insert(excluded,ally.Character) end
	end
	params.FilterDescendantsInstances=excluded
	return workspace:Raycast(root.Position,record.root.Position-root.Position,params)==nil
end

-- Colossos: Arauto (fase 5) e chefões finais das regiões 2–4 (stats.ai == "Herald").
local function colossus(record: any): boolean
	return record.definition.kind=="Herald" or record.stats.ai=="Herald"
end

-- Comportamento de combate: colossos usam o do Arauto; criaturas novas, o arquétipo em stats.ai.
local function aiOf(record: any): string
	if colossus(record) then return "Herald" end
	return record.stats.ai or record.definition.kind
end

local function eligible(player: Player, record: any): boolean
	local root=playerRoot(player)
	if not root then return false end
	if not Expedition.hasStarted() then return false end
	if Expedition.isEliminated(player) then return false end
	-- Arauto (fase 5): quem está na arena da Convergência participa.
	if record.definition.kind=="Herald" or record.definition.group=="Herald" then
		if not Expedition.branchesResolved() then return false end
		return (root.Position-record.origin).Magnitude<=record.definition.leash+14
	end
	-- Chefão de região (e seus reforços): quem está na arena participa.
	local leader=if record.definition.group then records[record.definition.group] else record
	if leader and leader.stats.ai=="Herald" then
		return (root.Position-leader.origin).Magnitude<=leader.definition.leash+14
	end
	if record.definition.kind=="Boss" or record.definition.group=="RootGuardian" then
		local p=Data.get(player)
		return p.quest==5 and (root.Position-record.origin).Magnitude<=48
	end
	return true
end

local function makeRecord(definition: any)
	local kind=Chapter.EnemyTypes[definition.kind]
	-- Altura pelo piso real do local (platôs, ilha da arena), não por cota fixa.
	local ground=groundAt(Vector3.new(definition.position.X,definition.groundFromY or 200,definition.position.Z))
	local origin=Vector3.new(definition.position.X,ground+(if definition.kind=="Boss" or kind.big then 7 else 3),definition.position.Z)
	local model=Art.enemy(workspace.PortalEnemies,definition.kind,origin,kind.color)
	model.Name=definition.id
	model:SetAttribute("EnemyKind",definition.kind)
	-- Arquétipo de movimento para a apresentação no cliente (criaturas novas reaproveitam poses).
	model:SetAttribute("MotionKind",kind.ai or definition.kind)
	if kind.flier then model:SetAttribute("Flier",true) end
	model:SetAttribute("EncounterGroup",definition.group or definition.id)
	model:SetAttribute("DisplayName",kind.name)
	model:SetAttribute("Health",kind.health)
	model:SetAttribute("MaxHealth",kind.health)
	model:SetAttribute("Phase",1)
	local root=model.PrimaryPart :: BasePart
	-- Corpo lógico sólido: jogadores não atravessam a criatura (a malha visual continua sem colisão).
	root.CanCollide=true
	Art.label(root,kind.name,nil,Color3.fromRGB(234,224,202),if definition.kind=="Boss" or kind.big then 11 else 5)
	-- Barra de vida de colosso no HUD (o Guardião de Raízes mantém a regra própria da missão 5).
	if kind.big then model:SetAttribute("BossBar",true) model:SetAttribute("BossTitle",kind.title or kind.name) end
	records[definition.id]={definition=definition,stats=kind,model=model,root=root,origin=origin,groundY=ground,hp=kind.health,max=kind.health,phase=1,contributors={},casting=false,nextCast=0,slowUntil=0,engaged=false}
end

function Service.isAlive(id: string): boolean
	local r=records[id]
	if r and (r.hp>0 or r.pendingReinforcements) then return true end
	for _,child in records do if child.definition.group==id and child.hp>0 then return true end end
	return false
end

local function callReinforcements(record: any)
	if record.definition.group or record.reinforcementsCalled then return end
	record.reinforcementsCalled=true record.pendingReinforcements=true
	-- Reforços pela quantidade de viajantes: 1 sozinho, 2 em grupo pequeno, 3 com 5–6.
	local players=Expedition.readyCount()
	local count=if players>=5 then 3 elseif players>=2 then 2 else 1
	notify:FireAllClients({kind="toast",text=record.stats.name.." chamou reforços! Protejam os companheiros."})
	record.model:SetAttribute("ReinforcementsCalled",true)
	-- Reforços da fauna da região (o Vale usa Predador e Eco; cada mundo tem as suas criaturas).
	local fauna=Chapter.RegionFauna[record.definition.region or "Lumen"] or Chapter.RegionFauna.Lumen
	record.waves=(record.waves or 0)+1
	local wave=record.waves
	task.delay(2,function()
		-- Líder já caiu (ex.: golpe único): não convoca mais ninguém.
		if record.hp<=0 then record.pendingReinforcements=false return end
		for i=1,count do
			local a=i*math.pi*2/count+0.8
			-- Dentro do piso do encontro: platôs pequenos usam corrente curta.
			local spread=math.min(10,record.definition.leash*0.6)
			local pos=record.origin+Vector3.new(math.cos(a)*spread,0,math.sin(a)*spread)
			-- Novos encontros finitos; nunca renascer o inimigo derrotado.
			makeRecord({id=record.definition.id.."_Reinforcement_"..(if wave>1 then wave.."_" else "")..i,kind=fauna[(i-1)%#fauna+1],region=record.definition.region,
				position=Vector3.new(pos.X,3,pos.Z),leash=record.definition.leash,group=record.definition.id,groundFromY=record.groundY-45})
		end
		record.pendingReinforcements=false
	end)
end

-- Definido depois de `stun` (atordoa a criatura que acertou um escudo no tempo certo).
local onParry: ((Player,Vector3) -> ())?=nil

local function hurtPlayer(player: Player,amount: number,position: Vector3)
	local root,humanoid=playerRoot(player)
	if not humanoid or not root then return end
	-- Invencível durante a esquiva.
	local dodgeUntil=player:GetAttribute("DodgeUntil")
	if typeof(dodgeUntil)=="number" and dodgeUntil>workspace:GetServerTimeNow() then
		notify:FireClient(player,{kind="evade",position=root.Position})
		return
	end
	local shield=player:GetAttribute("ShieldUntil")
	local reduced=typeof(shield)=="number" and shield>workspace:GetServerTimeNow()
	local factor=if reduced then 0.35 else 1
	-- Bloqueio com escudo (Guardião): só vale para golpes vindos da frente (cone de ~140°).
	local blocked=false
	if player:GetAttribute("Blocking")==true then
		local toHit=Vector3.new(position.X-root.Position.X,0,position.Z-root.Position.Z)
		local look=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
		if toHit.Magnitude<1.5 or (look.Magnitude>0.1 and look.Unit:Dot(toHit.Unit)>0.35) then blocked=true factor=math.min(factor,0.15) end
	end
	-- Aparo: escudo erguido até 0,35 s antes do golpe anula o dano e atordoa quem atacou.
	local parried=false
	if blocked then
		local started=player:GetAttribute("BlockStartedAt")
		if typeof(started)=="number" and workspace:GetServerTimeNow()-started<=0.35 then parried=true factor=0 end
	end
	local damage=math.floor(amount*factor)
	if damage>0 then humanoid:TakeDamage(damage) end
	notify:FireClient(player,{kind="hurt",amount=damage,shielded=reduced,blocked=blocked,position=position})
	if parried then
		notify:FireAllClients({kind="parry",userId=player.UserId,position=root.Position})
		if onParry then onParry(player,position) end
	elseif blocked then notify:FireAllClients({kind="block",userId=player.UserId,position=root.Position}) end
end

-- Defesa com escudo: o cliente pede, o servidor valida classe/vida e aplica a lentidão.
-- Velocidade do jogador a partir dos estados ativos (preso > defendendo > normal).
local function refreshSpeed(player: Player)
	local _,humanoid=playerRoot(player)
	if not humanoid then return end
	local snared=(player:GetAttribute("SnaredUntil") or 0)>workspace:GetServerTimeNow()
	humanoid.WalkSpeed=if snared then 3 elseif player:GetAttribute("Blocking")==true then 9 elseif player:GetAttribute("Crouching")==true then 7 else 16
	-- Agachado não pula (o pulo cancela o agachamento no cliente).
	if humanoid.UseJumpPower then humanoid.JumpPower=if player:GetAttribute("Crouching")==true then 0 else 50
	else humanoid.JumpHeight=if player:GetAttribute("Crouching")==true then 0 else 7.2 end
end

-- Agachar: estado pedido pelo cliente (segurar Ctrl / botão). Usado pela rasteira e pelo
-- gancho do Lutador; replicado aos outros clientes como atributo.
local function setCrouching(player: Player,wanted: any)
	local root,humanoid=playerRoot(player)
	local active=wanted==true and root~=nil and humanoid~=nil
	if (player:GetAttribute("Crouching")==true)==active then return end
	player:SetAttribute("Crouching",active)
	refreshSpeed(player)
end

-- No ar: distância do quadril ao chão maior que a altura em pé (+ folga). O servidor mede;
-- o cliente só pede a variante do golpe.
local function airborne(player: Player): boolean
	local root,humanoid=playerRoot(player)
	if not root or not humanoid then return false end
	local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={player.Character :: Instance,workspace:FindFirstChild("PortalEnemies") or workspace.Terrain}
	local standing=humanoid.HipHeight+root.Size.Y*0.5
	local hit=workspace:Raycast(root.Position,Vector3.new(0,-(standing+12),0),params)
	return hit==nil or (root.Position.Y-hit.Position.Y)>standing+1.3
end

-- Atordoamento (rasteira, chute voador, golpes do Lutador). Chefes não caem: só ficam lentos.
local function stun(record: any,seconds: number)
	if record.hp<=0 then return end
	if record.definition.kind=="Boss" or record.stats.big then
		record.slowUntil=math.max(record.slowUntil,os.clock()+seconds*0.6)
		return
	end
	-- Imunidade curta depois de cada atordoamento: rasteiras/ganchos seguidos não travam o
	-- alvo para sempre.
	local now=os.clock()
	if (record.stunImmuneUntil or 0)>now then return end
	record.stunUntil=now+seconds
	record.stunImmuneUntil=now+seconds+1.5
	if record.motion then record.motion:Cancel() end
	record.model:SetAttribute("StunnedUntil",workspace:GetServerTimeNow()+seconds)
	notify:FireAllClients({kind="stun",position=record.root.Position,duration=seconds})
end

-- Aparo: atordoa as criaturas comuns que estão bem perto de onde o golpe veio.
onParry=function(player: Player,position: Vector3)
	for _,record in records do
		if record.hp>0 and (record.root.Position-position).Magnitude<=10 then stun(record,1.2) end
	end
end

local function setBlocking(player: Player,wanted: any)
	local root,humanoid=playerRoot(player)
	local p=Data.get(player)
	local active=wanted==true and root~=nil and humanoid~=nil and p~=nil and p.classId=="Guardian"
	if (player:GetAttribute("Blocking")==true)==active then return end
	player:SetAttribute("Blocking",active)
	if active then player:SetAttribute("BlockStartedAt",workspace:GetServerTimeNow()) end
	refreshSpeed(player)
end

local function damage(player: Player,record: any,amount: number)
	if record.hp<=0 then return end
	callReinforcements(record)
	if record.definition.kind=="Boss" and not record.engaged then
		record.engaged=true local count=0
		for _, participant in Players:GetPlayers() do if eligible(participant,record) then count+=1 end end
		record.max=1800+1100*math.max(0,math.min(count,6)-1) record.hp=record.max
		record.model:SetAttribute("MaxHealth",record.max)
	end
	local texts=record.stats.phaseTexts
	if colossus(record) and not record.engaged then
		-- Vida pelo número de participantes na arena: um jogador sozinho consegue vencer.
		record.engaged=true local count=0
		for _, participant in Players:GetPlayers() do if eligible(participant,record) then count+=1 end end
		record.max=record.stats.health+record.stats.healthPerPlayer*math.max(0,math.min(count,6)-1) record.hp=record.max
		record.model:SetAttribute("MaxHealth",record.max)
		notify:FireAllClients({kind="bossPhase",text=if texts then texts[1] else "O ARAUTO PARTIDO desperta. A luz dos quatro mundos se volta contra vocês!",position=record.root.Position})
	end
	record.hp=math.max(0,record.hp-amount)
	record.contributors[player]=os.clock()
	local shieldSource=player:GetAttribute("ShieldSourceUserId")
	local shieldUntil=player:GetAttribute("ShieldUntil")
	if typeof(shieldSource)=="number" and typeof(shieldUntil)=="number" and shieldUntil>workspace:GetServerTimeNow() then
		local support=Players:GetPlayerByUserId(shieldSource)
		local supportRoot=support and playerRoot(support)
		if support and supportRoot and (supportRoot.Position-record.root.Position).Magnitude<100 then record.contributors[support]=os.clock() end
	end
	record.model:SetAttribute("Health",record.hp)
	notify:FireAllClients({kind="damage",position=record.root.Position+Vector3.new(0,4,0),amount=amount,boss=record.definition.kind=="Boss" or colossus(record)})
	if record.definition.kind=="Boss" and record.hp>0 and record.phase==1 and record.hp<=record.max*0.5 then
		record.phase=2 record.model:SetAttribute("Phase",2)
		for _, piece in record.model:GetChildren() do
			if piece:IsA("BasePart") and (piece.Name=="Core" or piece.Name=="Eye") then piece.Color=Color3.fromRGB(225,136,104) end
			-- Treant: a luz do peito muda de ciano para laranja-brasa.
			local light=piece:FindFirstChildWhichIsA("PointLight") if light then light.Color=Color3.fromRGB(255,120,70) light.Brightness=2.4 end
		end
		notify:FireAllClients({kind="bossPhase",text="O núcleo se rompeu. Fase 2: raízes do vazio!",position=record.root.Position})
	end
	if colossus(record) and record.hp>0 then
		if record.phase==1 and record.hp<=record.max*0.6 then
			record.phase=2 record.model:SetAttribute("Phase",2)
			notify:FireAllClients({kind="bossPhase",text=if texts then texts[2] else "O Arauto se parte: ecos dos quatro mundos surgem na arena!",position=record.root.Position})
			record.reinforcementsCalled=false
			callReinforcements(record)
		elseif record.phase==2 and record.hp<=record.max*0.25 then
			record.phase=3 record.model:SetAttribute("Phase",3)
			notify:FireAllClients({kind="bossPhase",text=if texts then texts[3] else "FÚRIA DA CONVERGÊNCIA: o Arauto ataca sem pausa!",position=record.root.Position})
		end
	end
	if record.hp==0 then
		record.root.CanQuery=false
		-- O corpo visual desaparece; sua colisão não pode bloquear a trilha
		-- ou o altar após a derrota.
		record.root.CanCollide=false
		record.root.CanTouch=false
		if record.motion then record.motion:Cancel() end
		-- Chefão caiu: as criaturas que ele convocou se desfazem (o portal da região e o objetivo
		-- não ficam presos a reforços restantes).
		if record.definition.kind=="Boss" or colossus(record) then
			record.pendingReinforcements=false
			for _,member in records do
				if member.definition.group==record.definition.id and member.hp>0 then
					member.hp=0 member.casting=false
					if member.motion then member.motion:Cancel() end
					member.root.CanQuery=false member.root.CanCollide=false member.root.CanTouch=false
					member.model:SetAttribute("Health",0)
					member.model:SetAttribute("EncounterCompleted",true)
					notify:FireAllClients({kind="defeat",position=member.root.Position,color=member.stats.color})
					for _,piece in member.model:GetChildren() do
						if piece:IsA("BasePart") and piece~=member.root then TweenService:Create(piece,TweenInfo.new(0.6),{Transparency=1}):Play() end
					end
				end
			end
		end
		local encounter=record.definition.group or record.definition.id
		if not Service.isAlive(encounter) then
			local leader=records[encounter]
			if leader then leader.model:SetAttribute("EncounterCleared",true) end
			local credited: {[Player]: boolean}={}
			for _,member in records do
				if member.definition.id==encounter or member.definition.group==encounter then
					for contributor,time in member.contributors do
						local root=playerRoot(contributor)
						if not credited[contributor] and contributor.Parent==Players and root and os.clock()-time<45 and (root.Position-record.root.Position).Magnitude<100 then
							credited[contributor]=true quests.recordDefeat(contributor,encounter)
						end
					end
				end
			end
			-- Objetivo narrativo da equipe: companheiros vivos presentes também
			-- avançam, mesmo quando protegem/atraem inimigos sem causar dano.
			for _,companion in Players:GetPlayers() do
				local root=playerRoot(companion)
				if not credited[companion] and root and (root.Position-record.root.Position).Magnitude<100 then
					quests.recordDefeat(companion,encounter)
				end
			end
		end
		notify:FireAllClients({kind="defeat",position=record.root.Position,color=record.stats.color})
		-- Chefe final de região: visão do Regente do Vazio (flashback; na fase 5, a fenda).
		local vision=record.definition.vision
		if vision then
			if Service.onBossDefeated then task.spawn(Service.onBossDefeated,vision,record.origin) end
			local center=record.origin
			task.delay(2.4,function()
				for _,witness in Players:GetPlayers() do
					local root=playerRoot(witness)
					if root and (root.Position-center).Magnitude<160 then
						notify:FireClient(witness,{kind="vision",style=record.definition.visionStyle or "flashback",region=vision,center=center})
					end
				end
			end)
		end
		-- Chefe final da campanha (Regente): progresso da fase 6 e epílogo para quem estava no átrio.
		if record.definition.finale then
			local center=record.origin
			if Service.onBossDefeated then task.spawn(Service.onBossDefeated,record.definition.region,center) end
			notify:FireAllClients({kind="bossPhase",text="O Regente do Vazio se desfaz em poeira violeta...",position=record.root.Position})
			task.delay(3.5,function()
				for _,witness in Players:GetPlayers() do
					local root=playerRoot(witness)
					if (root and (root.Position-center).Magnitude<220) or Expedition.isEliminated(witness) then
						notify:FireClient(witness,{kind="finale"})
					end
				end
			end)
		end
		for _, piece in record.model:GetChildren() do
			if piece:IsA("BasePart") and piece~=record.root then TweenService:Create(piece,TweenInfo.new(0.6),{Transparency=1}):Play() end
		end
		-- Encontro concluído nesta expedição. Reforços terão encontros próprios;
		-- não ressuscitar a mesma criatura enquanto o grupo explora ou coleta.
		record.model:SetAttribute("EncounterCompleted",true)
	end
end

local function targets(player: Player,range: number): {any}
	local root=playerRoot(player)
	if not root then return {} end
	local result={}
	for _, record in records do
		if record.hp>0 and eligible(player,record) and (root.Position-record.root.Position).Magnitude<=range and lineOfSight(player,record) then table.insert(result,record) end
	end
	table.sort(result,function(a,b) return (a.root.Position-root.Position).Magnitude<(b.root.Position-root.Position).Magnitude end)
	return result
end

-- Lutador: o poder dele é lutar. Sequência de 4 golpes (jab, direto, gancho e Punho Solar),
-- golpe aéreo (pular + atacar) e gancho ascendente (agachar + atacar). Dano maior que o das
-- outras classes; o servidor decide variante, alvo e dano.
local brawlerCombo: {[Player]: number}={}
local brawlerSpecialAt: {[Player]: number}={}
local BRAWLER_MOVES={
	{name="Jab",mult=1.0},
	{name="Direto",mult=1.1},
	{name="Gancho",mult=1.3,stun=0.35},
	{name="PUNHO SOLAR",mult=2.0,stun=0.9,radius=7},
}

local function brawlerAttack(player: Player,root: BasePart,class: any,variant: string)
	local now=os.clock()
	local move: any
	-- Golpes especiais têm recarga própria (não seguem a do soco, 0,42 s).
	local special=brawlerSpecialAt[player] or -math.huge
	if variant=="air" and airborne(player) and now-special>=1.4 then
		brawlerSpecialAt[player]=now
		move={name="MARTELO SOLAR",mult=1.6,stun=1.0,radius=9,low=true,id="air"}
		brawlerCombo[player]=0
	elseif variant=="low" and player:GetAttribute("Crouching")==true and now-special>=1.6 then
		brawlerSpecialAt[player]=now
		move={name="GANCHO ASCENDENTE",mult=1.9,stun=1.3,id="low"}
		brawlerCombo[player]=0
	else
		local last=lastAttack[player] or -math.huge
		local index=if now-last<1.1 then (brawlerCombo[player] or 0)%4+1 else 1
		brawlerCombo[player]=index
		move=table.clone(BRAWLER_MOVES[index]) move.id="combo"..index
	end
	lastAttack[player]=now
	local enemy=targets(player,class.range)[1]
	local point=if enemy then enemy.root.Position else root.Position+root.CFrame.LookVector*6
	notify:FireAllClients({kind="strike",origin=root.Position,position=point,classId="Brawler",userId=player.UserId,color=class.color,move=move.id,moveName=if move.mult>=1.6 then move.name else nil})
	local amount=math.floor(class.damage*move.mult)
	if move.radius then
		-- Golpe de área ao redor do impacto (Punho Solar / Martelo Solar).
		local center=if enemy then enemy.root.Position else point
		for _,record in records do
			if record.hp>0 and eligible(player,record) and (record.root.Position-center).Magnitude<=move.radius+record.stats.radius*0.3 then
				damage(player,record,amount)
				if move.stun then stun(record,move.stun) end
			end
		end
	elseif enemy then
		damage(player,enemy,amount)
		if move.stun then stun(enemy,move.stun) end
	end
end

-- Guardião: combo de 3 cortes e golpes por direção/estado (frente, lado, trás, no ar, agachado).
-- O cliente pede a variante; o servidor valida estado (ar/agachado), limita deslocamentos por
-- raycast e decide alvo e dano. Especiais compartilham recarga curta (1,1 s).
-- Move o personagem (habilidades de deslocamento), zerando a velocidade.
local function character_pivot(player: Player,target: CFrame)
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not character or not root or not root:IsA("BasePart") then return end
	root.AssemblyLinearVelocity=Vector3.zero
	character:PivotTo(target)
end

local guardianCombo: {[Player]: number}={}
local guardianSpecialAt: {[Player]: number}={}
local GUARDIAN_MOVES={
	forward={id="thrust",name="ESTOCADA",mult=1.4,stun=0.4,lunge=6},
	side={id="spin",name="GIRO DE LÂMINA",mult=0.9,radius=9},
	back={id="counter",name="CORTE DE RECUO",mult=1.2,lunge=-4},
	air={id="plunge",name="QUEDA ASTRAL",mult=1.5,radius=7,stun=0.8},
	low={id="low",name="CORTE BAIXO",mult=1.1,slow=1.6},
}
local function guardianAttack(player: Player,root: BasePart,class: any,variant: string)
	local now=os.clock()
	local move: any=nil
	local spec=GUARDIAN_MOVES[variant]
	if spec and now-(guardianSpecialAt[player] or -math.huge)>=1.1 then
		local valid=if variant=="air" then airborne(player) elseif variant=="low" then player:GetAttribute("Crouching")==true else true
		if valid then move=spec guardianSpecialAt[player]=now guardianCombo[player]=0 end
	end
	if not move then
		local index=if now-(lastAttack[player] or -math.huge)<1.0 then (guardianCombo[player] or 0)%3+1 else 1
		guardianCombo[player]=index
		move={id="combo"..index,mult=if index==3 then 1.25 else 1}
	end
	lastAttack[player]=now
	-- Avanço/recuo do golpe, sem atravessar paredes.
	if move.lunge then
		local look=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
		if look.Magnitude>0.1 then
			look=look.Unit*math.sign(move.lunge)
			local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances={player.Character :: Instance,workspace:FindFirstChild("PortalEnemies") or workspace.Terrain}
			local hit=workspace:Raycast(root.Position,look*math.abs(move.lunge),params)
			local dist=if hit then math.max(0,(hit.Position-root.Position).Magnitude-2) else math.abs(move.lunge)
			local floor=workspace:Raycast(root.Position+look*dist,Vector3.new(0,-8,0),params)
			if dist>0.5 and floor then
				local to=root.Position+look*dist
				character_pivot(player,CFrame.lookAt(to,to+root.CFrame.LookVector*Vector3.new(1,0,1)))
			end
		end
	end
	local enemy=targets(player,class.range+(if move.lunge and move.lunge>0 then 2 else 0))[1]
	local point=if enemy then enemy.root.Position else root.Position+root.CFrame.LookVector*8
	notify:FireAllClients({kind="strike",origin=root.Position,position=point,classId="Guardian",userId=player.UserId,color=class.color,move=move.id,moveName=move.name})
	local amount=math.floor(class.damage*move.mult)
	if move.radius then
		local center=if move.id=="spin" then root.Position else (if enemy then enemy.root.Position else point)
		for _,record in records do
			if record.hp>0 and eligible(player,record) and (record.root.Position-center).Magnitude<=move.radius+record.stats.radius*0.3 then
				damage(player,record,amount)
				if move.stun then stun(record,move.stun) end
			end
		end
	elseif enemy then
		if not move.name and Service.tryEvade and Service.tryEvade(enemy,root) then return end
		damage(player,enemy,amount)
		if move.stun then stun(enemy,move.stun) end
		if move.slow and not (enemy.definition.kind=="Boss" or enemy.stats.big) then enemy.slowUntil=os.clock()+move.slow end
	end
end

local function attack(player: Player,variant: any)
	if (player:GetAttribute("KickBusyUntil") or 0)>workspace:GetServerTimeNow() then return end
	local root=playerRoot(player)
	local p=Data.get(player)
	if not root or not p then return end
	local class=Classes[p.classId]
	local now=os.clock()
	if now-(lastAttack[player] or -math.huge)<class.cooldown then return end
	-- Atacar abaixa o escudo.
	if player:GetAttribute("Blocking")==true then setBlocking(player,false) end
	if p.classId=="Brawler" then
		brawlerAttack(player,root,class,if variant=="air" or variant=="low" then variant else "ground")
		return
	end
	if p.classId=="Guardian" then
		guardianAttack(player,root,class,if typeof(variant)=="string" then variant else "ground")
		return
	end
	lastAttack[player]=now
	local enemy=targets(player,class.range)[1]
	local point=if enemy then enemy.root.Position else root.Position+root.CFrame.LookVector*8
	notify:FireAllClients({kind="strike",origin=root.Position,position=point,classId=p.classId,userId=player.UserId,color=class.color})
	-- Criaturas ágeis às vezes desviam do golpe comum (habilidades e chutes não são esquivados).
	if enemy and Service.tryEvade and Service.tryEvade(enemy,root) then return end
	if enemy then damage(player,enemy,class.damage) end
end


local function skill(player: Player)
	if (player:GetAttribute("KickBusyUntil") or 0)>workspace:GetServerTimeNow() then return end
	local root,humanoid=playerRoot(player)
	local p=Data.get(player)
	if not root or not humanoid or not p then return end
	local class=Classes[p.classId]
	local now=os.clock()
	if now-(lastSkill[player] or -math.huge)<class.skillCooldown then return end
	lastSkill[player]=now
	player:SetAttribute("SkillReadyAt",workspace:GetServerTimeNow()+class.skillCooldown)
	-- "skillCast" só alimenta gesto e efeitos nos clientes; dano e escudo continuam decididos aqui.
	local cast={kind="skillCast",classId=p.classId,userId=player.UserId,position=root.Position,color=class.color,targets={}}
	if p.classId=="Guardian" then
		for _, ally in Players:GetPlayers() do
			local allyRoot=playerRoot(ally)
			if allyRoot and (allyRoot.Position-root.Position).Magnitude<=22 then ally:SetAttribute("ShieldUntil",workspace:GetServerTimeNow()+5) ally:SetAttribute("ShieldSourceUserId",player.UserId) end
		end
		-- Onda de choque do escudo: 70 de dano em 14 studs (chefões inclusive) e empurra as
		-- criaturas comuns para longe. É o especial do Guardião: bate mais que o golpe comum.
		for _,record in records do
			if record.hp>0 and eligible(player,record) and (record.root.Position-root.Position).Magnitude<=14+record.stats.radius*0.3 then
				damage(player,record,70)
				if record.hp>0 and not (record.definition.kind=="Boss" or record.stats.big) then
					local away=Vector3.new(record.root.Position.X-root.Position.X,0,record.root.Position.Z-root.Position.Z)
					if away.Magnitude>0.1 then
						local pushed=record.root.Position+away.Unit*6
						if hasFloor(record,pushed) then
							if record.motion then record.motion:Cancel() end
							record.motion=TweenService:Create(record.root,TweenInfo.new(0.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=record.root.CFrame.Rotation+pushed})
							record.motion:Play()
						end
					end
					stun(record,0.8)
				end
			end
		end
		cast.radius=22 cast.shockwave=14
		notify:FireAllClients(cast)
	elseif p.classId=="Explorer" then
		local selected=targets(player,class.range)
		for i=1,math.min(3,#selected) do
			local enemy=selected[i]
			damage(player,enemy,45)
			table.insert(cast.targets,enemy.root.Position)
		end
		if #cast.targets==0 then table.insert(cast.targets,root.Position+root.CFrame.LookVector*20) end
		notify:FireAllClients(cast)
	elseif p.classId=="Brawler" then
		-- Chute Sombra: avança até 22 studs (para antes de paredes) e atinge quem estiver no caminho.
		local look=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
		if look.Magnitude<0.1 then look=Vector3.new(0,0,-1) end
		look=look.Unit
		local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={player.Character :: Instance,workspace:FindFirstChild("PortalEnemies") or workspace.Terrain}
		local hit=workspace:Raycast(root.Position,look*22,params)
		local reach=if hit then math.max(0,(hit.Position-root.Position).Magnitude-2.5) else 22
		local from=root.Position
		local to=from+look*reach
		for _, record in records do
			if record.hp<=0 or not eligible(player,record) then continue end
			local offset=record.root.Position-from
			local along=math.clamp(offset:Dot(look),0,reach+3)
			local closest=from+look*along
			if (record.root.Position-closest).Magnitude<=record.stats.radius*0.5+4 then
				damage(player,record,75)
				table.insert(cast.targets,record.root.Position)
			end
		end
		player:SetAttribute("DodgeUntil",workspace:GetServerTimeNow()+0.45)
		character_pivot(player,CFrame.lookAt(to,to+look))
		cast.from=from cast.to=to
		notify:FireAllClients(cast)
	elseif p.classId=="Arcanist" then
		-- Sol Nascente: explosão de 14 studs no inimigo mais próximo ao alcance (ou à frente).
		local enemy=targets(player,class.range)[1]
		local center=if enemy then enemy.root.Position else root.Position+root.CFrame.LookVector*24
		for _, record in records do
			if record.hp>0 and eligible(player,record) and (record.root.Position-center).Magnitude<=14+record.stats.radius*0.3 then damage(player,record,60) end
		end
		cast.targets={center} cast.radius=14
		notify:FireAllClients(cast)
	elseif p.classId=="Shade" then
		-- Passo do Véu: reaparece atrás do inimigo mais próximo (até 40 studs, com linha de visão)
		-- e golpeia com crítico; fica velado por 2 s.
		local enemy=targets(player,40)[1]
		if enemy then
			local back=enemy.root.CFrame.LookVector
			back=Vector3.new(back.X,0,back.Z)
			if back.Magnitude<0.1 then back=(enemy.root.Position-root.Position)*Vector3.new(1,0,1) end
			local spot=enemy.root.Position-back.Unit*(enemy.stats.radius*0.5+3)
			local from=root.Position
			character_pivot(player,CFrame.lookAt(Vector3.new(spot.X,enemy.root.Position.Y,spot.Z),Vector3.new(enemy.root.Position.X,enemy.root.Position.Y,enemy.root.Position.Z)))
			damage(player,enemy,70)
			notify:FireAllClients({kind="blink",from=from,to=spot,color=class.color})
			table.insert(cast.targets,enemy.root.Position)
		end
		player:SetAttribute("VeiledUntil",workspace:GetServerTimeNow()+2)
		notify:FireAllClients(cast)
	else
		for _, enemy in targets(player,26) do enemy.slowUntil=now+4 damage(player,enemy,48) end
		cast.radius=26
		notify:FireAllClients(cast)
	end
end

-- Esquiva: impulso na direção pedida pelo cliente (validada: horizontal e unitária) com 0,35 s
-- de invencibilidade. Sem direção → passo para trás. Esquivar também solta das raízes.
local DODGE_COOLDOWN=1.6
local function dash(player: Player,wanted: any)
	local root=playerRoot(player)
	if not root then return end
	-- MoveDirection é unitário; rejeita NaN, infinito e magnitudes que
	-- transbordariam ao normalizar antes de consumir cooldown ou tocar a física.
	if wanted~=nil then
		if typeof(wanted)~="Vector3" then return end
		if wanted.X~=wanted.X or wanted.Y~=wanted.Y or wanted.Z~=wanted.Z
			or math.abs(wanted.X)>1.01 or math.abs(wanted.Y)>1.01 or math.abs(wanted.Z)>1.01 then return end
	end
	local now=os.clock()
	if now-(lastDash[player] or -math.huge)<DODGE_COOLDOWN then return end
	lastDash[player]=now
	player:SetAttribute("DashReadyAt",workspace:GetServerTimeNow()+DODGE_COOLDOWN)
	local direction=Vector3.zero
	if typeof(wanted)=="Vector3" and wanted.X==wanted.X and wanted.Z==wanted.Z then direction=Vector3.new(wanted.X,0,wanted.Z) end
	if direction.Magnitude<0.2 then direction=-Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z) end
	if direction.Magnitude<0.1 then return end
	direction=direction.Unit
	player:SetAttribute("DodgeUntil",workspace:GetServerTimeNow()+0.35)
	if (player:GetAttribute("SnaredUntil") or 0)>workspace:GetServerTimeNow() then
		player:SetAttribute("SnaredUntil",0) refreshSpeed(player)
	end
	root.AssemblyLinearVelocity=direction*46+Vector3.new(0,root.AssemblyLinearVelocity.Y,0)
	local localDir=root.CFrame:VectorToObjectSpace(direction)
	notify:FireAllClients({kind="dash",position=root.Position,color=Color3.fromRGB(181,210,221),userId=player.UserId,dir=Vector3.new(localDir.X,0,localDir.Z)})
end

-- ===== Movimentos das criaturas =====
-- Cada ataque marca o modelo com CastKind/CastStartedAt/CastEndsAt para a animação local e
-- envia telegrafia aos clientes; dano, puxões e imobilização são decididos aqui.

local function serverNow(): number return workspace:GetServerTimeNow() end

local function dodging(player: Player): boolean
	local untilTime=player:GetAttribute("DodgeUntil")
	return typeof(untilTime)=="number" and untilTime>serverNow()
end


local function snare(player: Player,seconds: number,position: Vector3)
	player:SetAttribute("SnaredUntil",serverNow()+seconds)
	refreshSpeed(player)
	notify:FireAllClients({kind="snare",userId=player.UserId,position=position,duration=seconds})
	task.delay(seconds+0.05,function() if player.Parent then refreshSpeed(player) end end)
end

local function beginCast(record: any,kind: string,windup: number)
	record.casting=true
	-- Vez de atacar (ver crowded no laço da IA).
	record.lastStrikeAt=os.clock() record.lastStrikeTarget=record.pendingTarget
	if record.motion then record.motion:Cancel() end
	record.model:SetAttribute("CastKind",kind)
	record.model:SetAttribute("CastStartedAt",serverNow())
	record.model:SetAttribute("CastEndsAt",serverNow()+windup)
end

local function faceTowards(record: any,position: Vector3)
	local flat=Vector3.new(position.X,record.root.Position.Y,position.Z)
	if (flat-record.root.Position).Magnitude>0.1 then record.root.CFrame=CFrame.lookAt(record.root.Position,flat) end
end

-- Mão de onde sai a vinha (ponta do braço direito do modelo gerado, ou a frente da raiz).
local function handPosition(record: any): Vector3
	local arm=record.model:FindFirstChild("RightArm")
	if arm and arm:IsA("BasePart") then return arm.Position-arm.CFrame.UpVector*arm.Size.Y*0.4 end
	return record.root.Position+record.root.CFrame.LookVector*2
end

local function forwardCone(record: any,player: Player,range: number,minDot: number): boolean
	local root=playerRoot(player)
	if not root then return false end
	local delta=Vector3.new(root.Position.X-record.root.Position.X,0,root.Position.Z-record.root.Position.Z)
	if delta.Magnitude>range then return false end
	if delta.Magnitude<1.5 then return true end
	local look=Vector3.new(record.root.CFrame.LookVector.X,0,record.root.CFrame.LookVector.Z).Unit
	return look:Dot(delta.Unit)>=minDot
end

local rootBurst: (record: any,target: Player,windupOverride: number?) -> ()

-- Raízes irrompem do chão na área ao redor da criatura (Sentinela) ou sob o alvo (chefe).
rootBurst=function(record: any,target: Player,windupOverride: number?)
	if record.casting or record.hp<=0 then return end
	local root=playerRoot(target)
	if not root then return end
	local boss=record.definition.kind=="Boss"
	local windup=windupOverride or (if record.phase==2 then 1.2 else record.stats.windup)
	beginCast(record,"RootBurst",windup)
	faceTowards(record,root.Position)
	local radius=if boss and record.phase==2 then 10 else record.stats.radius
	local centers={if boss then Vector3.new(root.Position.X,root.Position.Y-2.25,root.Position.Z) else Vector3.new(record.root.Position.X,record.groundY+0.75,record.root.Position.Z)}
	if boss and record.phase==2 then
		for _, offset in {Vector3.new(12,0,3),Vector3.new(-9,0,-7)} do table.insert(centers,centers[1]+offset) end
	end
	for _, center in centers do notify:FireAllClients({kind="telegraph",position=center,radius=radius,duration=windup,boss=boss,style="roots"}) end
	record.nextCast=os.clock()+(if record.phase==2 then 2.8 else record.stats.cooldown)+windup
	task.delay(windup,function()
		if record.hp>0 and record.model.Parent then
			record.model:SetAttribute("ImpactUntil",serverNow()+0.3)
			local hit: {[Player]: boolean}={}
			for _, player in Players:GetPlayers() do
				local playerPart=playerRoot(player)
				if playerPart and eligible(player,record) then
					for _, center in centers do
						local flat=Vector3.new(playerPart.Position.X,center.Y,playerPart.Position.Z)
						if not hit[player] and (flat-center).Magnitude<=radius and math.abs(playerPart.Position.Y-2.25-center.Y)<6 then
							hit[player]=true
							if not dodging(player) then
								hurtPlayer(player,record.stats.damage+(if record.phase==2 then 3 else 0),center)
								snare(player,if boss then 0.9 else 1.1,playerPart.Position)
							end
						end
					end
				end
			end
			for _, center in centers do notify:FireAllClients({kind="impact",position=center,radius=radius,style="roots"}) end
		end
		record.casting=false
	end)
end

-- Arauto Partido (fase 5). Cada fase acelera: 1 → 2 (ecos na arena) → 3 (fúria, sem pausas).
local function heraldTempo(record: any): number
	return if record.phase==3 then 0.55 elseif record.phase==2 then 0.8 else 1
end

-- Resolve uma área telegrafada: dano a quem estiver dentro (esquiva evita).
local function heraldImpact(record: any,centers: {Vector3},radius: number,amount: number,style: string)
	if record.hp<=0 or not record.model.Parent then return end
	record.model:SetAttribute("ImpactUntil",serverNow()+0.3)
	local hit: {[Player]: boolean}={}
	for _, player in Players:GetPlayers() do
		local part=playerRoot(player)
		if part and eligible(player,record) and not hit[player] then
			for _, center in centers do
				local flat=Vector3.new(part.Position.X,center.Y,part.Position.Z)
				if (flat-center).Magnitude<=radius and math.abs(part.Position.Y-2.25-center.Y)<7 then
					hit[player]=true
					if not dodging(player) then hurtPlayer(player,amount,center) end
					break
				end
			end
		end
	end
	for _, center in centers do notify:FireAllClients({kind="impact",position=center,radius=radius,style=style}) end
end

-- Golpe Quádruplo: áreas sob o alvo e ao redor dele, em sequência (na fase 3, cinco áreas).
local function heraldStrike(record: any,target: Player)
	if record.casting or record.hp<=0 then return end
	local root=playerRoot(target)
	if not root then return end
	local tempo=heraldTempo(record)
	local windup=record.stats.windup*tempo
	beginCast(record,"HeraldStrike",windup)
	faceTowards(record,root.Position)
	local base=Vector3.new(root.Position.X,root.Position.Y-2.25,root.Position.Z)
	local count=if record.phase==3 then 5 else 4
	local centers={base}
	for i=1,count-1 do
		local a=i*math.pi*2/(count-1)+os.clock()
		table.insert(centers,base+Vector3.new(math.cos(a)*11,0,math.sin(a)*11))
	end
	for i,center in centers do
		notify:FireAllClients({kind="telegraph",position=center,radius=7,duration=windup+(i-1)*0.18,boss=true,style="void"})
	end
	record.nextCast=os.clock()+record.stats.cooldown*tempo+windup
	task.delay(windup,function()
		for i,center in centers do
			task.delay((i-1)*0.18,function() heraldImpact(record,{center},7,record.stats.damage,"void") end)
		end
		task.delay(#centers*0.18,function() record.casting=false end)
	end)
end

-- Anel do Eclipse: onda ao redor do Arauto; é preciso sair do raio (ou esquivar na hora certa).
local function heraldRing(record: any)
	if record.casting or record.hp<=0 then return end
	local tempo=heraldTempo(record)
	local windup=1.4*math.max(0.7,tempo)
	beginCast(record,"HeraldRing",windup)
	local center=Vector3.new(record.root.Position.X,record.groundY+0.75,record.root.Position.Z)
	local radius=if record.phase>=2 then 20 else 17
	notify:FireAllClients({kind="telegraph",position=center,radius=radius,duration=windup,boss=true,style="void"})
	record.nextRing=os.clock()+7*tempo
	record.nextCast=os.clock()+windup+1.2*tempo
	task.delay(windup,function()
		heraldImpact(record,{center},radius,record.stats.damage+8,"void")
		record.casting=false
	end)
end

-- Vinha: estica o braço, lança uma raiz em linha reta (mira travada no início) e, se pegar,
-- puxa o alvo para dentro da área e emenda a Explosão de Raízes. Esquiva ou sair da linha evita.
local function vineGrab(record: any,target: Player,reach: number)
	if record.casting or record.hp<=0 then return end
	local root=playerRoot(target)
	if not root then return end
	local windup=if record.definition.kind=="Boss" then 0.8 else 0.65
	beginCast(record,"VineGrab",windup)
	faceTowards(record,root.Position)
	local origin=handPosition(record)
	local direction=Vector3.new(root.Position.X-origin.X,0,root.Position.Z-origin.Z)
	if direction.Magnitude<0.1 then record.casting=false return end
	direction=direction.Unit
	local tip=origin+direction*reach
	record.model:SetAttribute("ReachTarget",tip)
	local web=record.stats.abilities~=nil and record.stats.abilities.webPull==true
	notify:FireAllClients({kind="vineTelegraph",from=origin,to=tip,duration=windup,width=2.4,style=if web then "web" else nil})
	record.nextGrab=os.clock()+(if record.definition.kind=="Boss" then 7 else 6)
	record.nextCast=math.max(record.nextCast,os.clock()+windup+0.6)
	task.delay(windup,function()
		if record.hp<=0 or not record.model.Parent then record.casting=false return end
		local travel=math.clamp(reach/55,0.18,0.45)
		record.model:SetAttribute("ReachUntil",serverNow()+travel+0.5)
		-- Primeiro jogador atingido ao longo da linha (largura 2,4 studs).
		local caught: Player?=nil local caughtAt=math.huge
		for _, player in Players:GetPlayers() do
			local part=playerRoot(player)
			if part and eligible(player,record) and not dodging(player) then
				local rel=Vector3.new(part.Position.X-origin.X,0,part.Position.Z-origin.Z)
				local along=rel:Dot(direction)
				local side=(rel-direction*along).Magnitude
				if along>0 and along<=reach and side<=2.4 and along<caughtAt then caught=player caughtAt=along end
			end
		end
		local stop=if caught then origin+direction*caughtAt else tip
		local caughtCharacter=if caught then caught.Character else nil
		notify:FireAllClients({kind="vine",from=origin,to=stop,travel=travel,caught=caught and caught.UserId or nil,style=if web then "web" else nil})
		task.wait(travel)
		local pulled=false
		if caught and caught.Parent and record.hp>0 then
			local part=playerRoot(caught)
			local rel=if part then Vector3.new(part.Position.X-origin.X,0,part.Position.Z-origin.Z) else Vector3.zero
			local along=rel:Dot(direction)
			local side=(rel-direction*along).Magnitude
			-- A captura só acontece na chegada: movimento, esquiva, morte ou
			-- respawn durante o voo não podem deixar um alvo antigo preso.
			if part and caught.Character==caughtCharacter and eligible(caught,record)
				and not dodging(caught) and along>0 and along<=reach and side<=2.4 and lineOfSight(caught,record) then
				local character=caught.Character :: Model
				-- Puxa até a frente da criatura, dentro da área das raízes.
				local landing=record.root.Position+record.root.CFrame.LookVector*math.max(3.5,record.stats.radius*0.45)
				landing=Vector3.new(landing.X,part.Position.Y,landing.Z)
				snare(caught,if record.definition.kind=="Boss" then 0.5 else 1.0,part.Position)
				local start=part.Position
				pulled=true
				local params=RaycastParams.new()
				params.FilterType=Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances={character,record.model}
				for i=1,8 do
					if not character.Parent or caught.Character~=character or record.hp<=0
						or not eligible(caught,record) or dodging(caught) then pulled=false break end
					local p=start:Lerp(landing,i/8)
					-- Não atravessar paredes durante a aproximação forçada.
					if workspace:Raycast(part.Position,p-part.Position,params) then pulled=false break end
					character:PivotTo(CFrame.lookAt(p,Vector3.new(record.root.Position.X,p.Y,record.root.Position.Z)))
					task.wait(0.035)
				end
				if pulled and caught.Character==character and eligible(caught,record) and not dodging(caught) then
					hurtPlayer(caught,math.floor(record.stats.damage*0.4),landing)
				else pulled=false end
			end
		end
		record.casting=false
		-- Chefe: aviso mais longo após o puxão, para a esquiva ser uma resposta possível.
		-- Teia (aranha): puxa para perto e a mordida vem no próximo instante; vinha: explosão de raízes.
		if pulled and caught and record.hp>0 then
			if web then record.nextCast=os.clock()+0.25 else rootBurst(record,caught,if record.definition.kind=="Boss" then 1.0 else 0.55) end
		end
	end)
end

-- Carnívoros (Predador): só mordida e garras, golpes rápidos em cone à frente.
local function bite(record: any,target: Player)
	if record.casting or record.hp<=0 then return end
	local root=playerRoot(target)
	if not root then return end
	local windup=0.45
	beginCast(record,"Bite",windup)
	faceTowards(record,root.Position)
	local front=record.root.Position+record.root.CFrame.LookVector*3.2
	notify:FireAllClients({kind="telegraph",position=Vector3.new(front.X,record.groundY+0.75,front.Z),radius=2.6,duration=windup,small=true})
	record.nextCast=os.clock()+record.stats.cooldown*0.8+windup
	task.delay(windup,function()
		if record.hp<=0 or not record.model.Parent then record.casting=false return end
		-- Bote: avança 2,5 studs mordendo.
		record.root.CFrame=record.root.CFrame+record.root.CFrame.LookVector*2.5
		record.model:SetAttribute("ImpactUntil",serverNow()+0.25)
		for _, player in Players:GetPlayers() do
			if eligible(player,record) and forwardCone(record,player,5.5,0.45) and not dodging(player) then
				local part=playerRoot(player)
				hurtPlayer(player,record.stats.damage,if part then part.Position else front)
			end
		end
		notify:FireAllClients({kind="bite",position=record.root.Position+record.root.CFrame.LookVector*2.2})
		record.casting=false
	end)
end

local function claw(record: any,target: Player)
	if record.casting or record.hp<=0 then return end
	local root=playerRoot(target)
	if not root then return end
	local windup=0.55
	beginCast(record,"Claw",windup)
	faceTowards(record,root.Position)
	local front=record.root.Position+record.root.CFrame.LookVector*3
	notify:FireAllClients({kind="telegraph",position=Vector3.new(front.X,record.groundY+0.75,front.Z),radius=3.6,duration=windup,small=true})
	record.nextCast=os.clock()+record.stats.cooldown+windup
	task.delay(windup,function()
		if record.hp<=0 or not record.model.Parent then record.casting=false return end
		record.model:SetAttribute("ImpactUntil",serverNow()+0.3)
		for _, player in Players:GetPlayers() do
			if eligible(player,record) and forwardCone(record,player,6,0.05) and not dodging(player) then
				local part=playerRoot(player)
				hurtPlayer(player,math.floor(record.stats.damage*0.85),if part then part.Position else front)
			end
		end
		notify:FireAllClients({kind="claw",position=front,look=record.root.CFrame.LookVector})
		record.casting=false
	end)
end

-- Eco do Vazio: some e reaparece longe quando o jogador chega perto demais.
local function blink(record: any,target: Player)
	local root=playerRoot(target)
	if not root then return end
	local away=Vector3.new(record.root.Position.X-root.Position.X,0,record.root.Position.Z-root.Position.Z)
	away=if away.Magnitude>0.1 then away.Unit else record.root.CFrame.LookVector*-1
	local wanted=record.root.Position+away*11
	-- Respeita a corrente (leash) e só aceita destino com chão.
	local fromOrigin=Vector3.new(wanted.X-record.origin.X,0,wanted.Z-record.origin.Z)
	if fromOrigin.Magnitude>record.definition.leash-2 then wanted=record.origin+fromOrigin.Unit*(record.definition.leash-2)+Vector3.new(0,record.root.Position.Y-record.origin.Y,0) end
	if not hasFloor(record,wanted) then return end
	local from=record.root.Position
	if record.motion then record.motion:Cancel() end
	record.root.CFrame=CFrame.lookAt(Vector3.new(wanted.X,from.Y,wanted.Z),Vector3.new(root.Position.X,from.Y,root.Position.Z))
	record.nextBlink=os.clock()+7
	notify:FireAllClients({kind="blink",from=from,to=record.root.Position,color=record.stats.color})
end

-- Passo do Vazio (Regente, fase 2+): marca o ponto ao lado do alvo, some e reaparece ali.
-- O aviso no chão dura 0,7 s, dando tempo de se afastar antes do golpe seguinte.
local function voidStep(record: any,target: Player)
	if record.casting or record.hp<=0 then return end
	local root=playerRoot(target)
	if not root then return end
	local toward=Vector3.new(record.root.Position.X-root.Position.X,0,record.root.Position.Z-root.Position.Z)
	toward=if toward.Magnitude>0.1 then toward.Unit else Vector3.new(0,0,1)
	local wanted=Vector3.new(root.Position.X,record.root.Position.Y,root.Position.Z)+toward*9
	local fromOrigin=Vector3.new(wanted.X-record.origin.X,0,wanted.Z-record.origin.Z)
	if fromOrigin.Magnitude>record.definition.leash-2 then return end
	if not hasFloor(record,wanted) then return end
	record.nextStep=os.clock()+(if record.phase>=3 then 6 else 9)
	beginCast(record,"VoidStep",0.7)
	notify:FireAllClients({kind="telegraph",position=Vector3.new(wanted.X,record.groundY+0.75,wanted.Z),radius=6,duration=0.7,boss=true,style="void"})
	task.delay(0.7,function()
		if record.hp<=0 or not record.model.Parent then return end
		local from=record.root.Position
		if record.motion then record.motion:Cancel() end
		record.root.CFrame=CFrame.lookAt(wanted,Vector3.new(root.Position.X,wanted.Y,root.Position.Z))
		notify:FireAllClients({kind="blink",from=from,to=wanted,color=record.stats.color})
		heraldImpact(record,{Vector3.new(wanted.X,record.groundY+0.75,wanted.Z)},6,math.floor(record.stats.damage*0.8),"void")
		record.nextCast=os.clock()+0.9
		record.casting=false
	end)
end

-- Projétil mirado (teia, chamas, ferrão): aviso curto, voo visível e acerto na chegada num raio
-- pequeno ao redor do ponto mirado — sair do lugar ou esquivar evita. `style` escolhe efeito:
--   web   dano + prende os pés (snare)    fire  explosão em área    sting  dano simples
local PROJECTILE={
	web={speed=55,radius=3.2,mult=0.7,snare=1.2,windup=0.45},
	fire={speed=40,radius=5.5,mult=1.0,windup=0.6},
	sting={speed=65,radius=3,mult=0.9,windup=0.4},
}
local function projectile(record: any,target: Player,style: string)
	if record.casting or record.hp<=0 then return end
	local root=playerRoot(target)
	if not root then return end
	local spec=PROJECTILE[style]
	beginCast(record,"Projectile",spec.windup)
	faceTowards(record,root.Position)
	-- Mira no chão sob o alvo, com um pouco de antecipação do movimento.
	local lead=root.AssemblyLinearVelocity*Vector3.new(1,0,1)*0.25
	local aim=Vector3.new(root.Position.X,root.Position.Y-2.25,root.Position.Z)+lead
	local from=record.root.Position+record.root.CFrame.LookVector*(record.root.Size.Z*0.5)+Vector3.new(0,record.root.Size.Y*0.15,0)
	local travel=math.clamp((aim-from).Magnitude/spec.speed,0.15,0.8)
	notify:FireAllClients({kind="telegraph",position=aim,radius=spec.radius,duration=spec.windup+travel,small=true})
	record.nextShot=os.clock()+(if style=="fire" then 4.2 else 3.4)
	record.nextCast=os.clock()+spec.windup+travel+0.5
	task.delay(spec.windup,function()
		if record.hp<=0 or not record.model.Parent then record.casting=false return end
		notify:FireAllClients({kind="projectile",from=from,to=aim,travel=travel,style=style})
		task.wait(travel)
		if record.hp>0 then
			for _,player in Players:GetPlayers() do
				local part=playerRoot(player)
				if part and eligible(player,record) then
					local flat=Vector3.new(part.Position.X,aim.Y,part.Position.Z)
					if (flat-aim).Magnitude<=spec.radius and math.abs(part.Position.Y-2.25-aim.Y)<6 and not dodging(player) then
						hurtPlayer(player,math.floor(record.stats.damage*spec.mult),aim)
						if spec.snare then snare(player,spec.snare,part.Position) end
					end
				end
			end
			notify:FireAllClients({kind="impact",position=aim,radius=spec.radius,style=style})
		end
		record.casting=false
	end)
end

-- Bote: agacha (aviso), salta até o alvo e morde na chegada. Quadrúpedes rápidos.
local function pounce(record: any,target: Player)
	if record.casting or record.hp<=0 then return end
	local root=playerRoot(target)
	if not root then return end
	local windup=0.45
	beginCast(record,"Pounce",windup)
	faceTowards(record,root.Position)
	local landing=Vector3.new(root.Position.X,record.root.Position.Y,root.Position.Z)
	local away=Vector3.new(record.root.Position.X-landing.X,0,record.root.Position.Z-landing.Z)
	if away.Magnitude>0.1 then landing+=away.Unit*2.5 end
	local fromOrigin=Vector3.new(landing.X-record.origin.X,0,landing.Z-record.origin.Z)
	if fromOrigin.Magnitude>record.definition.leash or not hasFloor(record,landing) then record.casting=false return end
	notify:FireAllClients({kind="telegraph",position=Vector3.new(landing.X,record.groundY+0.75,landing.Z),radius=3.5,duration=windup+0.25,small=true})
	record.nextPounce=os.clock()+5
	record.nextCast=os.clock()+windup+1.1
	task.delay(windup,function()
		if record.hp<=0 or not record.model.Parent then record.casting=false return end
		if record.motion then record.motion:Cancel() end
		local look=Vector3.new(root.Position.X,landing.Y,root.Position.Z)
		record.motion=TweenService:Create(record.root,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=CFrame.lookAt(landing,look)})
		record.motion:Play()
		task.wait(0.25)
		if record.hp>0 then
			record.model:SetAttribute("ImpactUntil",serverNow()+0.25)
			for _,player in Players:GetPlayers() do
				local part=playerRoot(player)
				if part and eligible(player,record) and (Vector3.new(part.Position.X,landing.Y,part.Position.Z)-landing).Magnitude<=4 and not dodging(player) then
					hurtPlayer(player,math.floor(record.stats.damage*1.2),landing)
				end
			end
			notify:FireAllClients({kind="bite",position=landing+Vector3.new(0,1.5,0)})
		end
		record.casting=false
	end)
end

-- Esquiva lateral de criaturas ágeis quando um golpe vem pela frente (chance e recarga).
local function tryEvade(record: any,attacker: BasePart): boolean
	if not record.stats.agile or record.casting or record.hp<=0 or (record.stunUntil or 0)>os.clock() then return false end
	if os.clock()<(record.nextEvade or 0) or math.random()>record.stats.agile then return false end
	record.nextEvade=os.clock()+4
	local toward=Vector3.new(attacker.Position.X-record.root.Position.X,0,attacker.Position.Z-record.root.Position.Z)
	if toward.Magnitude<0.1 then return false end
	local side=Vector3.new(-toward.Unit.Z,0,toward.Unit.X)*(if math.random()<0.5 then 1 else -1)
	local wanted=record.root.Position+side*5
	if not hasFloor(record,wanted) then wanted=record.root.Position-side*5 end
	if not hasFloor(record,wanted) then return false end
	if record.motion then record.motion:Cancel() end
	record.motion=TweenService:Create(record.root,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=CFrame.lookAt(wanted,Vector3.new(attacker.Position.X,wanted.Y,attacker.Position.Z))})
	record.motion:Play()
	notify:FireAllClients({kind="evade",position=record.root.Position})
	return true
end
Service.tryEvade=tryEvade

local function cast(record: any,target: Player)
	if record.casting or record.hp<=0 then return end
	record.casting=true
	if record.motion then record.motion:Cancel() end
	local root=playerRoot(target)
	if not root then record.casting=false return end
	local boss=record.definition.kind=="Boss"
	local ranged=aiOf(record)=="Wisp" or boss
	local centers={if ranged then Vector3.new(root.Position.X,root.Position.Y-2.25,root.Position.Z) else Vector3.new(record.root.Position.X,record.groundY+0.75,record.root.Position.Z)}
	local radius=if boss and record.phase==2 then 10 else record.stats.radius
	local windup=if record.phase==2 then 1.2 else record.stats.windup
	record.model:SetAttribute("CastKind","Spell")
	record.model:SetAttribute("CastStartedAt",workspace:GetServerTimeNow())
	record.model:SetAttribute("CastEndsAt",workspace:GetServerTimeNow()+windup)
	if boss and record.phase==2 then
		for _, offset in {Vector3.new(12,0,3),Vector3.new(-9,0,-7)} do table.insert(centers,centers[1]+offset) end
	end
	for _, center in centers do notify:FireAllClients({kind="telegraph",position=center,radius=radius,duration=windup,boss=boss}) end
	record.nextCast=os.clock()+(if record.phase==2 then 2.8 else record.stats.cooldown)+windup
	task.delay(windup,function()
		if record.hp>0 and record.model.Parent then
			record.model:SetAttribute("ImpactUntil",workspace:GetServerTimeNow()+0.25)
			local hit: {[Player]: boolean}={}
			for _, player in Players:GetPlayers() do
				local playerPart=playerRoot(player)
				if playerPart and eligible(player,record) then
					for _, center in centers do
						local flat=Vector3.new(playerPart.Position.X,center.Y,playerPart.Position.Z)
						if not hit[player] and (flat-center).Magnitude<=radius and math.abs(playerPart.Position.Y-2.25-center.Y)<6 then hit[player]=true if not dodging(player) then hurtPlayer(player,record.stats.damage+(if record.phase==2 then 3 else 0),center) end end
					end
				end
			end
			for _, center in centers do notify:FireAllClients({kind="impact",position=center,radius=radius}) end
		end
		record.casting=false
	end)
end

local function navigate(record: any,wanted: Vector3): Vector3?
	local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude
	local excluded={workspace.PortalEnemies}
	for _, player in Players:GetPlayers() do if player.Character then table.insert(excluded,player.Character) end end
	params.FilterDescendantsInstances=excluded
	local delta=Vector3.new(wanted.X-record.root.Position.X,0,wanted.Z-record.root.Position.Z)
	if delta.Magnitude<0.1 then return wanted end
	if workspace:Raycast(record.root.Position,delta,params)==nil then record.waypoints=nil return wanted end
	if not record.pathComputing and os.clock()>=(record.nextPath or 0) then
		record.pathComputing=true record.nextPath=os.clock()+2
		task.spawn(function()
			local path=PathfindingService:CreatePath({AgentRadius=if record.definition.kind=="Boss" then 4.5 else 2,AgentHeight=if record.definition.kind=="Boss" then 13 else 6,AgentCanJump=false,WaypointSpacing=5})
			local ok=pcall(function() path:ComputeAsync(record.root.Position,wanted) end)
			if records[record.definition.id]==record and record.hp>0 then
				if ok and path.Status==Enum.PathStatus.Success then record.waypoints=path:GetWaypoints() record.waypoint=2 else record.waypoints=nil end
				if RunService:IsStudio() then record.model:SetAttribute("PathStatus",if ok then path.Status.Name else "Error") end
			end
			record.pathComputing=false
		end)
	end
	local route=record.waypoints
	if route then
		while record.waypoint<=#route do
			local point=route[record.waypoint].Position
			if Vector3.new(point.X-record.root.Position.X,0,point.Z-record.root.Position.Z).Magnitude>2.5 then return point end
			record.waypoint+=1
		end
	end
	return nil
end

-- Chutes de todas as classes. O cliente pede a variante; o servidor confirma o estado:
--   front  chute frontal (em pé)
--   jump   chute voador (no ar, medido por raycast): mais alcance, derruba criaturas comuns
--   sweep  rasteira (agachado): arco largo, atinge todos à frente e derruba
-- O Lutador chuta com o dobro de força, recarga menor e encadeia com os socos.
local KICKS={
	front={damage=14,reach=7,cone=0.5,slow=1.2,all=false,delay=0.22,label=nil},
	jump={damage=20,reach=10,cone=0.3,stun=0.8,all=false,delay=0.16,label="CHUTE VOADOR"},
	sweep={damage=12,reach=8.5,cone=-0.25,stun=1.6,all=true,delay=0.2,label="RASTEIRA"},
}
local function kick(player: Player,wanted: any)
	local root=playerRoot(player)
	local p=Data.get(player)
	local now=os.clock()
	if not root or not p or not Expedition.hasStarted() then return end
	local fighter=p.classId=="Brawler"
	local cooldown=if fighter then 1.0 else 1.8
	if now-(lastKick[player] or -math.huge)<cooldown then return end
	if now-(lastAttack[player] or -math.huge)<(if fighter then 0.2 else 0.6) or now-(lastSkill[player] or -math.huge)<0.95 then return end
	local variant="front"
	if wanted=="sweep" and player:GetAttribute("Crouching")==true then variant="sweep"
	elseif wanted=="jump" and airborne(player) then variant="jump" end
	local spec=KICKS[variant]
	lastKick[player]=now
	player:SetAttribute("KickReadyAt",workspace:GetServerTimeNow()+cooldown)
	player:SetAttribute("KickBusyUntil",workspace:GetServerTimeNow()+(if variant=="sweep" then 0.55 else 0.5))
	setBlocking(player,false)
	local character=player.Character
	notify:FireAllClients({kind="kick",userId=player.UserId,position=root.Position,variant=variant,label=if fighter and spec.label then spec.label.." SOLAR" else spec.label,color=if fighter then Classes.Brawler.color else nil})
	-- O contato acontece na extensão da perna; cliente não escolhe alvo/dano.
	task.delay(spec.delay,function()
		local current=playerRoot(player)
		if not current or player.Character~=character then return end
		local amount=if fighter then spec.damage*2 else spec.damage
		for _,enemy in targets(player,spec.reach+(if variant=="jump" then 2 else 0)) do
			local delta=enemy.root.Position-current.Position
			local flat=Vector3.new(delta.X,0,delta.Z)
			if flat.Magnitude>0.1 and current.CFrame.LookVector:Dot(flat.Unit)>spec.cone then
				damage(player,enemy,amount)
				if spec.stun then stun(enemy,spec.stun*(if fighter then 1.4 else 1))
				elseif enemy.definition.kind~="Boss" then enemy.slowUntil=os.clock()+spec.slow end
				if not spec.all then break end
			end
		end
	end)
end

-- Há criatura viva a até `radius` studs? (Pontos seguros não curam no meio de uma luta.)
function Service.threatNear(position: Vector3,radius: number): boolean
	for _,record in records do
		local boss=record.stats.big or record.definition.kind=="Boss"
		-- Chefões só contam com a luta em andamento: o ponto seguro antes da arena cura normalmente.
		if record.hp>0 and (not boss or record.engaged) and (record.root.Position-position).Magnitude<=radius+(if boss then 30 else 0) then return true end
	end
	return false
end

-- QA (Studio): dano por um jogador pelo caminho normal (créditos, fases, reforços, visão).
function Service.debugDamage(player: Player,id: string,amount: number): number?
	local record=records[id]
	if not record then return nil end
	damage(player,record,amount)
	return record.hp
end

function Service.spawnRegional()
	for _, definition in Chapter.Encounters do
		if definition.region and not records[definition.id] then makeRecord(definition) end
	end
	-- Encontros comuns das regiões 2–6: cada slot "Encounter" do construtor recebe um grupo da
	-- fauna local (líder + 1–2 membros). Só o líder chama reforços.
	local world=workspace:FindFirstChild("PortalChapter")
	if not world then return end
	for regionId,fauna in Chapter.RegionFauna do
		local regionModel=if regionId=="Lumen" then nil else world:FindFirstChild(regionId)
		if not regionModel then continue end
		local index=0
		for _,slot in regionModel:GetDescendants() do
			if not slot:IsA("BasePart") or slot:GetAttribute("Kind")~="Encounter" then continue end
			index+=1
			local radius=tonumber(slot:GetAttribute("Radius")) or 14
			local leader=regionId.."_"..slot.Name
			local size=if radius>=16 then 3 else 2
			for k=1,size do
				local id=if k==1 then leader else leader.."_"..k
				if records[id] then continue end
				local a=k*math.pi*2/size+index
				local spread=if k==1 then 0 else math.min(6,radius*0.4)
				local pos=slot.Position+Vector3.new(math.cos(a)*spread,0,math.sin(a)*spread)
				makeRecord({id=id,kind=fauna[(index+k-2)%#fauna+1],position=pos,leash=radius+6,region=regionId,group=if k==1 then nil else leader,groundFromY=slot.Position.Y-50})
			end
		end
	end
end

function Service.init(attackRemote: RemoteEvent,skillRemote: RemoteEvent,dashRemote: RemoteEvent,notifyRemote: RemoteEvent,questService: any,blockRemote: RemoteEvent?,kickRemote: RemoteEvent?,crouchRemote: RemoteEvent?)
	notify=notifyRemote quests=questService
	-- Encontros de outras regiões nascem depois que o cenário delas existe (spawnRegional).
	for _, definition in Chapter.Encounters do if not definition.region then makeRecord(definition) end end
	if blockRemote then blockRemote.OnServerEvent:Connect(setBlocking) end
	if kickRemote then kickRemote.OnServerEvent:Connect(kick) end
	if crouchRemote then crouchRemote.OnServerEvent:Connect(setCrouching) end
	local function reset(player: Player) player:SetAttribute("Blocking",false) player:SetAttribute("Crouching",false) end
	Players.PlayerAdded:Connect(function(player) player.CharacterAdded:Connect(function() reset(player) end) end)
	for _, player in Players:GetPlayers() do player.CharacterAdded:Connect(function() reset(player) end) end
	attackRemote.OnServerEvent:Connect(attack)
	skillRemote.OnServerEvent:Connect(skill)
	dashRemote.OnServerEvent:Connect(dash)
	Players.PlayerRemoving:Connect(function(player)
		lastAttack[player]=nil lastSkill[player]=nil lastDash[player]=nil lastKick[player]=nil brawlerCombo[player]=nil brawlerSpecialAt[player]=nil guardianCombo[player]=nil guardianSpecialAt[player]=nil
		for _, r in records do r.contributors[player]=nil end
	end)
	local elapsed=0
	RunService.Heartbeat:Connect(function(dt)
		elapsed+=dt if elapsed<0.16 then return end
		local step=math.min(elapsed,0.4) elapsed=0
		for _, r in records do
			if r.hp<=0 or r.casting then continue end
			-- Derrubado (rasteira/chute voador/golpes do Lutador): não anda nem ataca.
			if (r.stunUntil or 0)>os.clock() then continue end
			local target=nil local distance=math.huge local point=nil
			for _, player in Players:GetPlayers() do
				local root=playerRoot(player)
				-- Véu velado (Passo do Véu) não é perseguido por 2 s.
				local veiled=(player:GetAttribute("VeiledUntil") or 0)>workspace:GetServerTimeNow()
				if root and not veiled and eligible(player,r) and (root.Position-r.origin).Magnitude<=r.definition.leash then
					local d=(root.Position-r.root.Position).Magnitude
					if d<distance then target=player point=root.Position distance=d end
				end
			end

			if target then r.idleSince=nil elseif r.engaged and r.hp<r.max then
				r.idleSince=r.idleSince or os.clock()
				if os.clock()-r.idleSince>12 then
					r.hp=r.max r.phase=1 r.engaged=false r.contributors={}
					r.model:SetAttribute("Health",r.hp) r.model:SetAttribute("Phase",1)
					for _, piece in r.model:GetChildren() do
						if piece:IsA("BasePart") and (piece.Name=="Core" or piece.Name=="Eye") then piece.Color=Color3.fromRGB(76,201,205) end
						local light=piece:FindFirstChildWhichIsA("PointLight") if light and r.definition.kind=="Boss" then light.Color=Color3.fromRGB(76,201,205) light.Brightness=1.8 end
					end
				end
			end
			-- Patrulha visível mesmo sem jogadores por perto; raio curto, sem spawn infinito.
			local patrolAngle=os.clock()*0.13+#r.definition.id
			local patrol=if r.definition.kind=="Boss" or colossus(r) then r.origin else r.origin+Vector3.new(math.sin(patrolAngle)*5,0,math.cos(patrolAngle)*5)
			local wanted=point or patrol
			local delta=Vector3.new(wanted.X-r.root.Position.X,0,wanted.Z-r.root.Position.Z)
			local boss=r.definition.kind=="Boss" or colossus(r)
			local kind=aiOf(r)
			local now=os.clock()
			local ready=now>=r.nextCast
			local sees=target~=nil and (boss or lineOfSight(target :: Player,r))
			-- Escolha de movimento por tipo de criatura.
			if target and sees then
				local t=target :: Player
				r.pendingTarget=t
				-- Habilidades próprias da criatura (stats.abilities), antes do ataque do arquétipo.
				-- Todas as criaturas podem atacar ao mesmo tempo (sem fila de vez).
				local abilities=r.stats.abilities
				if abilities and ready then
					if abilities.webPull and distance>=10 and distance<=20 and now>=(r.nextGrab or 0) then vineGrab(r,t,20) continue end
					if abilities.pounce and distance>=6 and distance<=15 and now>=(r.nextPounce or 0) then pounce(r,t) continue end
					if abilities.shot and distance>=7 and distance<=26 and now>=(r.nextShot or 0) then projectile(r,t,abilities.shot) continue end
				end
				if kind=="Moss" then
					if distance<=r.stats.radius+1 and ready then rootBurst(r,t) continue end
					if distance>r.stats.radius+1 and distance<=20 and now>=(r.nextGrab or 0) and ready then vineGrab(r,t,20) continue end
				elseif kind=="Boss" then
					if distance>14 and distance<=32 and now>=(r.nextGrab or 0) and ready then vineGrab(r,t,32) continue end
					if distance<=42 and ready then rootBurst(r,t) continue end
				elseif kind=="Herald" then
					if r.stats.voidStep and r.phase>=2 and distance>12 and ready and now>=(r.nextStep or 0) then voidStep(r,t) continue end
					if distance<=15 and ready and now>=(r.nextRing or 0) then heraldRing(r) continue end
					if distance<=46 and ready then heraldStrike(r,t) continue end
				elseif kind=="Thorn" then
					if distance<=6 and ready then
						r.alternate=not r.alternate
						if r.alternate then bite(r,t) else claw(r,t) end
						continue
					end
				elseif kind=="Wisp" then
					if distance<6 and now>=(r.nextBlink or 0) then blink(r,t) continue end
					if distance<=25 and ready then cast(r,t) continue end
				end
			end
			-- Predador rodeia a presa enquanto o próximo ataque recarrega.
			if kind=="Thorn" and target and distance<9 and not ready then
				local around=Vector3.new(r.root.Position.X-(point :: Vector3).X,0,r.root.Position.Z-(point :: Vector3).Z)
				if around.Magnitude>0.1 then
					r.circle=r.circle or (if math.random()<0.5 then 1 else -1)
					local tangent=Vector3.new(-around.Unit.Z,0,around.Unit.X)*r.circle
					local wantedPos=(point :: Vector3)+around.Unit*6.5+tangent*3
					local stepVec=Vector3.new(wantedPos.X-r.root.Position.X,0,wantedPos.Z-r.root.Position.Z)
					if stepVec.Magnitude>0.2 then
						local pos=r.root.Position+stepVec.Unit*math.min(stepVec.Magnitude,r.stats.speed*0.7*step)
						if not hasFloor(r,pos) then r.circle=-(r.circle or 1) continue end
						if r.motion then r.motion:Cancel() end
						r.motion=TweenService:Create(r.root,TweenInfo.new(0.16,Enum.EasingStyle.Linear),{CFrame=CFrame.lookAt(pos,Vector3.new((point :: Vector3).X,pos.Y,(point :: Vector3).Z))})
						r.motion:Play()
					end
					continue
				end
			end
			-- Para antes de encostar: metade da largura do corpo lógico + espaço do jogador.
			-- O Eco luta à distância: mantém ~12 studs.
			local stopDistance=if not target then 0.3 elseif kind=="Wisp" then 12 else math.max(4.5,r.root.Size.X*0.5+2.5)
			if delta.Magnitude>stopDistance then
				local speed=r.stats.speed*(if r.slowUntil>os.clock() then 0.4 else 1)
				local nextPoint=navigate(r,wanted)
				if not nextPoint then if r.motion then r.motion:Cancel() end continue end
				delta=Vector3.new(nextPoint.X-r.root.Position.X,0,nextPoint.Z-r.root.Position.Z)
				if delta.Magnitude<0.1 then continue end
				local pos=r.root.Position+delta.Unit*math.min(delta.Magnitude,speed*step)
				if not hasFloor(r,pos) then if r.motion then r.motion:Cancel() end continue end
				if r.motion then r.motion:Cancel() end
				r.motion=TweenService:Create(r.root,TweenInfo.new(0.16,Enum.EasingStyle.Linear),{CFrame=CFrame.lookAt(pos,pos+delta.Unit)})
				r.motion:Play()
			end
		end
	end)
end

return Service
