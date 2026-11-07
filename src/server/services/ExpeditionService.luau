--!strict
-- Expedição (docs/CAMPAIGN_SIX_PHASES.md e GAME_MODES_AND_MATCHMAKING.md), sem sala/lobby ainda:
-- todos no servidor formam a expedição. Ao primeiro herói escolhido abre-se uma janela de
-- reunião; quando ela termina (ou todos já escolheram e ninguém mais chega), a expedição começa
-- e a ROTA fica congelada pela quantidade de participantes:
--   1–3 → Rota A: todos no Vale, fase a fase; cada região abre só após vencer o chefão dela.
--   4–6 → Rota B: sorteio entre as quatro regiões iniciais, pelo menos um em cada uma;
--         morte elimina da expedição atual (sem apagar a conta); reencontro na fase 5.
-- O servidor decide seed e resultado. Quem chega depois do início não entra na expedição em
-- andamento (joga o Vale por conta própria) — a sala com início congelado é etapa do lobby.
local Players=game:GetService("Players")
local Data=require(script.Parent.PlayerDataService)
local Expedition={MinimumPlayers=1,RecommendedPlayers=6,GatherSeconds=20}

local started=false
local members: {[Player]: boolean}={}
local assignment: {[Player]: string}={}
local eliminated: {[Player]: boolean}={}
local resolved: {[string]: boolean}={}
local route="A"
local lastSignature: string?=nil
local gatherDeadline: number?=nil
local onBegin: {(route: string, assignment: {[Player]: string}) -> ()}={}

local BRANCHES={"Lumen","CrystalAbyss","HourDesert","EclipseCitadel"}

function Expedition.readyCount(): number
	local count=0
	for _,player in Players:GetPlayers() do
		local profile=Data.get(player)
		if profile and profile.classId then count+=1 end
	end
	return count
end

-- Tamanhos dos grupos por região (embaralhados depois). 6 alterna entre 3-1-1-1 e 2-2-1-1.
local function groupSizes(count: number, rng: Random): {number}
	if count==4 then return {1,1,1,1}
	elseif count==5 then return {2,1,1,1}
	elseif count>=6 then return if rng:NextNumber()<0.5 then {3,1,1,1} else {2,2,1,1} end
	return {count}
end

