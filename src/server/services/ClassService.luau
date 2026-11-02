--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Classes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Classes"))

local ClassService = {}
local lastRequest: { [Player]: number } = {}

function ClassService.select(player: Player, classId: any): boolean
	if player.Parent ~= Players then
		return false
	end
	if typeof(classId) ~= "string" or Classes[classId] == nil then
		return false
	end

	local now = os.clock()
	local last = lastRequest[player]
	if last ~= nil and now - last < 1 then
		return false
	end
	lastRequest[player] = now
	player:SetAttribute("ClassId", classId)
	return true
end

function ClassService.init(chooseClassRemote: RemoteEvent)
	chooseClassRemote.OnServerEvent:Connect(function(player: Player, classId: any)
		ClassService.select(player, classId)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		lastRequest[player] = nil
	end)
end

return ClassService
