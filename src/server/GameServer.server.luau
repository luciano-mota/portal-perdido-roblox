--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local services = ServerScriptService:WaitForChild("Services")
local ClassService = require(services:WaitForChild("ClassService"))
local WorldBuilder = require(services:WaitForChild("WorldBuilder"))
local QuestService = require(services:WaitForChild("QuestService"))
local EnemyService = require(services:WaitForChild("EnemyService"))

local existingFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
local remoteFolder: Folder
if existingFolder and existingFolder:IsA("Folder") then
	remoteFolder = existingFolder
else
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "GameRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name: string): RemoteEvent
	local existing = remoteFolder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remoteFolder
	return remote
end

local chooseClass = getOrCreateRemote("ChooseClass")
local attackEnemy = getOrCreateRemote("AttackEnemy")

WorldBuilder.build()
ClassService.init(chooseClass)
QuestService.init()
EnemyService.init(attackEnemy, QuestService)

print("[Portal Perdido] Primeira aventura inicializada: classe, mentora, sentinela e missão.")
