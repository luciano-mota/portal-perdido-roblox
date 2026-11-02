--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Classes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Classes"))

local ClassService = {}
local lastRequest: { [Player]: number } = {}

local function applyHealth(character: Model, classId: string)
	local definition = Classes[classId]
	if not definition then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.MaxHealth = definition.health
		humanoid.Health = definition.health
	end
end

function ClassService.select(player: Player, classId: any): boolean
	if player.Parent ~= Players then
		return false
	end
	if typeof(classId) ~= "string" or Classes[classId] == nil then
		return false
	end
	-- Classe fixa na demonstração: impedir troca em pleno combate.
	if player:GetAttribute("ClassId") ~= nil then
		return false
	end

	local now = os.clock()
	local previous = lastRequest[player]
	if previous ~= nil and now - previous < 1 then
		return false
	end
	lastRequest[player] = now
	player:SetAttribute("ClassId", classId)
	if player.Character then
		applyHealth(player.Character, classId)
	end
	return true
end

local function registerPlayer(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		-- Read the selection after the Humanoid exists: the client can select
		-- during character construction, before applyHealth can find it.
		local humanoid = character:WaitForChild("Humanoid", 10)
		local classId = player:GetAttribute("ClassId")
		if humanoid and humanoid:IsA("Humanoid") and typeof(classId) == "string" then
			applyHealth(character, classId)
		end
	end)
end

function ClassService.init(chooseClassRemote: RemoteEvent)
	chooseClassRemote.OnServerEvent:Connect(function(player: Player, classId: any)
		ClassService.select(player, classId)
	end)
	Players.PlayerAdded:Connect(registerPlayer)
	for _, player in Players:GetPlayers() do
		registerPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		lastRequest[player] = nil
	end)
end

return ClassService
