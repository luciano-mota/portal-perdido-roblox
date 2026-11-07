--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local services=script.Parent:WaitForChild("Services")
local Data=require(services.PlayerDataService)
local Classes=require(services.ClassService)
local World=require(services.WorldBuilder)
local Quests=require(services.QuestService)
local Enemies=require(services.EnemyService)
local Expedition=require(services.ExpeditionService)
local Regions=require(services.Regions)
local Travel=require(services.TravelService)
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
local kick=remote("Kick")
World.build()
local world=workspace:WaitForChild("PortalChapter") :: Model
Classes.spawnResolver=Travel.spawnFor
Expedition.init()
Classes.init(choose)
Quests.init(notify,Enemies.isAlive)
Enemies.init(attack,skill,dash,notify,Quests,block,kick)
Data.init(function(player)
	Classes.register(player)
	Quests.register(player)
end)
-- Regiões 2–6 depois do Vale e dos serviços: quem entra já joga enquanto elas são montadas.
Regions.build(world)
Travel.init(world,notify)
-- Ganchos de QA apenas no Studio: BindableFunction em ServerStorage não é acessível
-- pelo cliente e não existe em servidores publicados. Usado por testes via MCP, que
-- executam em outra VM e não compartilham o estado dos módulos.
if game:GetService("RunService"):IsStudio() then
	local qa=Instance.new("BindableFunction") qa.Name="QAFixtures"
	qa.OnInvoke=function(op: string,player: Player?,value: any)
		if op=="beginSolo" then Expedition.MinimumPlayers=1 return Expedition.tryBegin() end
		if op=="travel" and player and typeof(value)=="string" then return Travel.send(player,value) end
		if op=="openGates" then workspace:SetAttribute("CampaignOpenGates",value==true) return value==true end
		if op=="setQuest" and player and typeof(value)=="number" then
			Data.mutate(player,function(profile) profile.quest=value end) return Data.get(player).quest
		end
		return nil
	end
	qa.Parent=game:GetService("ServerStorage")
end
print("[PortalPerdido] Capítulo 1 pronto: cinco missões, três classes, floresta, templo e Guardião.")
