--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Classes=require(ReplicatedStorage.Shared.Config.Classes)
local Chapter=require(ReplicatedStorage.Shared.Config.Chapter)
local Art=require(ReplicatedStorage.Shared.Art)
local Data=require(script.Parent.PlayerDataService)
local Service={}
local templates={Explorer="ExplorerTemplate",Guardian="GuardianTemplate",Artificer="ArtificerTemplate"}

-- Antes da escolha de classe o avatar padrão do Roblox não deve aparecer (prólogo/seleção):
-- fica invisível e parado no spawn. A escolha troca o personagem pelo rig humanizado.
local function setAwaiting(character: Model, root: BasePart, humanoid: Humanoid, awaiting: boolean)
	if (character:GetAttribute("AwaitingClass")==true)==awaiting then return end
	character:SetAttribute("AwaitingClass",awaiting)
	for _,item in character:GetDescendants() do
		if item:IsA("BasePart") or item:IsA("Decal") then
			if awaiting then
				if item:GetAttribute("PortalOriginalTransparency")==nil then item:SetAttribute("PortalOriginalTransparency",item.Transparency) end
				item.Transparency=1
			else
				local original=item:GetAttribute("PortalOriginalTransparency")
				if typeof(original)=="number" then item.Transparency=original end
			end
		end
	end
	root.Anchored=awaiting
	humanoid.DisplayDistanceType=if awaiting then Enum.HumanoidDisplayDistanceType.None else Enum.HumanoidDisplayDistanceType.Viewer
end

local function apply(player: Player, character: Model, moveToCheckpoint: boolean)
	local humanoid=character:WaitForChild("Humanoid",10)
	local root=character:WaitForChild("HumanoidRootPart",10)
	local profile=Data.get(player)
	if not profile or player.Character~=character or not humanoid or not humanoid:IsA("Humanoid") or not root or not root:IsA("BasePart") then return end
	if not profile.classId then
		-- Acessórios podem chegar depois do CharacterAdded; uma segunda passada cobre o atraso.
		setAwaiting(character,root,humanoid,true)
		task.delay(1,function()
			local latest=Data.get(player)
			if player.Character==character and latest and not latest.classId then
				character:SetAttribute("AwaitingClass",false)
				setAwaiting(character,root,humanoid,true)
			end
		end)
		return
	end
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
	-- Contingência: classe sem template disponível mantém o avatar padrão, agora visível.
	setAwaiting(character,root,humanoid,false)
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
		-- Bolha visível só fora da vila (respawn em combate); na entrada do jogo ela só protege.
		local grace=Instance.new("ForceField") grace.Name="SpawnGrace" grace.Visible=profile.checkpoint~="Village" grace.Parent=character
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

-- Cópias estáticas dos rigs gerados para os retratos da tela de seleção (somente visual).
local function publishPreviews()
	local folder=Instance.new("Folder") folder.Name="ClassPreviews"
	for classId,templateName in templates do
		local template=game:GetService("ServerStorage"):FindFirstChild(templateName)
		if template and template:IsA("Model") then
			local preview=template:Clone()
			preview.Name=classId
			for _,item in preview:GetDescendants() do
				if item:IsA("LuaSourceContainer") or item:IsA("Humanoid") then item:Destroy()
				elseif item:IsA("BasePart") then item.Anchored=true item.CanCollide=false item.CanQuery=false item.CanTouch=false end
			end
			preview:SetAttribute("PortalGeneratedRig",true)
			local definition=Classes[classId]
			if definition then Art.equipment(preview,classId,definition.color) end
			preview.Parent=folder
		end
	end
	folder.Parent=ReplicatedStorage
end

function Service.init(remote: RemoteEvent)
	remote.OnServerEvent:Connect(Service.select)
	publishPreviews()
end

return Service
