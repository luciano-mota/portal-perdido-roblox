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
local Service={}
local records: {[string]: any}={}
local lastAttack: {[Player]: number}={}
local lastSkill: {[Player]: number}={}
local lastDash: {[Player]: number}={}
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

local function lineOfSight(player: Player, record: any): boolean
	local root=playerRoot(player)
	if not root then return false end
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	-- Não existe PvP: companheiros não são cobertura contra ataques aliados.
	-- A geometria do mundo continua no raio, preservando paredes/obstáculos.
	local excluded: {Instance}={record.model}
	for _,ally in Players:GetPlayers() do
		if ally.Character then table.insert(excluded,ally.Character) end
	end
	params.FilterDescendantsInstances=excluded
	return workspace:Raycast(root.Position,record.root.Position-root.Position,params)==nil
end

local function eligible(player: Player, record: any): boolean
	local root=playerRoot(player)
	if not root then return false end
	if record.definition.kind=="Boss" then
		local p=Data.get(player)
		return p.quest==5 and (root.Position-record.origin).Magnitude<=48
	end
	return true
end

local function makeRecord(definition: any)
	local kind=Chapter.EnemyTypes[definition.kind]
	local origin=definition.position+Vector3.new(0,2,0)
	if definition.kind=="Boss" then origin=Vector3.new(origin.X,9,origin.Z) end
	local model=Art.enemy(workspace.PortalEnemies,definition.kind,origin,kind.color)
	model.Name=definition.id
	model:SetAttribute("EnemyKind",definition.kind)
	model:SetAttribute("DisplayName",kind.name)
	model:SetAttribute("Health",kind.health)
	model:SetAttribute("MaxHealth",kind.health)
	model:SetAttribute("Phase",1)
	local root=model.PrimaryPart :: BasePart
	-- Corpo lógico sólido: jogadores não atravessam a criatura (a malha visual continua sem colisão).
	root.CanCollide=true
	Art.label(root,kind.name,nil,Color3.fromRGB(234,224,202),if definition.kind=="Boss" then 11 else 5)
	records[definition.id]={definition=definition,stats=kind,model=model,root=root,origin=origin,hp=kind.health,max=kind.health,phase=1,contributors={},casting=false,nextCast=0,slowUntil=0,engaged=false}
end

function Service.isAlive(id: string): boolean
	local r=records[id]
	return r~=nil and r.hp>0
end

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
	local damage=math.floor(amount*factor)
	humanoid:TakeDamage(damage)
	notify:FireClient(player,{kind="hurt",amount=damage,shielded=reduced,blocked=blocked,position=position})
	if blocked then notify:FireAllClients({kind="block",userId=player.UserId,position=root.Position}) end
end

-- Defesa com escudo: o cliente pede, o servidor valida classe/vida e aplica a lentidão.
-- Velocidade do jogador a partir dos estados ativos (preso > defendendo > normal).
local function refreshSpeed(player: Player)
	local _,humanoid=playerRoot(player)
	if not humanoid then return end
	local snared=(player:GetAttribute("SnaredUntil") or 0)>workspace:GetServerTimeNow()
	humanoid.WalkSpeed=if snared then 3 elseif player:GetAttribute("Blocking")==true then 9 else 16
end

local function setBlocking(player: Player,wanted: any)
	local root,humanoid=playerRoot(player)
	local p=Data.get(player)
	local active=wanted==true and root~=nil and humanoid~=nil and p~=nil and p.classId=="Guardian"
	if (player:GetAttribute("Blocking")==true)==active then return end
	player:SetAttribute("Blocking",active)
	refreshSpeed(player)
end

