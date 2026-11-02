--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")

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
card.Size = UDim2.fromOffset(420, 350)
card.BackgroundColor3 = Color3.fromRGB(23, 35, 55)
card.BorderSizePixel = 0
card.Parent = screen
makeCorner(card, 14)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(420, 350)
sizeConstraint.MinSize = Vector2.new(250, 280)

local cardScale = Instance.new("UIScale")
cardScale.Parent = card
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
questPanel.Size = UDim2.new(0.86, 0, 0, 122)
questPanel.BackgroundColor3 = Color3.fromRGB(20, 39, 55)
questPanel.BackgroundTransparency = 0
questPanel.Visible = false
questPanel.Parent = screen
makeCorner(questPanel, 12)

local maxPanel = Instance.new("UISizeConstraint")
maxPanel.MaxSize = Vector2.new(510, 122)
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
coinsLabel.AnchorPoint = Vector2.new(0, 0)
coinsLabel.Position = UDim2.new(0.04, 0, 0, 88)
coinsLabel.Size = UDim2.new(0.43, 0, 0, 25)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
coinsLabel.BackgroundColor3 = Color3.fromRGB(20, 39, 55)
coinsLabel.TextColor3 = Color3.fromRGB(251, 227, 140)
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextSize = 16
coinsLabel.Parent = questPanel
local controlsLabel = Instance.new("TextLabel")
controlsLabel.Name = "ControlsHint"
controlsLabel.Position = UDim2.new(0.49, 0, 0, 88)
controlsLabel.Size = UDim2.new(0.47, 0, 0, 25)
controlsLabel.BackgroundTransparency = 1
controlsLabel.TextColor3 = Color3.fromRGB(194, 214, 228)
controlsLabel.Font = Enum.Font.Gotham
controlsLabel.TextSize = 11
controlsLabel.TextWrapped = true
controlsLabel.Parent = questPanel

-- Brilho discreto do portal no desktop; desligado na entrada touch.
-- O perfil mobile mantém apenas atmosfera e correção de cor, sem desfoque.
local bloom = Instance.new("BloomEffect")
bloom.Name = "PortalPerdidoBloom"
bloom.Intensity = 0.14
bloom.Size = 18
bloom.Threshold = 1.7
bloom.Parent = Lighting

local function updateLayout()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize
	local available = screen.AbsoluteSize
	local touch = UserInputService.PreferredInput == Enum.PreferredInput.Touch
	bloom.Enabled = not touch
	cardScale.Scale = math.min(1, (available.X - 24) / 420, (available.Y - 24) / 350)
	card.Position = UDim2.fromScale(if viewport.X >= 1000 then 0.68 else 0.5, 0.5)
	questPanel.Position = UDim2.fromScale(if viewport.X >= 1000 then 0.68 else 0.5, 0.025)
	questPanel.Size = UDim2.new(0.92, 0, 0, 122)
	-- Preserve the native thumbstick and jump button areas on phones.
	attackButton.Position = if touch then UDim2.new(1, -20, 1, -130) else UDim2.new(1, -24, 1, -24)
	attackButton.Size = if touch then UDim2.fromOffset(120, 56) else UDim2.fromOffset(154, 66)
	attackButton.TextSize = if touch then 18 else 20
	attackButton.Text = if touch then "ATACAR" else "ATACAR  [Q]"
	controlsLabel.Text = if touch then "Arraste para mover" else "Clique no cenário · WASD / Espaço"
end

local viewportConnection: RBXScriptConnection? = nil
local function bindCamera()
	if viewportConnection then viewportConnection:Disconnect() end
	local camera = workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayout)
	end
	updateLayout()
end
screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(updateLayout)
bindCamera()

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
	coinsLabel.Text = "Moedas: " .. tostring(if typeof(coins) == "number" then coins else 0)
end

for _, attribute in { "ClassId", "QuestState", "QuestProgress", "QuestMessage", "Coins" } do
	player:GetAttributeChangedSignal(attribute):Connect(refreshHud)
end

local lastAttack = -math.huge
local function attack()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if player:GetAttribute("ClassId") == nil or not humanoid or humanoid.Health <= 0 then return end
	if os.clock() - lastAttack < 0.65 then return end
	lastAttack = os.clock()
	attackEnemy:FireServer()
	attackButton.BackgroundColor3 = Color3.fromRGB(117, 71, 65)
	task.delay(0.65, function()
		attackButton.BackgroundColor3 = Color3.fromRGB(195, 91, 67)
	end)
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
			"WalkSpeed=%.1f JumpPower=%.1f JumpHeight=%.1f PlatformStand=%s Sit=%s RootAnchored=%s Position=%s State=%s MoveDirection=%s",
			humanoid.WalkSpeed,
			humanoid.JumpPower,
			humanoid.JumpHeight,
			tostring(humanoid.PlatformStand),
			tostring(humanoid.Sit),
			rootAnchored,
			position,
			humanoid:GetState().Name,
			tostring(humanoid.MoveDirection)
		)
	end

	local function inspectSpawn()
		task.delay(2, function()
			local modernModule = game:GetService("StarterPlayer"):FindFirstChild("PlayerModule")
			local legacyModule = player:WaitForChild("PlayerScripts"):FindFirstChild("PlayerModule")
			print("[PortalPerdido][MovementDebug] Spawn:", describeCharacter(), "PlayerModule=" .. (if modernModule then modernModule:GetFullName() elseif legacyModule then legacyModule:GetFullName() else "absent"))
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
			"MenuOpen=" .. tostring(GuiService.MenuIsOpen),
			describeCharacter()
		)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local before = root.Position
			task.delay(0.35, function()
				if root.Parent and player.Character == character then
					print("[PortalPerdido][MovementDebug] AfterInput Key=" .. input.KeyCode.Name, "Delta=" .. tostring(root.Position - before), describeCharacter())
				end
			end)
		end
	end)
end

refreshHud()
