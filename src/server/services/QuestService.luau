--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Chapter=require(ReplicatedStorage.Shared.Config.Chapter)
local Data=require(script.Parent.PlayerDataService)
local Quest={}
local notify: RemoteEvent
local guardAlive: (string) -> boolean = function() return true end
local lastAction: {[Player]: number}={}
local lastRest: {[Player]: number}={}

local function aliveNear(player: Player, target: Vector3, distance: number): boolean
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	return root~=nil and root:IsA("BasePart") and humanoid~=nil and humanoid.Health>0 and (root.Position-target).Magnitude<=distance
end

local function message(player: Player,text: string)
	player:SetAttribute("QuestMessage",text)
	notify:FireClient(player,{kind="toast",text=text})
end

local function dialogue(player: Player, lines: {string}, speaker: string?)
	if not speaker or speaker=="ILYRA" then
		local world=workspace:FindFirstChild("PortalChapter")
		local village=world and world:FindFirstChild("Village")
		local npc=village and village:FindFirstChild("Ilyra")
		if npc then npc:SetAttribute("TalkingUntil",workspace:GetServerTimeNow()+8) end
	end
	notify:FireClient(player,{kind="dialogue",speaker=speaker or "ILYRA",lines=lines})
end

local function advance(player: Player, expected: number, checkpoint: string?)
	local p=Data.get(player)
	if not p or p.quest~=expected then return end
	Data.award(player,expected,Chapter.Quests[expected].reward)
	Data.mutate(player,function(profile)
		profile.quest=expected+1
		if checkpoint then profile.checkpoint=checkpoint end
	end)
	notify:FireClient(player,{kind="quest",text=Chapter.Quests[expected].title.." — concluída",coins=Chapter.Quests[expected].reward})
	task.spawn(Data.save,player,false)
end

local function prompt(parent: BasePart, action: string, object: string, callback: (Player) -> ())
	local p=Instance.new("ProximityPrompt")
	p.Name="Interact"
	p.ActionText=action p.ObjectText=object p.HoldDuration=0.2
	p.MaxActivationDistance=12 p.RequiresLineOfSight=false
	p.Parent=parent
	p.Triggered:Connect(function(player)
		local now=os.clock()
		if now-(lastAction[player] or -math.huge)<0.35 then return end
		lastAction[player]=now
		if Data.get(player) and aliveNear(player,parent.Position,16) then callback(player) end
	end)
end

function Quest.register(player: Player)
	local p=Data.get(player)
	if not p then return end
	message(player,if p.quest>5 then "O Fragmento da Aurora está seguro. O mistério do Portal Primordial continua." else Chapter.Quests[p.quest].objective)
end

function Quest.recordDefeat(player: Player, encounter: string)
	local p=Data.get(player)
	if not p or not p.classId then return end
	if encounter=="FirstSentinel" and p.quest==2 then
		advance(player,2,"Forest")
		message(player,"Caminho livre! Encontre as três inscrições na floresta.")
	elseif encounter=="RootGuardian" and p.quest==5 then
		Data.mutate(player,function(profile) profile.bossDefeated=true end)
		task.spawn(Data.save,player,false)
		message(player,"O Guardião repousa. Recolha o Fragmento da Aurora no altar.")
	end
end

