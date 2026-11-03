--!strict
-- Contingência local somente para conteúdo que o ContentProvider confirmou como falho.
-- Não substitui controles, rig, colisões, identidade ou assets que carregaram.
local Players=game:GetService("Players")
local ContentProvider=game:GetService("ContentProvider")
local RunService=game:GetService("RunService")
local Art=require(script.Parent.Art)
local Classes=require(script.Parent.Config.Classes)
local Motion=require(script.Parent.CharacterMotion)
local Face=require(script.Parent.FacePresentation)
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
	local existing=body:FindFirstChild("PortalFallbackSurface")
	if existing then
		local surface=existing:FindFirstChild("Surface")
		if body.Name=="Head" and surface and surface:IsA("BasePart") and Face.apply(surface,player:GetAttribute("ClassId") or "Guardian") then
			for _,item in existing:GetChildren() do if item:IsA("BasePart") and (item.Name=="Eye" or item.Name=="Glint" or item.Name=="Mouth") then item.Transparency=1 end end
		end
		return
	end
	local m=Instance.new("Model") m.Name="PortalFallbackSurface" m.Parent=body
	local class=Classes[player:GetAttribute("ClassId") or "Guardian"] or Classes.Guardian
	local tint=body.Color
	if tint.R>0.85 and tint.G>0.7 and tint.B<0.3 then tint=Color3.fromRGB(209,176,143) end
	if string.find(body.Name,"Torso") then tint=Color3.fromRGB(43,65,82)
	elseif string.find(body.Name,"Leg") or string.find(body.Name,"Foot") then tint=Color3.fromRGB(52,62,70)
	elseif string.find(body.Name,"Arm") then tint=class.color:Lerp(Color3.fromRGB(40,57,67),0.55) end
	local surface=weldPart(m,body,"Surface",body.Size*Vector3.new(0.9,1,0.9),CFrame.identity,tint,Enum.PartType.Ball)
	if body.Name=="Head" then
		local size=body.Size
		local textured=Face.apply(surface,player:GetAttribute("ClassId") or "Guardian")
		if not textured then
		for _, side in {-1,1} do
			weldPart(m,body,"Eye",Vector3.new(0.09,0.12,0.055),CFrame.new(side*size.X*0.19,size.Y*0.05,-size.Z*0.46),Color3.fromRGB(43,53,61),Enum.PartType.Ball)
			weldPart(m,body,"Glint",Vector3.new(0.035,0.035,0.025),CFrame.new(side*size.X*0.19+0.02,size.Y*0.08,-size.Z*0.49),Color3.new(1,1,1),Enum.PartType.Ball)
		end
		weldPart(m,body,"Mouth",Vector3.new(0.16,0.035,0.04),CFrame.new(0,-size.Y*0.23,-size.Z*0.43),Color3.fromRGB(127,85,73),Enum.PartType.Ball)
		end
		weldPart(m,body,"Hair",size*Vector3.new(0.95,0.65,0.95),CFrame.new(0,size.Y*0.3,size.Z*0.1),Color3.fromRGB(73,58,48),Enum.PartType.Ball)
	end
	local connection: RBXScriptConnection?=nil
	connection=ContentProvider:GetAssetFetchStatusChangedSignal(body.MeshId):Connect(function(status)
		if status==Enum.AssetFetchStatus.Success and m.Parent then m:Destroy() end
		if status==Enum.AssetFetchStatus.Success and connection then connection:Disconnect() end
	end)
	table.insert(connections,connection :: RBXScriptConnection)
end

