--!strict
local Players=game:GetService("Players")
local Data=require(script.Parent.PlayerDataService)
local Expedition={MinimumPlayers=3,RecommendedPlayers=6}
local started=false
function Expedition.readyCount(): number
	local count=0
	for _,player in Players:GetPlayers() do
		local profile=Data.get(player)
		if profile and profile.classId then count+=1 end
	end
	return count
end
function Expedition.tryBegin(): (boolean,number)
	local count=Expedition.readyCount()
	if count>=Expedition.MinimumPlayers then started=true end
	workspace:SetAttribute("ExpeditionStarted",started)
	workspace:SetAttribute("ExpeditionReadyPlayers",count)
	return started,count
end
function Expedition.hasStarted(): boolean return started end
function Expedition.init()
	workspace:SetAttribute("ExpeditionStarted",false)
	workspace:SetAttribute("ExpeditionMinimumPlayers",Expedition.MinimumPlayers)
	workspace:SetAttribute("ExpeditionRecommendedPlayers",Expedition.RecommendedPlayers)
	task.spawn(function()
		while true do
			workspace:SetAttribute("ExpeditionReadyPlayers",Expedition.readyCount())
			task.wait(1)
		end
	end)
end
return Expedition
