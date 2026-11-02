--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

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
card.Position = UDim2.fromScale(0.5, 0.5)
card.Size = UDim2.fromScale(0.78, 0.58)
card.BackgroundColor3 = Color3.fromRGB(23, 35, 55)
card.BorderSizePixel = 0
card.Parent = screen
makeCorner(card, 14)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(440, 360)
sizeConstraint.MinSize = Vector2.new(240, 220)
sizeConstraint.Parent = card

local stack = Instance.new("UIListLayout")
stack.HorizontalAlignment = Enum.HorizontalAlignment.Center
stack.VerticalAlignment = Enum.VerticalAlignment.Center
stack.Padding = UDim.new(0, 8)
stack.Parent = card

local function textLine(content: string, height: number, size: number): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.92, 0, 0, height)
	label.Text = content
	label.Font = Enum.Font.GothamBold
	label.TextSize = size
	label.TextColor3 = Color3.fromRGB(236, 242, 255)
	label.TextWrapped = true
	label.Parent = card
	return label
end

textLine("AS CRÔNICAS DO PORTAL PERDIDO", 40, 18)
textLine("Você despertou em Aetherion. Escolha sua classe.", 35, 13)

for _, classId in { "Guardian", "Explorer", "Artificer" } do
	local definition = Classes[classId]
	local button = Instance.new("TextButton")
	button.Name = "Choose" .. classId
	button.Size = UDim2.new(0.92, 0, 0, 49)
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
maxPanel.MaxSize = Vector2.new(610, 96)
maxPanel.Parent = questPanel

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

refreshHud()
