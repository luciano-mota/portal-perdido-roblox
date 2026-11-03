--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Classes=require(ReplicatedStorage.Shared.Config.Classes)
local Chapter=require(ReplicatedStorage.Shared.Config.Chapter)
local Art=require(ReplicatedStorage.Shared.Art)
local Data=require(script.Parent.PlayerDataService)
local Service={}
local templates={Explorer="ExplorerTemplate",Guardian="GuardianTemplate",Artificer="ArtificerTemplate"}

local function apply(player: Player, character: Model, moveToCheckpoint: boolean)
	local humanoid=character:WaitForChild("Humanoid",10)
	local root=character:WaitForChild("HumanoidRootPart",10)
	local profile=Data.get(player)
	if not profile or player.Character~=character or not humanoid or not humanoid:IsA("Humanoid") or not root then return end
	local templateName=profile.classId and templates[profile.classId]
	if templateName and not character:GetAttribute("PortalGeneratedRig") then
		local template=game:GetService("ServerStorage"):FindFirstChild(templateName)
		if template and template:IsA("Model") and template:FindFirstChild("HumanoidRootPart") and template:FindFirstChildOfClass("Humanoid") then
			local replacement=template:Clone()
			replacement.Name=player.Name
			replacement:SetAttribute("PortalGeneratedRig",true)
			for _,item in replacement:GetDescendants() do
				if item:IsA("LuaSourceContainer") then item:Destroy()
				elseif item:IsA("BasePart") then item.Anchored=false end
			end
			local loose=replacement:FindFirstChild("RBX_RIGID_neck",true)
			if loose then loose:Destroy() end
			local animate=character:FindFirstChild("Animate")
			if animate then animate:Clone().Parent=replacement end
			replacement:PivotTo(character:GetPivot())
			replacement.Parent=workspace
			player.Character=replacement
			character:Destroy()
			return
		end
	end
	local definition=profile.classId and Classes[profile.classId]
	if definition then
		humanoid.MaxHealth=definition.health humanoid.Health=definition.health
		Art.equipment(character,profile.classId,definition.color)
	end
	if moveToCheckpoint then
		local point=Chapter.Checkpoints[profile.checkpoint] or Chapter.Checkpoints.Village
		character:PivotTo(CFrame.new(point))
		-- Proteção curta ao renascer: o checkpoint da Arena fica dentro do alcance do chefe.
		-- Humanoid:TakeDamage ignora dano enquanto houver ForceField no personagem.
		local grace=Instance.new("ForceField") grace.Name="SpawnGrace" grace.Visible=true grace.Parent=character
		game:GetService("Debris"):AddItem(grace,4)
	end
	player:SetAttribute("ShieldUntil",0)
end

function Service.register(player: Player)
	player.CharacterAdded:Connect(function(character) task.spawn(apply,player,character,true) end)
	if player.Character then task.spawn(apply,player,player.Character,true) end
end

function Service.select(player: Player, classId: any): boolean
	local p=Data.get(player)
	if player.Parent~=Players or not p or p.classId~=nil or typeof(classId)~="string" or Classes[classId]==nil then return false end
	Data.mutate(player,function(profile) profile.classId=classId end)
	if player.Character then task.spawn(apply,player,player.Character,false) end
	task.spawn(Data.save,player,false)
	return true
end

function Service.init(remote: RemoteEvent)
	remote.OnServerEvent:Connect(Service.select)
end

return Service
