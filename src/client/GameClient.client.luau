--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Classes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Classes"))
local remoteFolder = ReplicatedStorage:WaitForChild("GameRemotes")
local chooseClass = remoteFolder:WaitForChild("ChooseClass") :: RemoteEvent
local attackEnemy = remoteFolder:WaitForChild("AttackEnemy") :: RemoteEvent

local oldScreen = playerGui:FindFirstChild("PortalPerdidoHUD")
if oldScreen then
	oldScreen:Destroy()
end

local screen = Instance.new("ScreenGui")
screen.Name = "PortalPerdidoHUD"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.Parent = playerGui

local function makeCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local card = Instance.new("Frame")
card.Name = "ClassSelection"
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.53)
card.Size = UDim2.fromScale(0.90, 0.64)
card.BackgroundColor3 = Color3.fromRGB(23, 35, 55)
card.BorderSizePixel = 0
card.Parent = screen
makeCorner(card, 14)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(420, 350)
sizeConstraint.MinSize = Vector2.new(250, 280)
sizeConstraint.Parent = card

local stack = Instance.new("UIListLayout")
stack.SortOrder = Enum.SortOrder.LayoutOrder
stack.HorizontalAlignment = Enum.HorizontalAlignment.Center
stack.VerticalAlignment = Enum.VerticalAlignment.Center
stack.Padding = UDim.new(0, 10)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(67, 171, 178)
panelStroke.Thickness = 2
panelStroke.Transparency = 0.45
panelStroke.Parent = card

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingTop = UDim.new(0, 14)
panelPadding.PaddingBottom = UDim.new(0, 14)
panelPadding.PaddingLeft = UDim.new(0, 10)
panelPadding.PaddingRight = UDim.new(0, 10)
panelPadding.Parent = card

local function updatePanelPosition()
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
	if viewport and viewport.X >= 760 then
		-- Deixa o menu de classes fora da área ocupada pelo chat nativo aberto.
		card.Position = UDim2.fromScale(0.68, 0.52)
	else
		card.Position = UDim2.fromScale(0.5, 0.53)
	end
end

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePanelPosition)
end
updatePanelPosition()
stack.Parent = card

local function textLine(content: string, height: number, size: number, order: number): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.LayoutOrder = order
	label.Size = UDim2.new(0.92, 0, 0, height)
	label.Text = content
	label.Font = Enum.Font.GothamBold
	label.TextSize = size
	label.TextColor3 = Color3.fromRGB(236, 242, 255)
	label.TextWrapped = true
	label.Parent = card
	return label
end

textLine("AS CRÔNICAS DO PORTAL PERDIDO", 44, 17, 1)
textLine("Você despertou em Aetherion. Escolha sua classe.", 38, 13, 2)

for order, classId in { "Guardian", "Explorer", "Artificer" } do
	local definition = Classes[classId]
	local button = Instance.new("TextButton")
	button.Name = "Choose" .. classId
	button.LayoutOrder = order + 2
	button.Size = UDim2.new(0.92, 0, 0, 52)
	button.BackgroundColor3 = Color3.fromRGB(30, 117, 127)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextWrapped = true
	button.TextSize = 13
	button.Font = Enum.Font.GothamSemibold
	button.Text = definition.displayName .. " — " .. definition.description
	button.Parent = card
	makeCorner(button, 8)
	button.Activated:Connect(function()
		chooseClass:FireServer(classId)
	end)
end

local questPanel = Instance.new("Frame")
questPanel.Name = "QuestPanel"
questPanel.AnchorPoint = Vector2.new(0.5, 0)
questPanel.Position = UDim2.fromScale(0.5, 0.025)
questPanel.Size = UDim2.new(0.86, 0, 0, 96)
questPanel.BackgroundColor3 = Color3.fromRGB(20, 39, 55)
questPanel.BackgroundTransparency = 0.12
questPanel.Visible = false
questPanel.Parent = screen
makeCorner(questPanel, 12)

local maxPanel = Instance.new("UISizeConstraint")
maxPanel.MaxSize = Vector2.new(510, 96)
maxPanel.Parent = questPanel

local function updateQuestPanelPosition()
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
	if viewport and viewport.X >= 760 then
		questPanel.Position = UDim2.fromScale(0.68, 0.025)
		questPanel.Size = UDim2.new(0.74, 0, 0, 96)
	else
		questPanel.Position = UDim2.fromScale(0.5, 0.025)
		questPanel.Size = UDim2.new(0.92, 0, 0, 96)
	end
end

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateQuestPanelPosition)
end
updateQuestPanelPosition()

local objectiveLabel = Instance.new("TextLabel")
objectiveLabel.Name = "Objective"
objectiveLabel.Position = UDim2.new(0.04, 0, 0, 7)
objectiveLabel.Size = UDim2.new(0.92, 0, 0, 48)
objectiveLabel.BackgroundTransparency = 1
objectiveLabel.TextColor3 = Color3.fromRGB(245, 249, 255)
objectiveLabel.Font = Enum.Font.GothamSemibold
objectiveLabel.TextSize = 14
objectiveLabel.TextWrapped = true
objectiveLabel.Parent = questPanel

