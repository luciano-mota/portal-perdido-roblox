--!strict
-- Protocolo de lease testável com adapter; nenhuma chamada de rede no transform.
local ProfileStore = {}
ProfileStore.__index = ProfileStore
local allowedClasses = {Guardian=true, Explorer=true, Artificer=true, Brawler=true, Arcanist=true, Shade=true}
-- Heróis desbloqueáveis na Rota A (persistem na conta, sem duplicar recompensa).
local unlockable = {"Brawler","Arcanist","Shade"}

function ProfileStore.fresh()
	return {version=2, quest=1, coins=0, runes={}, seals=0, rewards={}, fragment=false, bossDefeated=false, checkpoint="Village", heroes={}}
end

function ProfileStore.sanitize(value: any)
	if typeof(value) ~= "table" or value.version ~= 2 then return nil end
	if typeof(value.quest) ~= "number" or value.quest%1~=0 or value.quest<1 or value.quest>6 then return nil end
	if typeof(value.coins)~="number" or value.coins%1~=0 or value.coins<0 or value.coins>10000000 then return nil end
	if value.classId~=nil and (typeof(value.classId)~="string" or not allowedClasses[value.classId]) then return nil end
	if typeof(value.runes)~="table" or typeof(value.rewards)~="table" then return nil end
	if value.seals~=nil and (typeof(value.seals)~="number" or value.seals%1~=0 or value.seals<0 or value.seals>3) then return nil end
	local p=ProfileStore.fresh()
	p.quest=value.quest p.coins=value.coins p.classId=value.classId
	p.fragment=value.fragment==true
	p.bossDefeated=value.bossDefeated==true
	p.seals=value.seals or 0
	if typeof(value.heroes)=="table" then for _, id in unlockable do p.heroes[id]=value.heroes[id]==true end end
	for _, id in {"Dawn","Root","Star"} do p.runes[id]=value.runes[id]==true end
	for i=1,5 do p.rewards[tostring(i)]=value.rewards[tostring(i)]==true end
	local checkpoints={Village=true,Forest=true,Temple=true,Arena=true}
	p.checkpoint=if typeof(value.checkpoint)=="string" and checkpoints[value.checkpoint] then value.checkpoint else "Village"
	return p
end

function ProfileStore.new(adapter: any, token: string, clock: () -> number)
	return setmetatable({adapter=adapter,token=token,clock=clock,leaseSeconds=180},ProfileStore)
end

function ProfileStore:load(key: string)
	local reason="BUSY"
	local record=self.adapter:UpdateAsync(key,function(old: any)
		if old~=nil and (typeof(old)~="table" or typeof(old.profile)~="table") then reason="CORRUPT" return nil end
		local profile=if old==nil then ProfileStore.fresh() else ProfileStore.sanitize(old.profile)
		if not profile then reason="CORRUPT" return nil end
		local lease=old and old.lease
		if lease and (typeof(lease)~="table" or typeof(lease.expires)~="number") then reason="CORRUPT" return nil end
		if lease and lease.token~=self.token and lease.expires>self.clock() then reason="BUSY" return nil end
		return {profile=profile,lease={token=self.token,expires=self.clock()+self.leaseSeconds}}
	end)
	if not record or not record.lease or record.lease.token~=self.token then return nil,reason end
	return ProfileStore.sanitize(record.profile),nil
end

function ProfileStore:save(key: string, profile: any, release: boolean)
	local clean=ProfileStore.sanitize(profile)
	if not clean then return false,"INVALID_PROFILE" end
	local record=self.adapter:UpdateAsync(key,function(old: any)
		if typeof(old)~="table" or typeof(old.lease)~="table" or old.lease.token~=self.token then return nil end
		return {profile=clean,lease=if release then nil else {token=self.token,expires=self.clock()+self.leaseSeconds}}
	end)
	if not record then return false,"LOST_LEASE" end
	return true,nil
end

return ProfileStore