local function damage(player: Player,record: any,amount: number)
	if record.hp<=0 then return end
	if record.definition.kind=="Boss" and not record.engaged then
		record.engaged=true local count=0
		for _, participant in Players:GetPlayers() do if eligible(participant,record) then count+=1 end end
		record.max=1800+1100*math.max(0,math.min(count,6)-1) record.hp=record.max
		record.model:SetAttribute("MaxHealth",record.max)
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
	notify:FireAllClients({kind="damage",position=record.root.Position+Vector3.new(0,4,0),amount=amount,boss=record.definition.kind=="Boss"})
	if record.definition.kind=="Boss" and record.hp>0 and record.phase==1 and record.hp<=record.max*0.5 then
		record.phase=2 record.model:SetAttribute("Phase",2)
		for _, piece in record.model:GetChildren() do
			if piece:IsA("BasePart") and (piece.Name=="Core" or piece.Name=="Eye") then piece.Color=Color3.fromRGB(225,136,104) end
		end
		notify:FireAllClients({kind="bossPhase",text="O núcleo se rompeu. Fase 2: raízes do vazio!",position=record.root.Position})
	end
	if record.hp==0 then
		record.root.CanQuery=false
		if record.motion then record.motion:Cancel() end
		for contributor,time in record.contributors do
			local root=playerRoot(contributor)
			if contributor.Parent==Players and root and os.clock()-time<45 and (root.Position-record.root.Position).Magnitude<100 then quests.recordDefeat(contributor,record.definition.id) end
		end
		notify:FireAllClients({kind="defeat",position=record.root.Position,color=record.stats.color})
		for _, piece in record.model:GetChildren() do
			if piece:IsA("BasePart") and piece~=record.root then TweenService:Create(piece,TweenInfo.new(0.6),{Transparency=1}):Play() end
		end
		local delaySeconds=if record.definition.kind=="Boss" then 40 else 30
		task.delay(delaySeconds,function()
			if records[record.definition.id]==record then
				record.model:Destroy()
				makeRecord(record.definition)
			end
		end)
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

local function attack(player: Player)
	local root=playerRoot(player)
	local p=Data.get(player)
	if not root or not p then return end
	local class=Classes[p.classId]
	local now=os.clock()
	if now-(lastAttack[player] or -math.huge)<class.cooldown then return end
	-- Atacar abaixa o escudo.
	if player:GetAttribute("Blocking")==true then setBlocking(player,false) end
	lastAttack[player]=now
	local enemy=targets(player,class.range)[1]
	local point=if enemy then enemy.root.Position else root.Position+root.CFrame.LookVector*8
	notify:FireAllClients({kind="strike",origin=root.Position,position=point,classId=p.classId,userId=player.UserId,color=class.color})
	if enemy then damage(player,enemy,class.damage) end
end

local function skill(player: Player)
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
		cast.radius=22
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
	local windup=windupOverride or (if record.phase==2 then 1.05 else record.stats.windup)
	beginCast(record,"RootBurst",windup)
	faceTowards(record,root.Position)
	local radius=if boss and record.phase==2 then 10 else record.stats.radius
	local centers={if boss then Vector3.new(root.Position.X,2.75,root.Position.Z) else Vector3.new(record.root.Position.X,2.75,record.root.Position.Z)}
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
						if not hit[player] and (flat-center).Magnitude<=radius then
							hit[player]=true
							if not dodging(player) then
								hurtPlayer(player,record.stats.damage+(if record.phase==2 then 5 else 0),center)
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
	notify:FireAllClients({kind="vineTelegraph",from=origin,to=tip,duration=windup,width=2.4})
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
		notify:FireAllClients({kind="vine",from=origin,to=stop,travel=travel,caught=caught and caught.UserId or nil})
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
				snare(caught,1.0,part.Position)
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
		if pulled and caught and record.hp>0 then rootBurst(record,caught,0.55) end
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
	notify:FireAllClients({kind="telegraph",position=Vector3.new(front.X,2.75,front.Z),radius=2.6,duration=windup,small=true})
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
	notify:FireAllClients({kind="telegraph",position=Vector3.new(front.X,2.75,front.Z),radius=3.6,duration=windup,small=true})
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
	local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances={workspace:FindFirstChild("PortalChapter") or workspace.Terrain,workspace.Terrain}
	if not workspace:Raycast(wanted+Vector3.new(0,6,0),Vector3.new(0,-20,0),params) then return end
	local from=record.root.Position
	if record.motion then record.motion:Cancel() end
	record.root.CFrame=CFrame.lookAt(Vector3.new(wanted.X,from.Y,wanted.Z),Vector3.new(root.Position.X,from.Y,root.Position.Z))
	record.nextBlink=os.clock()+7
	notify:FireAllClients({kind="blink",from=from,to=record.root.Position,color=record.stats.color})
end

