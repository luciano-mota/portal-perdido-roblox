--!strict
-- Vertical slice: inimigo único com perseguição simples e combate autoritativo.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local EnemyService = {}
local ORIGIN = Vector3.new(0, 2, -22)
local MAX_HEALTH = 100
local ATTACK_RANGE = 18
local AGGRO_RANGE = 30
local ENEMY_HIT_RANGE = 7
local LEASH_RANGE = 24
local ENEMY_SPEED = 6
local ENEMY_DAMAGE = 7
local RESPAWN_SECONDS = 7
local HIT_COOLDOWN = 0.65
local DAMAGE_BY_CLASS: { [string]: number } = {
	Guardian = 33,
	Explorer = 40,
	Artificer = 30,
}

local sentinel: Part? = nil
local lastPlayerAttack: { [Player]: number } = {}
local lastEnemyAttack = 0
local running = false

local function makeSentinel(): Part
	local enemy = Instance.new("Part")
	enemy.Name = "SentinelaDeMusgo"
	enemy.Shape = Enum.PartType.Ball
	enemy.Size = Vector3.new(6, 6, 6)
	enemy.Position = ORIGIN
	enemy.Color = Color3.fromRGB(46, 122, 75)
	enemy.Material = Enum.Material.Grass
	enemy.Anchored = true
	enemy.CanCollide = false
	enemy:SetAttribute("Health", MAX_HEALTH)
	enemy:SetAttribute("MaxHealth", MAX_HEALTH)
	enemy.Parent = Workspace:WaitForChild("PortalEnemies")

	local gui = Instance.new("BillboardGui")
	gui.Name = "EnemyStatus"
	gui.Size = UDim2.fromOffset(210, 46)
	gui.StudsOffset = Vector3.new(0, 4.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = enemy

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(240, 255, 221)
	label.TextStrokeTransparency = 0.25
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	local function refresh()
		local hp = enemy:GetAttribute("Health")
		label.Text = "Sentinela de Musgo\nHP: " .. tostring(hp) .. "/" .. tostring(MAX_HEALTH)
	end
	enemy:GetAttributeChangedSignal("Health"):Connect(refresh)
	refresh()

	return enemy
end

local function validPlayerRoot(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end
	return root, humanoid
end

function EnemyService.init(attackRemote: RemoteEvent, questService: any)
	if running then
		return
	end
	running = true
	local folder = Workspace:FindFirstChild("PortalEnemies")
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "PortalEnemies"
		folder.Parent = Workspace
	end
	sentinel = makeSentinel()

	attackRemote.OnServerEvent:Connect(function(player: Player)
		if player.Parent ~= Players then
			return
		end
		local classId = player:GetAttribute("ClassId")
		if typeof(classId) ~= "string" then
			return
		end
		local damage = DAMAGE_BY_CLASS[classId]
		if damage == nil then
			return
		end

		local root = validPlayerRoot(player)
		local currentEnemy = sentinel
		if root == nil or currentEnemy == nil or currentEnemy.Parent == nil then
			return
		end
		local hp = currentEnemy:GetAttribute("Health")
		if typeof(hp) ~= "number" or hp <= 0 then
			return
		end
		if (root.Position - currentEnemy.Position).Magnitude > ATTACK_RANGE then
			return
		end

		local now = os.clock()
		local previous = lastPlayerAttack[player]
		if previous ~= nil and now - previous < HIT_COOLDOWN then
			return
		end
		lastPlayerAttack[player] = now

		local remaining = math.max(0, hp - damage)
		currentEnemy:SetAttribute("Health", remaining)

		if remaining == 0 then
			questService.recordSentinelDefeat(player)
			currentEnemy.Transparency = 0.7
			task.delay(RESPAWN_SECONDS, function()
				if sentinel == currentEnemy then
					currentEnemy:Destroy()
					sentinel = makeSentinel()
				end
			end)
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		lastPlayerAttack[player] = nil
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < 0.12 then
			return
		end
		local step = elapsed
		elapsed = 0

		local enemy = sentinel
		if not enemy or enemy.Parent == nil then
			return
		end
		local hp = enemy:GetAttribute("Health")
		if typeof(hp) ~= "number" or hp <= 0 then
			return
		end

		local nearestPlayer: Player? = nil
		local nearestHumanoid: Humanoid? = nil
		local nearestRoot: BasePart? = nil
		local nearestDistance = AGGRO_RANGE
		for _, player in Players:GetPlayers() do
			local root, humanoid = validPlayerRoot(player)
			if root and humanoid and player:GetAttribute("ClassId") ~= nil and (root.Position - ORIGIN).Magnitude <= LEASH_RANGE then
				local distance = (root.Position - enemy.Position).Magnitude
				if distance < nearestDistance then
					nearestPlayer = player
					nearestHumanoid = humanoid
					nearestRoot = root
					nearestDistance = distance
				end
			end
		end

		if not nearestPlayer then
			local home = ORIGIN - enemy.Position
			if home.Magnitude > 0.1 then
				enemy.Position += home.Unit * math.min(ENEMY_SPEED * step, home.Magnitude)
			end
		end

		if nearestPlayer and nearestRoot and nearestHumanoid then
			if nearestDistance > ENEMY_HIT_RANGE then
				local displacement = Vector3.new(nearestRoot.Position.X - enemy.Position.X, 0, nearestRoot.Position.Z - enemy.Position.Z)
				if displacement.Magnitude > 0.1 then
					local movement = displacement.Unit * math.min(ENEMY_SPEED * step, displacement.Magnitude)
					enemy.Position += movement
				end
			elseif os.clock() - lastEnemyAttack > 2 then
				lastEnemyAttack = os.clock()
				nearestHumanoid:TakeDamage(ENEMY_DAMAGE)
			end
		end
	end)
end

return EnemyService
