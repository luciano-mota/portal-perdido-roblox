--!strict
local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local ProfileStore=require(script.Parent.ProfileStore)
local Data={}
local sessions: {[Player]: any}={}
local store: any=nil
local closing=false

function Data.get(player: Player)
	local session=sessions[player]
	return if session then session.profile else nil
end

function Data.publish(player: Player)
	local p=Data.get(player)
	if not p then return end
	player:SetAttribute("ClassId",p.classId)
	player:SetAttribute("Coins",p.coins)
	player:SetAttribute("QuestIndex",p.quest)
	local count=0 for _, id in {"Dawn","Root","Star"} do if p.runes[id] then count+=1 end end
	player:SetAttribute("RuneCount",count)
	for _, id in {"Dawn","Root","Star"} do player:SetAttribute("Rune"..id,p.runes[id]==true) end
	player:SetAttribute("SealProgress",p.seals)
	player:SetAttribute("HasFragment",p.fragment)
	player:SetAttribute("BossDefeated",p.bossDefeated==true)
	player:SetAttribute("QuestState",if p.quest>5 then "COMPLETED" else "ACTIVE")
	player:SetAttribute("Checkpoint",p.checkpoint)
end

function Data.mutate(player: Player, change: (any) -> ())
	local session=sessions[player]
	if not session then return false end
	change(session.profile)
	session.revision+=1
	if not session.readOnly then player:SetAttribute("DataStatus","Pending") end
	Data.publish(player)
	return true
end

function Data.award(player: Player, quest: number, amount: number)
	Data.mutate(player,function(p)
		local key=tostring(quest)
		if not p.rewards[key] then p.rewards[key]=true p.coins+=amount end
	end)
end

function Data.save(player: Player, release: boolean?)
	local session=sessions[player]
	if not session or session.readOnly then return false end
	if session.saving then
		if release then
			local started=os.clock()
			while session.saving and os.clock()-started<12 do task.wait(0.1) end
			if session.saving then return false end
		else return false end
	end
	session.saving=true
	local savedRevision=session.revision
	local snapshot=HttpService:JSONDecode(HttpService:JSONEncode(session.profile))
	local success=false
	local failure="NETWORK"
	for attempt=1,3 do
		local ok,result,reason=pcall(function() return store:save("player_"..player.UserId,snapshot,release==true) end)
		if ok and result then success=true break end
		failure=if ok then tostring(reason) else "NETWORK"
		if failure=="LOST_LEASE" then session.readOnly=true break end
		if attempt<3 then task.wait(attempt) end
	end
	session.saving=false
	if success then
		player:SetAttribute("DataStatus",if session.revision==savedRevision then "Saved" else "Pending")
	else
		player:SetAttribute("DataStatus",if failure=="LOST_LEASE" then "SessionLost" else "SaveFailed")
		warn("[PortalPerdido][Data] Save failed",player.UserId,failure)
	end
	return success
end

local function load(player: Player, ready: (Player) -> ())
	player:SetAttribute("DataStatus","Loading")
	local profile=nil
	local reason=nil
	if store then
		for attempt=1,3 do
			local ok,p,r=pcall(function() return store:load("player_"..player.UserId) end)
			if ok then profile=p reason=r if p or r=="BUSY" or r=="CORRUPT" then break end end
			if attempt<3 then task.wait(attempt) end
		end
	else reason="STUDIO" end
	local readOnly=profile==nil
	profile=profile or ProfileStore.fresh()
	sessions[player]={profile=profile,readOnly=readOnly,revision=0,saving=false}
	if player.Parent~=Players then
		if not readOnly then Data.save(player,true) end
		sessions[player]=nil return
	end
	player:SetAttribute("DataStatus",if reason=="STUDIO" then "StudioMemory" elseif reason=="BUSY" then "SessionBusy" elseif reason=="CORRUPT" then "DataUnavailable" elseif readOnly then "DataUnavailable" else "Saved")
	Data.publish(player)
	ready(player)
end

function Data.init(ready: (Player) -> ())
	if not RunService:IsStudio() and game.PlaceId>0 then
		local adapter=DataStoreService:GetDataStore("PortalPerdido_Chapter1_v2")
		store=ProfileStore.new(adapter,game.JobId..HttpService:GenerateGUID(false),os.time)
	end
	Players.PlayerAdded:Connect(function(player) task.spawn(load,player,ready) end)
	for _, player in Players:GetPlayers() do task.spawn(load,player,ready) end
	Players.PlayerRemoving:Connect(function(player)
		Data.save(player,true)
		sessions[player]=nil
	end)
	task.spawn(function()
		while not closing do
			task.wait(45)
			for player,session in sessions do if not session.readOnly then task.spawn(Data.save,player,false) end end
		end
	end)
	game:BindToClose(function()
		closing=true
		local remaining=0
		for player,session in sessions do
			if not session.readOnly then
				remaining+=1
				task.spawn(function() Data.save(player,true) remaining-=1 end)
			end
		end
		local started=os.clock()
		while remaining>0 and os.clock()-started<25 do task.wait(0.1) end
	end)
end

return Data