local function bind(player: Player,character: Model)
	task.spawn(function()
		local humanoid=character:WaitForChild("Humanoid",10)
		if not humanoid or not humanoid:IsA("Humanoid") or not character.Parent then return end
		local actor={player=player,humanoid=humanoid,joints={},animate=false,connections={},phase=0,stride=0,poses={},combat=false}
		actors[character]=actor
		-- O estado de download pode mudar depois do primeiro prazo. Reavaliar também
		-- restaura a apresentação nativa se os assets voltarem a carregar.
		task.wait(5)
		local warned=false
		while character.Parent and actors[character]==actor do
			local failedMeshes=0
			for _,item in character:GetChildren() do
				if item:IsA("MeshPart") and failed(item.MeshId) then shell(item,player,actor.connections) failedMeshes+=1 end
			end
			local failedAnimations=0
			local joints={}
			for _,item in character:GetDescendants() do
				if item:IsA("Animation") and failed(item.AnimationId) then failedAnimations+=1 end
				if (item:IsA("Motor6D") or item:IsA("AnimationConstraint")) and item.Name~="BowOrientation" then table.insert(joints,item) end
			end
			actor.joints=joints
			local loaded=false
			local animator=humanoid:FindFirstChildOfClass("Animator")
			if animator then for _,track in animator:GetPlayingAnimationTracks() do if track.Length>0 then loaded=true end end end
			local needsMotion=failedAnimations>0 and not loaded
			local animate=character:FindFirstChild("Animate")
			if player==Players.LocalPlayer and animate and animate:IsA("LocalScript") then
				if needsMotion and animate.Enabled then actor.disabledAnimate=animate animate.Enabled=false
				elseif not needsMotion and actor.disabledAnimate==animate then animate.Enabled=true actor.disabledAnimate=nil end
			end
			actor.animate=needsMotion
			character:SetAttribute("PortalFallbackActive",failedMeshes>0 or needsMotion)
			if (failedMeshes>0 or needsMotion) and not warned then
				warned=true
				warn("[PortalPerdido][AssetFallback]",player.Name,"malhas indisponíveis="..failedMeshes,"animação de contingência="..tostring(needsMotion))
			end
			task.wait(3)
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
			local root=character:FindFirstChild("HumanoidRootPart")
			if actor.player==Players.LocalPlayer then
				local aim=character:GetAttribute("PortalAimPosition")
				if attacking and root and root:IsA("BasePart") and typeof(aim)=="Vector3" then
					if actor.autoRotateBefore==nil then actor.autoRotateBefore=actor.humanoid.AutoRotate end
					actor.humanoid.AutoRotate=false
					local delta=Vector3.new(aim.X-root.Position.X,0,aim.Z-root.Position.Z)
					if delta.Magnitude>0.1 then
						local rotation=root.CFrame.Rotation:Lerp(CFrame.lookAt(Vector3.zero,delta),1-math.exp(-dt*24))
						root.CFrame=CFrame.new(root.Position)*rotation
					end
				elseif actor.autoRotateBefore~=nil then actor.humanoid.AutoRotate=actor.autoRotateBefore actor.autoRotateBefore=nil end
			end
			local equipment=character:FindFirstChild("ClassEquipment")
			local mount=equipment and equipment:FindFirstChild("BowGrip")
			local bowJoint=mount and mount:FindFirstChild("BowOrientation")
			if bowJoint and bowJoint:IsA("Motor6D") and bowJoint.Part0 and root and root:IsA("BasePart") then
				bowJoint.Transform=bowJoint.Part0.CFrame.Rotation:Inverse()*root.CFrame.Rotation*CFrame.Angles(0,-math.pi/2,0)
			end
			if equipment and (attacking or actor.combat) then
				local drawing=attacking and progress<0.55
				for _,piece in equipment:GetChildren() do
					if piece:IsA("Beam") and piece.Name=="DrawnString" then piece.Enabled=drawing
					elseif piece:IsA("BasePart") and piece.Name=="BowString" then piece.Transparency=if drawing then 1 else 0 end
				end
			end
			if not actor.animate and not attacking and not actor.combat then continue end
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
				elseif name:find("shoulder") or name:find("elbow") or name:find("wrist") or name=="waist" then
					joint.Transform=joint.Transform*pose
				end
			end
			actor.combat=attacking or (actor.combat and progress<1.25)

		end
	end)
end

return Fallback