local function cast(record: any,target: Player)
	if record.casting or record.hp<=0 then return end
	record.casting=true
	if record.motion then record.motion:Cancel() end
	local root=playerRoot(target)
	if not root then record.casting=false return end
	local boss=record.definition.kind=="Boss"
	local ranged=record.definition.kind=="Wisp" or boss
	local centers={if ranged then Vector3.new(root.Position.X,2.75,root.Position.Z) else Vector3.new(record.root.Position.X,2.75,record.root.Position.Z)}
	local radius=if boss and record.phase==2 then 10 else record.stats.radius
	local windup=if record.phase==2 then 1.05 else record.stats.windup
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
						if not hit[player] and (flat-center).Magnitude<=radius then hit[player]=true if not dodging(player) then hurtPlayer(player,record.stats.damage+(if record.phase==2 then 5 else 0),center) end end
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

function Service.init(attackRemote: RemoteEvent,skillRemote: RemoteEvent,dashRemote: RemoteEvent,notifyRemote: RemoteEvent,questService: any,blockRemote: RemoteEvent?)
	notify=notifyRemote quests=questService
	for _, definition in Chapter.Encounters do makeRecord(definition) end
	if blockRemote then blockRemote.OnServerEvent:Connect(setBlocking) end
	Players.PlayerAdded:Connect(function(player) player.CharacterAdded:Connect(function() player:SetAttribute("Blocking",false) end) end)
	for _, player in Players:GetPlayers() do player.CharacterAdded:Connect(function() player:SetAttribute("Blocking",false) end) end
	attackRemote.OnServerEvent:Connect(attack)
	skillRemote.OnServerEvent:Connect(skill)
	dashRemote.OnServerEvent:Connect(dash)
	Players.PlayerRemoving:Connect(function(player)
		lastAttack[player]=nil lastSkill[player]=nil lastDash[player]=nil
		for _, r in records do r.contributors[player]=nil end
	end)
	local elapsed=0
	RunService.Heartbeat:Connect(function(dt)
		elapsed+=dt if elapsed<0.16 then return end
		local step=math.min(elapsed,0.4) elapsed=0
		for _, r in records do
			if r.hp<=0 or r.casting then continue end
			local target=nil local distance=math.huge local point=nil
			for _, player in Players:GetPlayers() do
				local root=playerRoot(player)
				if root and eligible(player,r) and (root.Position-r.origin).Magnitude<=r.definition.leash then
					local d=(root.Position-r.root.Position).Magnitude
					if d<distance then target=player point=root.Position distance=d end
				end
			end

			if target then r.idleSince=nil elseif r.engaged and r.hp<r.max then
				r.idleSince=r.idleSince or os.clock()
				if os.clock()-r.idleSince>12 then
					r.hp=r.max r.phase=1 r.engaged=false r.contributors={}
					r.model:SetAttribute("Health",r.hp) r.model:SetAttribute("Phase",1)
					for _, piece in r.model:GetChildren() do if piece:IsA("BasePart") and (piece.Name=="Core" or piece.Name=="Eye") then piece.Color=Color3.fromRGB(76,201,205) end end
				end
			end
			local wanted=point or r.origin
			local delta=Vector3.new(wanted.X-r.root.Position.X,0,wanted.Z-r.root.Position.Z)
			local boss=r.definition.kind=="Boss"
			local kind=r.definition.kind
			local now=os.clock()
			local ready=now>=r.nextCast
			local sees=target~=nil and (boss or lineOfSight(target :: Player,r))
			-- Escolha de movimento por tipo de criatura.
			if target and sees then
				local t=target :: Player
				if kind=="Moss" then
					if distance<=r.stats.radius+1 and ready then rootBurst(r,t) continue end
					if distance>r.stats.radius+1 and distance<=20 and now>=(r.nextGrab or 0) and ready then vineGrab(r,t,20) continue end
				elseif kind=="Boss" then
					if distance>14 and distance<=32 and now>=(r.nextGrab or 0) and ready then vineGrab(r,t,32) continue end
					if distance<=42 and ready then rootBurst(r,t) continue end
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
				if r.motion then r.motion:Cancel() end
				r.motion=TweenService:Create(r.root,TweenInfo.new(0.16,Enum.EasingStyle.Linear),{CFrame=CFrame.lookAt(pos,pos+delta.Unit)})
				r.motion:Play()
			end
		end
	end)
end

return Service