local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "Message"
messageLabel.Position = UDim2.new(0.04, 0, 0, 55)
messageLabel.Size = UDim2.new(0.92, 0, 0, 34)
messageLabel.BackgroundTransparency = 1
messageLabel.TextColor3 = Color3.fromRGB(147, 233, 225)
messageLabel.Font = Enum.Font.Gotham
messageLabel.TextSize = 12
messageLabel.TextWrapped = true
messageLabel.Parent = questPanel

local attackButton = Instance.new("TextButton")
attackButton.Name = "AttackButton"
attackButton.AnchorPoint = Vector2.new(1, 1)
attackButton.Position = UDim2.fromScale(0.96, 0.92)
attackButton.Size = UDim2.fromOffset(154, 66)
attackButton.BackgroundColor3 = Color3.fromRGB(195, 91, 67)
attackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
attackButton.Font = Enum.Font.GothamBold
attackButton.TextSize = 20
attackButton.Text = "ATACAR  [Q]"
attackButton.Visible = false
attackButton.Parent = screen
makeCorner(attackButton, 16)

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "Coins"
coinsLabel.AnchorPoint = Vector2.new(0, 1)
coinsLabel.Position = UDim2.fromScale(0.04, 0.92)
coinsLabel.Size = UDim2.fromOffset(160, 45)
coinsLabel.BackgroundColor3 = Color3.fromRGB(20, 39, 55)
coinsLabel.TextColor3 = Color3.fromRGB(251, 227, 140)
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextSize = 16
coinsLabel.Parent = screen
makeCorner(coinsLabel, 11)

local function refreshHud()
	local classId = player:GetAttribute("ClassId")
	local selected = typeof(classId) == "string" and Classes[classId] ~= nil
	card.Visible = not selected
	questPanel.Visible = selected
	attackButton.Visible = selected
	coinsLabel.Visible = selected

	local questState = player:GetAttribute("QuestState")
	if questState == "ACTIVE" then
		objectiveLabel.Text = "MISSÃO: A PRIMEIRA AMEAÇA — Derrote 1 Sentinela de Musgo"
	elseif questState == "READY" then
		objectiveLabel.Text = "MISSÃO: Volte para Ilyra e receba a recompensa"
	elseif questState == "COMPLETED" then
		objectiveLabel.Text = "MISSÃO CONCLUÍDA — Primeiro desafio vencido!"
	else
		objectiveLabel.Text = "EXPLORAÇÃO: Fale com Ilyra perto do ponto inicial"
	end

	local message = player:GetAttribute("QuestMessage")
	messageLabel.Text = if typeof(message) == "string" then message else "Use Q ou ATACAR para lutar."
	local coins = player:GetAttribute("Coins")
	coinsLabel.Text = "✦ Moedas: " .. tostring(if typeof(coins) == "number" then coins else 0)
end

for _, attribute in { "ClassId", "QuestState", "QuestProgress", "QuestMessage", "Coins" } do
	player:GetAttributeChangedSignal(attribute):Connect(refreshHud)
end

local function attack()
	if player:GetAttribute("ClassId") ~= nil then
		attackEnemy:FireServer()
	end
end
attackButton.Activated:Connect(attack)

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q then
		attack()
	end
end)


-- Diagnóstico somente no Studio: identifica se o teclado chega ao cliente,
-- se a interface/chat consome os eventos e se o Humanoid pode caminhar.
-- Não altera os controles Roblox nem executa no jogo publicado.
if RunService:IsStudio() then
	local movementKeys = {
		[Enum.KeyCode.W] = true,
		[Enum.KeyCode.A] = true,
		[Enum.KeyCode.S] = true,
		[Enum.KeyCode.D] = true,
		[Enum.KeyCode.Space] = true,
	}

	local function describeCharacter(): string
		local character = player.Character
		if not character then
			return "Character=ausente"
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		if not humanoid then
			return "Humanoid=ausente"
		end
		local rootAnchored = if root and root:IsA("BasePart") then tostring(root.Anchored) else "sem root"
		local position = if root and root:IsA("BasePart") then tostring(root.Position) else "sem root"
		return string.format(
			"WalkSpeed=%.1f JumpPower=%.1f JumpHeight=%.1f PlatformStand=%s Sit=%s RootAnchored=%s Position=%s",
			humanoid.WalkSpeed,
			humanoid.JumpPower,
			humanoid.JumpHeight,
			tostring(humanoid.PlatformStand),
			tostring(humanoid.Sit),
			rootAnchored,
			position
		)
	end

	local function inspectSpawn()
		task.delay(2, function()
			print("[PortalPerdido][MovementDebug] Spawn:", describeCharacter())
		end)
	end
	player.CharacterAdded:Connect(inspectSpawn)
	if player.Character then
		inspectSpawn()
	end

	local inputLogs = 0
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if not movementKeys[input.KeyCode] or inputLogs >= 12 then
			return
		end
		inputLogs += 1
		local focused = UserInputService:GetFocusedTextBox()
		warn(
			"[PortalPerdido][MovementDebug]",
			"Key=" .. input.KeyCode.Name,
			"Processed=" .. tostring(processed),
			"FocusedTextBox=" .. (if focused then focused:GetFullName() else "none"),
			describeCharacter()
		)
	end)
end

refreshHud()
