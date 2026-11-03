--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local services=script.Parent:WaitForChild("Services")
local Data=require(services.PlayerDataService)
local Classes=require(services.ClassService)
local World=require(services.WorldBuilder)
local Quests=require(services.QuestService)
local Enemies=require(services.EnemyService)
local folder=ReplicatedStorage:FindFirstChild("GameRemotes")
if not folder then folder=Instance.new("Folder") folder.Name="GameRemotes" folder.Parent=ReplicatedStorage end
local function remote(name: string): RemoteEvent
	local found=folder:FindFirstChild(name)
	if found and found:IsA("RemoteEvent") then return found end
	local event=Instance.new("RemoteEvent") event.Name=name event.Parent=folder return event
end
local choose=remote("ChooseClass")
local attack=remote("AttackEnemy")
local skill=remote("UseSkill")
local dash=remote("Dash")
local notify=remote("Notify")
local block=remote("Block")
World.build()
Classes.init(choose)
Quests.init(notify,Enemies.isAlive)
Enemies.init(attack,skill,dash,notify,Quests,block)
Data.init(function(player)
	Classes.register(player)
	Quests.register(player)
end)
print("[PortalPerdido] Capítulo 1 pronto: cinco missões, três classes, floresta, templo e Guardião.")
