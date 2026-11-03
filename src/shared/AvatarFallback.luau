--!strict
-- Contingência local somente para conteúdo que o ContentProvider confirmou como falho.
-- Não substitui controles, rig, colisões, identidade ou assets que carregaram.
local Players=game:GetService("Players")
local ContentProvider=game:GetService("ContentProvider")
local RunService=game:GetService("RunService")
local Art=require(script.Parent.Art)
local Classes=require(script.Parent.Config.Classes)
local Motion=require(script.Parent.CharacterMotion)
local Fallback={}
local actors: {[Model]: any}={}

local function failed(id: string): boolean
	local ok,status=pcall(function() return ContentProvider:GetAssetFetchStatus(id) end)
	return ok and (status==Enum.AssetFetchStatus.Failure or status==Enum.AssetFetchStatus.TimedOut)
end

local function weldPart(parent: Instance,body: BasePart,name: string,size: Vector3,offset: CFrame,color: Color3,shape: Enum.PartType?)
	local p=Art.part(parent,name,size,body.CFrame*offset,color,Enum.Material.SmoothPlastic,shape)
	p.Anchored=false p.Massless=true
	local weld=Instance.new("WeldConstraint") weld.Part0=body weld.Part1=p weld.Parent=p
	return p
end

local function shell(body: MeshPart,player: Player,connections: {RBXScriptConnection})
	if body:FindFirstChild("PortalFallbackSurface") then return end
	local m=Instance.new("Model") m.Name="PortalFallbackSurface" m.Parent=body
	local class=Classes[player:GetAttribute("ClassId") or "Guardian"]
	local tint=body.Color
	if tint.R>0.85 and tint.G>0.7 and tint.B<0.3 then tint=Color3.fromRGB(209,176,143) end
	if string.find(body.Name,"Torso") then tint=Color3.fromRGB(43,65,82)
	elseif string.find(body.Name,"Leg") or string.find(body.Name,"Foot") then tint=Color3.fromRGB(52,62,70)
	elseif string.find(body.Name,"Arm") then tint=class.color:Lerp(Color3.fromRGB(40,57,67),0.55) end
	weldPart(m,body,"Surface",body.Size*Vector3.new(0.9,1,0.9),CFrame.identity,tint,Enum.PartType.Ball)
	if body.Name=="Head" then
		local size=body.Size
		for _, side in {-1,1} do
			weldPart(m,body,"Eye",Vector3.new(0.09,0.12,0.055),CFrame.new(side*size.X*0.19,size.Y*0.05,-size.Z*0.46),Color3.fromRGB(43,53,61),Enum.PartType.Ball)
			weldPart(m,body,"Glint",Vector3.new(0.035,0.035,0.025),CFrame.new(side*size.X*0.19+0.02,size.Y*0.08,-size.Z*0.49),Color3.new(1,1,1),Enum.PartType.Ball)
		end
		weldPart(m,body,"Hair",size*Vector3.new(0.95,0.65,0.95),CFrame.new(0,size.Y*0.3,size.Z*0.1),Color3.fromRGB(73,58,48),Enum.PartType.Ball)
		weldPart(m,body,"Mouth",Vector3.new(0.16,0.035,0.04),CFrame.new(0,-size.Y*0.23,-size.Z*0.43),Color3.fromRGB(127,85,73),Enum.PartType.Ball)
	end
	local connection: RBXScriptConnection?=nil
	connection=ContentProvider:GetAssetFetchStatusChangedSignal(body.MeshId):Connect(function(status)
		if status==Enum.AssetFetchStatus.Success and m.Parent then m:Destroy() end
		if status==Enum.AssetFetchStatus.Success and connection then connection:Disconnect() end
	end)
	table.insert(connections,connection :: RBXScriptConnection)
end

local function bind(player: Player,character: Model)
	task.delay(5,function()
		if not character.Parent then return end
		local humanoid=character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		local actor={player=player,humanoid=humanoid,joints={},animate=false,connections={},phase=0,stride=0,poses={},combat=false}
		local failedMeshes=0
		for _, item in character:GetChildren() do
			if item:IsA("MeshPart") and failed(item.MeshId) then shell(item,player,actor.connections) failedMeshes+=1 end
		end
		local failedAnimations=0
		for _, item in character:GetDescendants() do
			if item:IsA("Animation") and failed(item.AnimationId) then failedAnimations+=1 end
			if item:IsA("Motor6D") or item:IsA("AnimationConstraint") then table.insert(actor.joints,item) end
		end
		local hasLoadedTrack=false
		local animator=humanoid:FindFirstChildOfClass("Animator")
		if animator then for _, track in animator:GetPlayingAnimationTracks() do if track.Length>0 then hasLoadedTrack=true end end end
		actor.animate=failedAnimations>0 and not hasLoadedTrack
		actors[character]=actor
		if actor.animate and player==Players.LocalPlayer then
			local animate=character:FindFirstChild("Animate")
			if animate and animate:IsA("LocalScript") then animate.Enabled=false end
		end
		if failedMeshes>0 or actor.animate then
			character:SetAttribute("PortalFallbackActive",true)
			warn("[PortalPerdido][AssetFallback]",player.Name,"malhas indisponíveis="..failedMeshes,"animação de contingência="..tostring(actor.animate))
		end
	end)
end

function Fallback.init()
	local function register(player: Player)
		player.CharacterAdded:Connect(function(character) bind(player,character) end)
		if player.Character then bind(player,player.Character) end
	end
	Players.PlayerAdded:Connect(register)
	for _, player in Players:GetPlayers() do register(player) end
	RunService.PreSimulation:Connect(function(dt)
		local time=os.clock()
		for character,actor in actors do
			if not character.Parent then
				for _, connection in actor.connections do connection:Disconnect() end
				actors[character]=nil continue
			end
			local started=character:GetAttribute("PortalAttackStarted")
			local duration=character:GetAttribute("PortalAttackDuration") or 0.5
			local progress=if typeof(started)=="number" then (time-started)/duration else 2
			local attacking=progress>=0 and progress<=1
			if not actor.animate and not attacking and not actor.combat then continue end
			local root=character:FindFirstChild("HumanoidRootPart")
			local speed=if root and root:IsA("BasePart") then Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude else 0
			local targetStride=math.clamp(speed/16,0,1)
			actor.stride+=(targetStride-actor.stride)*(1-math.exp(-dt*12))
			-- Phase advances with distance travelled rather than wall time: no foot cycling at rest.
			actor.phase+=speed*dt*0.67
			local state=actor.humanoid:GetState()
			local airborne=state==Enum.HumanoidStateType.Freefall or state==Enum.HumanoidStateType.Jumping
			local classId=character:GetAttribute("PortalAttackClass") or actor.player:GetAttribute("ClassId") or "Guardian"
			for _,joint in actor.joints do
				if not joint.Parent then continue end
				local name=joint.Name:gsub(" ",""):lower()
				local target=Motion.pose(name,actor.phase,actor.stride,airborne,classId,if attacking then progress else nil,time)
				if not actor.animate and not attacking then target=CFrame.identity end
				local previous=actor.poses[joint] or CFrame.identity
				local pose=previous:Lerp(target,1-math.exp(-dt*22))
				actor.poses[joint]=pose
				if actor.animate then joint.Transform=pose
				elseif name:find("shoulder") or name:find("elbow") or name=="waist" then
					joint.Transform=joint.Transform*pose
				end
			end
			actor.combat=attacking or (actor.combat and progress<1.25)

		end
	end)
end

return Fallback
