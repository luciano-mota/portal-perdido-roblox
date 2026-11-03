--!strict
-- Movimento visual local dos atores originais. Não modifica hitboxes, HP ou IA.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Presentation={}
local actors: {[Model]: any}={}

local function register(model: Model)
	if actors[model] or not model.PrimaryPart then return end
	local kind=model:GetAttribute("EnemyKind") or model:GetAttribute("PresentationKind")
	if typeof(kind)~="string" then return end
	local joints={}
	local eyes={}
	for _,item in model:GetDescendants() do
		if item:IsA("Motor6D") then table.insert(joints,item) end
		if kind=="Ilyra" and item:IsA("BasePart") and (item.Name=="Eye" or item.Name=="Iris" or item.Name=="Pupil") then table.insert(eyes,item) end
	end
	actors[model]={root=model.PrimaryPart,kind=kind,joints=joints,eyes=eyes,last=model.PrimaryPart.Position,phase=0,stride=0}
end

function Presentation.init()
	local elapsed=1
	RunService.PreSimulation:Connect(function(dt)
		elapsed+=dt
		if elapsed>=1 then
			elapsed=0
			local folder=workspace:FindFirstChild("PortalEnemies")
			if folder then for _,model in folder:GetChildren() do if model:IsA("Model") then register(model) end end end
			local world=workspace:FindFirstChild("PortalChapter")
			local village=world and world:FindFirstChild("Village")
			local npc=village and village:FindFirstChild("Ilyra")
			if npc and npc:IsA("Model") then register(npc) end
		end
		local character=Players.LocalPlayer.Character
		local playerRoot=character and character:FindFirstChild("HumanoidRootPart")
		local now=workspace:GetServerTimeNow()
		for model,actor in actors do
			local root=actor.root :: BasePart
			if not model.Parent or not root.Parent then actors[model]=nil continue end
			local distance=(root.Position-actor.last).Magnitude
			actor.last=root.Position
			if not playerRoot or not playerRoot:IsA("BasePart") or (root.Position-playerRoot.Position).Magnitude>150 then continue end
			local dead=(model:GetAttribute("Health") or 1)<=0
			local stride=if dead then 0 else math.clamp(distance/math.max(dt,0.001)/7,0,1)
			actor.stride+=(stride-actor.stride)*(1-math.exp(-dt*10))
			if distance<10 then actor.phase+=distance*(if actor.kind=="Boss" then 0.38 elseif actor.kind=="Thorn" then 1.25 else 0.85) end
			local castEnd=model:GetAttribute("CastEndsAt") or 0
			local castStart=model:GetAttribute("CastStartedAt") or 0
			local casting=not dead and castEnd>now
			local wind=if casting then math.clamp((now-castStart)/math.max(castEnd-castStart,0.1),0,1) else 0
			local impact=not dead and (model:GetAttribute("ImpactUntil") or 0)>now
			local talking=(model:GetAttribute("TalkingUntil") or 0)>now
			for _,joint in actor.joints do
				if not joint.Parent then continue end
				local name=joint.Name
				local side=if name:find("Left") then -1 else 1
				local pose=CFrame.identity
				if not dead then
					if actor.kind=="Ilyra" then
						if name=="Neck" then
							local relative=root.CFrame:VectorToObjectSpace(playerRoot.Position-root.Position)
							local yaw=if relative.Z<0 and relative.Magnitude<24 then math.clamp(math.atan2(-relative.X,-relative.Z),-0.32,0.32) else 0
							pose=CFrame.Angles(math.sin(now*(if talking then 2.1 else 1.1))*0.035,yaw,0)
						elseif name=="LeftShoulder" then pose=CFrame.Angles(-0.06-(if talking then 0.22+math.sin(now*1.8)*0.11 else math.sin(now*1.3)*0.025),0,-0.04)
						elseif name=="RightShoulder" then pose=CFrame.Angles(math.sin(now*1.3)*0.015,0,0) end
					elseif name:find("Hip") then
						local rear=if name:find("Rear") then -1 else 1
						pose=CFrame.Angles(math.sin(actor.phase)*actor.stride*side*rear*0.48,0,0)
					elseif name:find("Shoulder") then
						local x=if casting then -1.5*wind elseif impact then 0.45 else -math.sin(actor.phase)*actor.stride*side*0.35-0.04
						pose=CFrame.Angles(x,0,if casting then side*0.15*wind else side*0.035)
					elseif name=="Neck" then pose=CFrame.Angles(if casting then -0.1*wind else math.sin(now*1.2)*0.025,math.sin(now*0.7)*0.025,0)
					elseif name=="SpiritCore" then pose=CFrame.new(0,math.sin(now*2)*0.18,0)*CFrame.Angles(0,math.sin(now*0.8)*0.18,0) end
				end
				joint.Transform=joint.Transform:Lerp(pose,1-math.exp(-dt*16))
			end
			if actor.kind=="Ilyra" then
				local blink=now%5.3<0.12
				for _,eye in actor.eyes do if eye.Parent then eye.LocalTransparencyModifier=if blink then 1 else 0 end end
			end
		end
	end)
end

return Presentation
