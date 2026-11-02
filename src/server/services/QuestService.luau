--!strict
-- Primeira missão demonstrativa. Dados somente em memória até CPP-004.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local QuestService = {}
local REWARD_COINS = 25
local QUEST_STATE = {
	NotStarted = "NOT_STARTED",
	Active = "ACTIVE",
	Ready = "READY",
	Completed = "COMPLETED",
}

local function makePart(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Parent = parent
	return part
end

local function initializePlayer(player: Player)
	-- Não sobrescrever atributos ao recriar o avatar.
	if player:GetAttribute("QuestState") ~= nil then
		return
	end
	player:SetAttribute("QuestState", QUEST_STATE.NotStarted)
	player:SetAttribute("QuestProgress", 0)
	player:SetAttribute("QuestGoal", 1)
	player:SetAttribute("Coins", 0)
	player:SetAttribute("QuestMessage", "Escolha sua classe e converse com Ilyra perto da entrada.")
end

local function onTalk(player: Player, mentor: BasePart)
	initializePlayer(player)

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	if root == nil or not root:IsA("BasePart") or (root.Position - mentor.Position).Magnitude > 16 then
		return
	end
	if player:GetAttribute("ClassId") == nil then
		player:SetAttribute("QuestMessage", "Primeiro escolha uma classe na tela inicial.")
		return
	end

	local state = player:GetAttribute("QuestState")
	if state == QUEST_STATE.NotStarted then
		player:SetAttribute("QuestState", QUEST_STATE.Active)
		player:SetAttribute("QuestMessage", "Derrote um Sentinela de Musgo e retorne para Ilyra.")
	elseif state == QUEST_STATE.Active then
		player:SetAttribute("QuestMessage", "Use o botão ATACAR ou a tecla Q perto do Sentinela.")
	elseif state == QUEST_STATE.Ready then
		-- Sem yields entre verificar estado e conceder prêmio: evita duplicação no servidor.
		player:SetAttribute("QuestState", QUEST_STATE.Completed)
		local oldCoins = player:GetAttribute("Coins")
		local coins = if typeof(oldCoins) == "number" then oldCoins else 0
		player:SetAttribute("Coins", coins + REWARD_COINS)
		player:SetAttribute("QuestMessage", "Missão concluída! +25 moedas (sessão de teste).")
	else
		player:SetAttribute("QuestMessage", "Vale de Lúmen agradece sua ajuda. Mais missões em breve!")
	end
end

function QuestService.recordSentinelDefeat(player: Player)
	if player.Parent ~= Players then
		return
	end
	if player:GetAttribute("QuestState") ~= QUEST_STATE.Active then
		return
	end
	player:SetAttribute("QuestProgress", 1)
	player:SetAttribute("QuestState", QUEST_STATE.Ready)
	player:SetAttribute("QuestMessage", "Sentinela derrotado! Volte para Ilyra e receba sua recompensa.")
end

function QuestService.init()
	Players.PlayerAdded:Connect(initializePlayer)
	for _, player in Players:GetPlayers() do
		initializePlayer(player)
	end

	if Workspace:FindFirstChild("PortalQuestGuide") then
		return
	end

	local model = Instance.new("Model")
	model.Name = "PortalQuestGuide"
	model.Parent = Workspace

	local body = makePart(model, "Ilyra", Vector3.new(3, 5, 2), Vector3.new(10, 1.5, 12), Color3.fromRGB(76, 111, 164))
	makePart(model, "Cabeca", Vector3.new(2.7, 2.7, 2.7), Vector3.new(10, 5.3, 12), Color3.fromRGB(235, 193, 151))

	local gui = Instance.new("BillboardGui")
	gui.Name = "MentorName"
	gui.Size = UDim2.fromOffset(200, 58)
	gui.StudsOffset = Vector3.new(0, 5.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = body

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 248, 211)
	label.TextStrokeTransparency = 0.25
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = "ILYRA\nGuardiã do Vale"
	label.Parent = gui

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Conversar"
	prompt.ObjectText = "Ilyra, Guardiã do Vale"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	prompt.Triggered:Connect(function(player: Player)
		onTalk(player, body)
	end)
end

return QuestService