function Quest.init(notifyRemote: RemoteEvent, isGuardAlive: (string) -> boolean)
	notify=notifyRemote guardAlive=isGuardAlive
	local world=workspace:WaitForChild("PortalChapter")
	local ilyra=world.Village.Ilyra.PrimaryPart
	assert(ilyra)
	prompt(ilyra,"Conversar","Ilyra, Guardiã do Vale",function(player)
		local p=Data.get(player)
		if not p.classId then message(player,"Escolha sua classe para iniciar a travessia.") return end
		if p.quest==1 then
			dialogue(player,Chapter.Dialogues.IlyraFirst)
			advance(player,1)
			message(player,Chapter.Quests[2].objective)
		elseif p.quest==2 then dialogue(player,{"O Sentinela está além do arco antigo. Use seu ataque e sua habilidade de classe. Desvie das marcas no chão."})
		elseif p.quest==3 then dialogue(player,Chapter.Dialogues.Runes)
		elseif p.quest==4 then dialogue(player,{"A ordem no templo é Aurora, Raiz, Estrela. As inscrições não podem ser esquecidas."})
		elseif p.quest==5 then dialogue(player,Chapter.Dialogues.Temple)
		else dialogue(player,Chapter.Dialogues.Ending) end
	end)
	for _, id in {"Forest","Temple"} do
		local core=world.RestShrines[id].Core
		prompt(core,"Descansar","Fonte de Lúmen",function(player)
			local p=Data.get(player)
			local minimum=if id=="Forest" then 3 else 4
			if p.quest<minimum then message(player,"Conclua a etapa anterior para despertar esta fonte.") return end
			if os.clock()-(lastRest[player] or -math.huge)<25 then message(player,"A fonte está se recuperando. Aguarde um instante.") return end
			lastRest[player]=os.clock()
			local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if h then h.Health=h.MaxHealth end
			Data.mutate(player,function(profile) profile.checkpoint=id end)
			message(player,"Vida restaurada. Este é seu novo ponto de retorno.")
		end)
	end
	for _, definition in Chapter.Runes do
		local core=world.Runes[definition.id].Core
		prompt(core,"Ler inscrição",definition.name,function(player)
			local p=Data.get(player)
			if p.quest<3 then message(player,"Primeiro libere o caminho com a missão de Ilyra.") return end
			if p.quest>3 or p.runes[definition.id] then message(player,"Esta inscrição já está no seu diário.") return end
			if guardAlive(definition.guard) then message(player,"Uma criatura protege a inscrição. Derrote-a primeiro.") return end
			Data.mutate(player,function(profile) profile.runes[definition.id]=true end)
			dialogue(player,{definition.name..": a pedra responde à sua presença.","Aurora desperta. A raiz sustenta. A estrela revela o caminho."},"MEMÓRIA DA FLORESTA")
			if p.runes.Dawn and p.runes.Root and p.runes.Star then
				advance(player,3,"Temple") message(player,Chapter.Quests[4].objective)
			else message(player,"Inscrição registrada. Continue pelas trilhas laterais da floresta.") end
		end)
	end
	for index,id in Chapter.SealOrder do
		local core=world.Temple.Seals[id].Core
		prompt(core,"Ativar selo",if id=="Dawn" then "Aurora" elseif id=="Root" then "Raiz" else "Estrela",function(player)
			local p=Data.get(player)
			if p.quest~=4 then message(player,if p.quest<4 then "Reúna as três inscrições antes de tocar os selos." else "O templo já reconhece você.") return end
			if index~=p.seals+1 then
				Data.mutate(player,function(profile) profile.seals=0 end)
				message(player,"A sequência se desfez. Tente: Aurora, Raiz, Estrela.") return
			end
			Data.mutate(player,function(profile) profile.seals=index end)
			notify:FireClient(player,{kind="seal",position=core.Position,color=core.Color})
			if index==3 then
				advance(player,4,"Temple") dialogue(player,Chapter.Dialogues.Temple,"O SANTUÁRIO")
				message(player,"Atravesse o limiar e enfrente o Guardião de Raízes.")
			else message(player,"Selo "..index.." de 3 ativado.") end
		end)
	end
	prompt(world.Temple.ArenaGate,"Atravessar","Limiar do Santuário",function(player)
		local p=Data.get(player)
		if p.quest<5 then message(player,"O limiar permanece fechado. Complete os três selos.") return end
		Data.mutate(player,function(profile) profile.checkpoint="Arena" end)
		if player.Character then player.Character:PivotTo(CFrame.new(Chapter.Checkpoints.Arena)) end
	end)
	prompt(world.Arena.AuroraFragment,"Recolher fragmento","Fragmento da Aurora",function(player)
		local p=Data.get(player)
		if p.quest>5 then message(player,"O Fragmento da Aurora já está no seu inventário.") return end
		if p.quest~=5 or player:GetAttribute("BossDefeated")~=true then message(player,"O Guardião ainda protege o fragmento.") return end
		Data.mutate(player,function(profile) profile.fragment=true end)
		advance(player,5,"Village")
		message(player,"O Fragmento da Aurora está seguro. Volte ao vale quando desejar.")
		dialogue(player,Chapter.Dialogues.Ending,"FRAGMENTO DA AURORA")
		notify:FireClient(player,{kind="ending"})
	end)
	prompt(world.Arena.ReturnStone,"Retornar","Vale de Lúmen",function(player)
		if player.Character then player.Character:PivotTo(CFrame.new(Chapter.Checkpoints.Village)) end
	end)
	Players.PlayerRemoving:Connect(function(player) lastAction[player]=nil lastRest[player]=nil end)
end

return Quest
