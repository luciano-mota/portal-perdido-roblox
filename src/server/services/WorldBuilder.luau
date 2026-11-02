--!strict
-- Blockout temporário para Play Test. Substituir por mapa criado no Studio.
local Workspace = game:GetService("Workspace")

local WorldBuilder = {}

local function createPart(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	material: Enum.Material,
	color: Color3,
	shape: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Material = material
	part.Color = color
	if shape ~= nil then
		part.Shape = shape
	end
	part.Parent = parent
	return part
end

function WorldBuilder.build()
	if Workspace:FindFirstChild("PortalPerdidoBlockout") then
		return
	end

	-- O modelo Baseplate padrão cobre a ilha e tem um spawn concorrente.
	-- Remover apenas esses objetos padrões quando criamos nosso blockout.
	local templateBaseplate = Workspace:FindFirstChild("Baseplate")
	if templateBaseplate and templateBaseplate:IsA("BasePart") then
		templateBaseplate:Destroy()
	end
	local templateSpawn = Workspace:FindFirstChild("SpawnLocation")
	if templateSpawn and templateSpawn:IsA("SpawnLocation") then
		templateSpawn:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "PortalPerdidoBlockout"
	world.Parent = Workspace

	createPart(world, "IlhaDeLumen", Vector3.new(240, 8, 240), Vector3.new(0, -5, 0), Enum.Material.Grass, Color3.fromRGB(74, 139, 92))

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "EntradaDeLumen"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.5, 20)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Material = Enum.Material.Slate
	spawn.Color = Color3.fromRGB(115, 156, 182)
	spawn.Parent = world

	-- Caminho central deixa a entrada, a mentora e o portal visíveis sem árvores na câmera.
	local path = createPart(world, "CaminhoDeLumen", Vector3.new(9, 0.3, 69), Vector3.new(0, -0.8, -13), Enum.Material.Slate, Color3.fromRGB(143, 148, 154))
	path.CanCollide = true

	-- Anel do portal: pilares e travessa estilizados com partes simples.
	createPart(world, "PortalPilarEsquerdo", Vector3.new(5, 24, 5), Vector3.new(-10, 12, -38), Enum.Material.Slate, Color3.fromRGB(109, 116, 135))
	createPart(world, "PortalPilarDireito", Vector3.new(5, 24, 5), Vector3.new(10, 12, -38), Enum.Material.Slate, Color3.fromRGB(109, 116, 135))
	createPart(world, "PortalTravessa", Vector3.new(25, 5, 5), Vector3.new(0, 25, -38), Enum.Material.Slate, Color3.fromRGB(109, 116, 135))
	local rift = createPart(world, "FendaLuminosa", Vector3.new(15, 20, 1), Vector3.new(0, 12, -38), Enum.Material.Neon, Color3.fromRGB(58, 204, 218))
	rift.Transparency = 0.4
	rift.CanCollide = false

	for index = 1, 12 do
		local angle = (index / 12) * math.pi * 2
		local radius = 72 + (index % 3) * 12
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local height = 11 + (index % 3) * 3

		createPart(world, "ArvoreTronco" .. index, Vector3.new(4, height, 4), Vector3.new(x, height / 2, z), Enum.Material.Wood, Color3.fromRGB(98, 72, 53))
		createPart(world, "ArvoreCopa" .. index, Vector3.new(18, 16, 18), Vector3.new(x, height + 6, z), Enum.Material.Grass, Color3.fromRGB(55, 142, 105), Enum.PartType.Ball)
	end

	for index = 1, 6 do
		local x = (index - 3.5) * 11
		createPart(world, "Ruina" .. index, Vector3.new(5, 10 + (index % 2) * 5, 5), Vector3.new(x, 5, -78), Enum.Material.Slate, Color3.fromRGB(140, 141, 152))
	end
end

return WorldBuilder
