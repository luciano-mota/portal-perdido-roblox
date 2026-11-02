--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Classes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Classes"))
local chooseClass = ReplicatedStorage:WaitForChild("GameRemotes"):WaitForChild("ChooseClass") :: RemoteEvent

local screen = Instance.new("ScreenGui")
screen.Name = "PortalPerdidoHUD"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.Parent = playerGui

local card = Instance.new("Frame")
card.Name = "ClassSelection"
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.5)
card.Size = UDim2.fromScale(0.78, 0.58)
card.BackgroundColor3 = Color3.fromRGB(23, 35, 55)
card.BorderSizePixel = 0
card.Parent = screen

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(440, 360)
sizeConstraint.MinSize = Vector2.new(240, 220)
sizeConstraint.Parent = card

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = card

local stack = Instance.new("UIListLayout")
stack.HorizontalAlignment = Enum.HorizontalAlignment.Center
stack.VerticalAlignment = Enum.VerticalAlignment.Center
stack.Padding = UDim.new(0, 8)
stack.Parent = card

local function textLine(content: string, height: number, font: Enum.Font, size: number): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.9, 0, 0, height)
	label.Text = content
	label.Font = font
	label.TextSize = size
	label.TextColor3 = Color3.fromRGB(236, 242, 255)
	label.TextWrapped = true
	label.Parent = card
	return label
end

textLine("AS CRÔNICAS DO PORTAL PERDIDO", 36, Enum.Font.GothamBold, 17)
textLine("Você despertou em Aetherion. Escolha sua classe.", 40, Enum.Font.Gotham, 13)

for _, classId in ipairs({ "Guardian", "Explorer", "Artificer" }) do
	local definition = Classes[classId]
	local button = Instance.new("TextButton")
	button.Name = "Choose" .. classId
	button.Size = UDim2.new(0.9, 0, 0, 48)
	button.BackgroundColor3 = Color3.fromRGB(30, 117, 127)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextWrapped = true
	button.TextSize = 14
	button.Font = Enum.Font.GothamSemibold
	button.Text = definition.displayName .. " — " .. definition.description
	button.Parent = card
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button
	button.Activated:Connect(function()
		chooseClass:FireServer(classId)
	end)
end

local notification = Instance.new("TextLabel")
notification.Name = "ClassStatus"
notification.AnchorPoint = Vector2.new(0.5, 0)
notification.Position = UDim2.fromScale(0.5, 0.025)
notification.Size = UDim2.fromScale(0.8, 0.065)
notification.BackgroundTransparency = 0.25
notification.BackgroundColor3 = Color3.fromRGB(23, 35, 55)
notification.TextColor3 = Color3.fromRGB(255, 255, 255)
notification.TextScaled = true
notification.Visible = false
notification.Parent = screen

local function updateClass()
	local current = player:GetAttribute("ClassId")
	if typeof(current) == "string" and Classes[current] then
		card.Visible = false
		notification.Visible = true
		notification.Text = "Classe selecionada: " .. Classes[current].displayName
	end
end

player:GetAttributeChangedSignal("ClassId"):Connect(updateClass)
updateClass()