-- Sorteio da Rota B: pelo menos um por região; evita repetir a combinação exata anterior.
function Expedition.distribute(players: {Player}, seed: number): {[Player]: string}
	local best: {[Player]: string}={}
	for attempt=1,8 do
		local rng=Random.new(seed+attempt*7919)
		local order=table.clone(players)
		for i=#order,2,-1 do local j=rng:NextInteger(1,i) order[i],order[j]=order[j],order[i] end
		local regions=table.clone(BRANCHES)
		for i=#regions,2,-1 do local j=rng:NextInteger(1,i) regions[i],regions[j]=regions[j],regions[i] end
		local sizes=groupSizes(#order,rng)
		local result: {[Player]: string}={}
		local index=1
		for slot,size in sizes do
			for _=1,size do
				if order[index] then result[order[index]]=regions[slot] index+=1 end
			end
		end
		local parts={}
		for player,region in result do table.insert(parts,tostring(player.UserId)..":"..region) end
		table.sort(parts)
		local signature=table.concat(parts,",")
		best=result
		if signature~=lastSignature then lastSignature=signature break end
	end
	return best
end

function Expedition.hasStarted(): boolean return started end
function Expedition.route(): string return route end
function Expedition.isMember(player: Player): boolean return members[player]==true end
function Expedition.regionOf(player: Player): string? return assignment[player] end
function Expedition.isEliminated(player: Player): boolean return eliminated[player]==true end

-- Ramo regional resolvido: chefe vencido ou todos os participantes daquele ramo eliminados.
function Expedition.resolve(region: string)
	if resolved[region] then return end
	resolved[region]=true
	workspace:SetAttribute("Resolved_"..region,true)
end
function Expedition.isResolved(region: string): boolean return resolved[region]==true end

-- Rota B: o reencontro (fase 5) só começa quando os quatro ramos estiverem resolvidos.
function Expedition.branchesResolved(): boolean
	if route~="B" then return true end
	for _,region in BRANCHES do
		if not resolved[region] then
			local alive=false
			for player,assigned in assignment do
				if assigned==region and player.Parent==Players and not eliminated[player] then alive=true break end
			end
			if alive then return false end
		end
	end
	return true
end

function Expedition.eliminate(player: Player)
	if route~="B" or not members[player] or eliminated[player] then return end
	eliminated[player]=true
	player:SetAttribute("Eliminated",true)
	local region=assignment[player]
	if region and not Expedition.branchesResolvedFor(region) then
		-- Ramo sem sobreviventes conta como resolvido: não trava a reunião.
		Expedition.resolve(region)
	end
	local alive=0
	for member in members do if member.Parent==Players and not eliminated[member] then alive+=1 end end
	workspace:SetAttribute("ExpeditionAlive",alive)
	if alive==0 then workspace:SetAttribute("ExpeditionFailed",true) end
end

function Expedition.branchesResolvedFor(region: string): boolean
	for player,assigned in assignment do
		if assigned==region and player.Parent==Players and not eliminated[player] then return false end
	end
	return true
end

function Expedition.onBegin(callback: (route: string, assignment: {[Player]: string}) -> ())
	table.insert(onBegin,callback)
end

local function begin()
	if started then return end
	local players={}
	for _,player in Players:GetPlayers() do
		local profile=Data.get(player)
		if profile and profile.classId then table.insert(players,player) end
	end
	if #players<Expedition.MinimumPlayers then return end
	started=true
	route=if #players>=4 then "B" else "A"
	for _,player in players do members[player]=true player:SetAttribute("ExpeditionMember",true) end
	if route=="B" then
		assignment=Expedition.distribute(players,os.time())
	else
		for _,player in players do assignment[player]="Lumen" end
	end
	for player,region in assignment do player:SetAttribute("ExpeditionRegion",region) end
	workspace:SetAttribute("CampaignRoute",route)
	workspace:SetAttribute("ExpeditionStarted",true)
	workspace:SetAttribute("ExpeditionPlayers",#players)
	workspace:SetAttribute("ExpeditionAlive",#players)
	workspace:SetAttribute("ExpeditionGatherEndsAt",nil)
	for _,callback in onBegin do task.spawn(callback,route,assignment) end
end

-- Compatibilidade: força o início com quem já escolheu herói (QA e Ilyra).
function Expedition.tryBegin(): (boolean,number)
	local count=Expedition.readyCount()
	if not started and count>=Expedition.MinimumPlayers then begin() end
	workspace:SetAttribute("ExpeditionReadyPlayers",count)
	return started,count
end

function Expedition.init()
	workspace:SetAttribute("ExpeditionStarted",false)
	workspace:SetAttribute("ExpeditionMinimumPlayers",Expedition.MinimumPlayers)
	workspace:SetAttribute("ExpeditionRecommendedPlayers",Expedition.RecommendedPlayers)
	Players.PlayerRemoving:Connect(function(player)
		-- Desconexão não é morte; o ramo sem ninguém conectado não trava a reunião.
		local region=assignment[player]
		task.defer(function()
			if started and route=="B" and region and Expedition.branchesResolvedFor(region) then Expedition.resolve(region) end
		end)
	end)
	task.spawn(function()
		while true do
			local count=Expedition.readyCount()
			workspace:SetAttribute("ExpeditionReadyPlayers",count)
			if not started and count>=Expedition.MinimumPlayers then
				local now=os.clock()
				local everyone=count==#Players:GetPlayers()
				if not gatherDeadline then
					gatherDeadline=now+Expedition.GatherSeconds
				end
				-- Seis prontos começam na hora; senão espera a janela de reunião.
				local remaining=(gatherDeadline :: number)-now
				workspace:SetAttribute("ExpeditionGatherEndsAt",workspace:GetServerTimeNow()+math.max(0,remaining))
				if count>=6 or (remaining<=0 and everyone) or remaining<=-10 then begin() end
			end
			task.wait(1)
		end
	end)
end

return Expedition
