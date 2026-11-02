--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local services = ServerScriptService:WaitForChild("Services")
local ClassService = require(services:WaitForChild("ClassService"))
local WorldBuilder = require(services:WaitForChild("WorldBuilder"))

local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
if remoteFolder == nil then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "GameRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local chooseClassRemote = remoteFolder:FindFirstChild("ChooseClass")
if chooseClassRemote == nil then
	chooseClassRemote = Instance.new("RemoteEvent")
	chooseClassRemote.Name = "ChooseClass"
	chooseClassRemote.Parent = remoteFolder
end

WorldBuilder.build()
ClassService.init(chooseClassRemote :: RemoteEvent)
print("[Portal Perdido] Servidor inicializado. Blockout e seleção de classe prontos.")
