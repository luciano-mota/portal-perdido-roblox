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
	Art.label(root,kind.name,nil,Color3.fromRGB(234,224,202),if definition.kind=="Boss" then 11 else 5)
	records[definition.id]={definition=definition,stats=kind,model=model,root=root,origin=origin,hp=kind.health,max=kind.health,phase=1,contributors={},casting=false,nextCast=0,slowUntil=0,engaged=false}
end

function Service.isAlive(id: string): boolean
	local r=records[id]
	return r~=nil and r.hp>0
end

local function hurtPlayer(player: Player,amount: number,position: Vector3)
	local _,humanoid=playerRoot(player)
	if not humanoid then return end
	local shield=player:GetAttribute("ShieldUntil")
	local reduced=typeof(shield)=="number" and shield>workspace:GetServerTimeNow()
	local damage=if reduced then math.floor(amount*0.35) else amount
	humanoid:TakeDamage(damage)
	notify:FireClient(player,{kind="hurt",amount=damage,shielded=reduced,position=position})
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

local function dash(player: Player)
	local root=playerRoot(player)
	if not root then return end
	local now=os.clock()
	if now-(lastDash[player] or -math.huge)<3 then return end
	lastDash[player]=now
	player:SetAttribute("DashReadyAt",workspace:GetServerTimeNow()+3)
	local direction=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
	if direction.Magnitude<0.1 then return end
	root.AssemblyLinearVelocity=direction.Unit*52+Vector3.new(0,root.AssemblyLinearVelocity.Y,0)
	notify:FireAllClients({kind="dash",position=root.Position,color=Color3.fromRGB(181,210,221),userId=player.UserId})
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
						if not hit[player] and (flat-center).Magnitude<=radius then hit[player]=true hurtPlayer(player,record.stats.damage+(if record.phase==2 then 5 else 0),center) end
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

function Service.init(attackRemote: RemoteEvent,skillRemote: RemoteEvent,dashRemote: RemoteEvent,notifyRemote: RemoteEvent,questService: any)
	notify=notifyRemote quests=questService
	for _, definition in Chapter.Encounters do makeRecord(definition) end
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
			local hitRange=if boss then 42 elseif r.definition.kind=="Wisp" then 25 else r.stats.radius+2
			if target and distance<=hitRange and os.clock()>=r.nextCast and (boss or lineOfSight(target,r)) then cast(r,target :: Player) continue end
			if delta.Magnitude>(if target then 5 else 0.3) then
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
