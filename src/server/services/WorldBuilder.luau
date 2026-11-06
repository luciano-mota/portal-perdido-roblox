--!strict
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Art = require(ReplicatedStorage.Shared.Art)
local Chapter = require(ReplicatedStorage.Shared.Config.Chapter)
local LumenScenery = require(script.Parent.LumenScenery)
local LumenRelief = require(script.Parent.LumenRelief)
local WorldBuilder = {}
local stone = Color3.fromRGB(126, 128, 137)
local darkStone = Color3.fromRGB(86, 94, 108)
local wood = Color3.fromRGB(102, 78, 57)
local cyan = Color3.fromRGB(76, 201, 205)
local amber = Color3.fromRGB(230, 185, 110)

local function lighting()
	Lighting.ClockTime = 16.8
	Lighting.GeographicLatitude = 35
	Lighting.Brightness = 2.2
	Lighting.ExposureCompensation = 0.18
	Lighting.Ambient = Color3.fromRGB(78,88,105)
	Lighting.OutdoorAmbient = Color3.fromRGB(115,130,145)
	Lighting.EnvironmentDiffuseScale = 0.65
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.ShadowSoftness = 0.4
	for _, v in Lighting:GetChildren() do
		if v:IsA("BloomEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("BlurEffect") then v.Enabled = false end
	end
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Name = "PortalPerdidoAtmosphere"
	atmosphere.Density = 0.24 atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(222,218,202)
	atmosphere.Decay = Color3.fromRGB(116,139,165)
	atmosphere.Haze = 1.1 atmosphere.Glare = 0.06
	atmosphere.Parent = Lighting
	local clouds=workspace.Terrain:FindFirstChild("LumenClouds")
	if not clouds then clouds=Instance.new("Clouds") clouds.Name="LumenClouds" clouds.Parent=workspace.Terrain end
	if clouds:IsA("Clouds") then clouds.Cover=0.38 clouds.Density=0.45 clouds.Color=Color3.fromRGB(255,239,216) end
	local color = Lighting:FindFirstChild("PortalPerdidoColor")
	if not color or not color:IsA("ColorCorrectionEffect") then color = Instance.new("ColorCorrectionEffect") end
	if color:IsA("ColorCorrectionEffect") then
		color.Name = "PortalPerdidoColor" color.Contrast = 0.08 color.Saturation = 0.03
		color.TintColor = Color3.fromRGB(255,247,235) color.Parent = Lighting
	end
end

local function folder(parent: Instance, name: string): Folder
	local f=Instance.new("Folder") f.Name=name f.Parent=parent return f
end

local function rock(parent: Instance, p: Vector3, size: Vector3, angle: number)
	Art.part(parent,"WeatheredStone",size,CFrame.new(p)*CFrame.Angles(0,angle,angle*0.12),stone,Enum.Material.Slate,Enum.PartType.Ball,true)
end

local function sign(parent: Instance, p: Vector3, title: string, subtitle: string)
	Art.segment(parent,"SignPost",p,p+Vector3.new(0,4,0),0.3,wood,Enum.Material.Wood,true)
	local board=Art.part(parent,"Wayfinder",Vector3.new(5,1.8,0.35),CFrame.new(p+Vector3.new(0,4,0)),wood,Enum.Material.Wood,nil,true)
	local gui=Instance.new("SurfaceGui") gui.Face=Enum.NormalId.Front gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud gui.PixelsPerStud=45 gui.Parent=board
	local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1 label.TextColor3=Color3.fromRGB(244,229,199) label.Font=Enum.Font.GothamSemibold label.TextSize=20 label.TextWrapped=true label.Text=title.."\n"..subtitle label.Parent=gui
end

local function house(parent: Instance, p: Vector3, flip: number)
	local m=Instance.new("Model") m.Name="CasaDeLumen" m.Parent=parent
	Art.part(m,"StoneBase",Vector3.new(13,1,12),CFrame.new(p+Vector3.new(0,0.4,0)),darkStone,Enum.Material.Cobblestone,nil,true)
	Art.part(m,"Plaster",Vector3.new(11,7,10),CFrame.new(p+Vector3.new(0,4,0)),Color3.fromRGB(183,171,144),Enum.Material.Plaster,nil,true)
	for _, x in {-5.5,5.5} do
		for _, z in {-5,5} do Art.part(m,"TimberFrame",Vector3.new(0.45,7.5,0.45),CFrame.new(p+Vector3.new(x,4,z)),wood,Enum.Material.Wood) end
		Art.part(m,"Roof",Vector3.new(7.5,0.5,13),CFrame.new(p+Vector3.new(x*0.55,8.8,0))*CFrame.Angles(0,0,if x>0 then -0.5 else 0.5),Color3.fromRGB(62,83,97),Enum.Material.Slate)
	end
	Art.part(m,"Door",Vector3.new(2.5,4.8,0.2),CFrame.new(p+Vector3.new(0,2.9,-5.12*flip)),wood,Enum.Material.WoodPlanks)
	for _, y in {1.1,6.9} do
		Art.part(m,"FacadeBeam",Vector3.new(11.4,0.28,0.35),CFrame.new(p+Vector3.new(0,y,-5.2*flip)),wood,Enum.Material.Wood)
	end
	for _, x in {-1.5,1.5} do
		Art.part(m,"DoorPost",Vector3.new(0.3,5.2,0.4),CFrame.new(p+Vector3.new(x,3,-5.25*flip)),wood,Enum.Material.Wood)
	end
	Art.part(m,"DoorLintel",Vector3.new(3.3,0.35,0.4),CFrame.new(p+Vector3.new(0,5.6,-5.25*flip)),wood,Enum.Material.Wood)
	Art.part(m,"DoorHandle",Vector3.new(0.12,0.36,0.15),CFrame.new(p+Vector3.new(0.8,2.9,-5.35*flip)),amber,Enum.Material.Metal)
	for _, x in {-3.5,3.5} do
		Art.part(m,"WindowFrame",Vector3.new(2.1,2.1,0.3),CFrame.new(p+Vector3.new(x,4.5,-5.15*flip)),wood,Enum.Material.Wood)
		Art.part(m,"AmberGlass",Vector3.new(1.65,1.65,0.1),CFrame.new(p+Vector3.new(x,4.5,-5.35*flip)),amber,Enum.Material.Neon)
		Art.part(m,"WindowMullion",Vector3.new(0.12,1.8,0.12),CFrame.new(p+Vector3.new(x,4.5,-5.44*flip)),wood,Enum.Material.Wood)
		Art.part(m,"WindowTransom",Vector3.new(1.8,0.12,0.12),CFrame.new(p+Vector3.new(x,4.5,-5.44*flip)),wood,Enum.Material.Wood)
		Art.part(m,"WindowSill",Vector3.new(2.5,0.22,0.7),CFrame.new(p+Vector3.new(x,3.35,-5.4*flip)),darkStone,Enum.Material.Slate)
	end
	Art.part(m,"Chimney",Vector3.new(2,5,2),CFrame.new(p+Vector3.new(3,9,2)),darkStone,Enum.Material.Cobblestone)
	for i=1,3 do Art.part(m,"EntranceStep",Vector3.new(5,0.25*i,1.3),CFrame.new(p+Vector3.new(0,0.125*i,-(5+i)*flip)),stone,Enum.Material.Slate,nil,true) end
	local yaw=if p.X<0 then -math.pi/2 else math.pi/2
	m:PivotTo(CFrame.new(p)*CFrame.Angles(0,yaw,0)*CFrame.new(-p)*m:GetPivot())
end

function WorldBuilder.build()
	lighting()
	if workspace:FindFirstChild("PortalChapter") then return end
	for _, name in {"Baseplate","SpawnLocation","PortalPerdidoBlockout","PortalQuestGuide","PortalEnemies"} do
		local old=workspace:FindFirstChild(name)
		if old then old:Destroy() end
	end
	local world=Instance.new("Model") world.Name="PortalChapter" world.Parent=workspace
	world:SetAttribute("Version",Chapter.Version)
	local terrain=workspace.Terrain
	terrain:SetMaterialColor(Enum.Material.LeafyGrass,Color3.fromRGB(105,128,88))
	terrain:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(91,94,106))
	terrain:FillBlock(CFrame.new(0,-16,-275),Vector3.new(310,32,790),Enum.Material.Rock)
	terrain:FillBlock(CFrame.new(0,-2,-275),Vector3.new(308,4,786),Enum.Material.LeafyGrass)
	local coast=folder(world,"Cliffs")
	for i=1,13 do
		local z=110-i*43
		for _, side in {-1,1} do
			terrain:FillBall(Vector3.new(side*(142+(i%3)*4),-8,z),22+(i%3)*4,Enum.Material.Rock)
			rock(coast,Vector3.new(side*(116+(i%4)*5),2,z),Vector3.new(13,8+(i%3)*3,19),i)
		end
		if i%6==0 then task.wait() end
	end
	-- Ondulações laterais mantêm o corredor, inscrições e checkpoints planos.
	for i=1,12 do
		local side=if i%2==0 then -1 else 1
		local center=Vector3.new(side*(112+(i%3)*4),-24,-30-i*31)
		local clear=true
		for _,rune in Chapter.Runes do
			if (Vector3.new(center.X,0,center.Z)-rune.position).Magnitude<62 then clear=false end
		end
		if clear then terrain:FillBall(center,34+(i%3),Enum.Material.LeafyGrass) end
	end
	-- Relevo em camadas (referência 2) antes de enraizar árvores e pedras.
	LumenRelief.sculpt(terrain)
	local groundParams=RaycastParams.new() groundParams.FilterType=Enum.RaycastFilterType.Include groundParams.FilterDescendantsInstances={terrain}
	local function rooted(x: number,z: number): Vector3
		local hit=workspace:Raycast(Vector3.new(x,80,z),Vector3.new(0,-150,0),groundParams)
		return Vector3.new(x,if hit then hit.Position.Y-2 else 0,z)
	end
	local paths=folder(world,"Paths")
	-- Caminho até a escadaria do santuário; o trecho 3→4 é a ponte em arcos sobre a garganta.
	local nodes={Vector3.new(0,0.12,70),Vector3.new(0,0.12,-70),Vector3.new(5,0.12,-91),Vector3.new(5,0.12,-125),Vector3.new(0,0.12,-185),Vector3.new(18,0.12,-245),Vector3.new(-8,0.12,-315),Vector3.new(0,0.12,-339)}
	for i=1,#nodes-1 do
		if i==3 then continue end
		local a,b=nodes[i],nodes[i+1]
		Art.part(paths,"PilgrimPath",Vector3.new(if i<3 then 9 else 7,0.25,(b-a).Magnitude+1),CFrame.lookAt((a+b)*0.5,b),Color3.fromRGB(112,105,88),if i<3 then Enum.Material.Cobblestone else Enum.Material.Ground,nil,true)
	end
	for i=1,10 do
		local z=35-i*34
		if math.abs(z-Chapter.Relief.Gorge.z)<Chapter.Relief.Gorge.halfWidth+3 then continue end
		Art.part(paths,"Waystone",Vector3.new(1.2,0.5,2),CFrame.new(-6,0.3,z),darkStone,Enum.Material.Slate)
		Art.part(paths,"Waylight",Vector3.new(0.2,0.08,0.8),CFrame.new(-6,0.58,z),cyan,Enum.Material.Neon)
	end
	local village=folder(world,"Village")
	local spawn=Instance.new("SpawnLocation") spawn.Name="EntradaDeLumen" spawn.Size=Vector3.new(8,0.2,8) spawn.Position=Vector3.new(0,0.3,32) spawn.Transparency=1 spawn.Anchored=true spawn.CanCollide=false spawn.Neutral=true spawn.Duration=0 spawn.Parent=village
	house(village,Vector3.new(-30,0,35),1)
	house(village,Vector3.new(36,0,48),1)
	house(village,Vector3.new(-38,0,-4),1)
	Art.portal(village,Vector3.new(-24,0,-28),10)
	for i=1,3 do
		local x=-18+(i-1)*18
		local z=58
		Art.part(village,"BenchSeat",Vector3.new(5,0.35,1.5),CFrame.new(x,1.5,z),wood,Enum.Material.WoodPlanks,nil,true)
		Art.part(village,"BenchBack",Vector3.new(5,1.4,0.25),CFrame.new(x,2.2,z+0.65),wood,Enum.Material.WoodPlanks)
		for _, side in {-1,1} do Art.part(village,"BenchLeg",Vector3.new(0.35,1.5,1.3),CFrame.new(x+side*1.8,0.75,z),wood,Enum.Material.Wood) end
	end
	for i=1,4 do
		local x=if i%2==0 then 18 else -18
		local z=12+i*9
		Art.segment(village,"LanternPost",Vector3.new(x,0,z),Vector3.new(x,6,z),0.2,wood,Enum.Material.Wood)
		Art.part(village,"LanternFrame",Vector3.new(0.9,1.2,0.9),CFrame.new(x,6,z),darkStone,Enum.Material.Metal)
		Art.part(village,"LanternGlass",Vector3.new(0.55,0.8,0.55),CFrame.new(x,6,z-0.25),amber,Enum.Material.Neon)
	end
	for i=1,12 do
		local x=if i%2==0 then -14-i%4 else 17+i%3
		local z=-2+i*4
		Art.segment(village,"HerbStem",Vector3.new(x,0,z),Vector3.new(x,0.8,z),0.07,Color3.fromRGB(74,110,71),Enum.Material.Grass)
		Art.part(village,"Wildflower",Vector3.new(0.5,0.2,0.5),CFrame.new(x,0.8,z),if i%3==0 then amber else Color3.fromRGB(167,145,190),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
	end
	Art.npc(village,Chapter.Ilyra)
	sign(village,Vector3.new(-8,0,12),"VALE DE LÚMEN","Refúgio dos viajantes")
	sign(village,Vector3.new(13,0,-86),"FLORESTA ESQUECIDA","Atravesse a ponte da garganta")
	-- Clareiras e grupos assimétricos: evitar a aparência de avenida arborizada.
	for i,point in {Vector2.new(-53,62),Vector2.new(59,72),Vector2.new(-61,18),Vector2.new(55,16),Vector2.new(-31,-46),Vector2.new(37,-58),Vector2.new(-54,-81),Vector2.new(61,-87)} do
		if not LumenRelief.blocked(point.X,point.Y,3) then Art.tree(village,rooted(point.X,point.Y),i,false) end
	end
	task.wait()
	local forest=folder(world,"Forest")
	local forestRng=Random.new(49621)
	for i=1,36 do
		local side=if i%2==0 then -1 else 1
		local z=-115-math.floor(i/2)*13+forestRng:NextNumber(-8,8)
		local x=side*(30+(i%5)*15+forestRng:NextNumber(-5,8))
		-- Corredor central desobstruído; árvores fora dos pontos de inscrição.
		local clear=true
		for _, rune in Chapter.Runes do
			if (Vector3.new(x,0,z)-rune.position).Magnitude<18 then clear=false end
			if math.abs(z-rune.position.Z)<12 and x*rune.position.X>0 and math.abs(x)<math.abs(rune.position.X)+8 then clear=false end
		end
		if clear and not LumenRelief.blocked(x,z,4) then Art.tree(forest,rooted(x,z),80+i,true) end
		if i%8==0 then task.wait() end
	end
	for i=1,24 do
		local side=if i%2==0 then -1 else 1
		local x=side*(16+(i%4)*17)
		local z=-125-i*9
		if LumenRelief.blocked(x,z,3) then continue end
		local ground=rooted(x,z)
		rock(forest,Vector3.new(x,ground.Y+0.8,z),Vector3.new(4+i%3,2.5,5),i)
		Art.part(forest,"AmberMushroom",Vector3.new(0.9,0.5,0.9),CFrame.new(x+2,ground.Y+0.8,z),amber,Enum.Material.Neon,Enum.PartType.Ball)
	end
	-- Trilhas levam ao acesso vertical de cada inscrição: escadaria, pilares e pedras flutuantes.
	local access={Vector3.new(-12,0.16,-179),Vector3.new(21,0.16,-243),Vector3.new(-24,0.16,-309)}
	local hints={"Suba a escadaria da colina","Salte pelos pilares","Suba pelas pedras flutuantes"}
	for i, definition in Chapter.Runes do
		local a=Vector3.new(if i==2 then 16 else -2,0.16,definition.position.Z+8)
		local b=access[i]
		Art.part(paths,"RuneTrail",Vector3.new(4,0.3,(b-a).Magnitude),CFrame.lookAt((a+b)*0.5,b),Color3.fromRGB(124,113,94),Enum.Material.Ground,nil,true)
		sign(forest,Vector3.new(if i==2 then 12 else -10,0,definition.position.Z+12),"INSCRIÇÃO "..definition.symbol,hints[i])
	end
	local floors={Dawn=Chapter.Relief.DawnHill,Root=Chapter.Relief.RootMesa,Star=Chapter.Relief.StarIsland}
	local runes=folder(world,"Runes")
	for index, definition in Chapter.Runes do
		local m=Instance.new("Model") m.Name=definition.id m.Parent=runes
		-- Coordenadas locais: o mundo inteiro sobe +2 no final.
		local pos=Vector3.new(definition.position.X,(floors[definition.id] or 2)-2,definition.position.Z)
		Art.part(m,"AncientPlinth",Vector3.new(7,0.7,7),CFrame.new(pos+Vector3.new(0,0.3,0)),darkStone,Enum.Material.Slate,nil,true)
		Art.part(m,"InscribedStone",Vector3.new(2.6,5,1.5),CFrame.new(pos+Vector3.new(0,3,0)),stone,Enum.Material.Slate,nil,true)
		local core=Art.part(m,"Core",Vector3.new(0.55,1.9,0.15),CFrame.new(pos+Vector3.new(0,3,-0.85)),if index==1 then amber elseif index==2 then cyan else Color3.fromRGB(158,130,215),Enum.Material.Neon)
		Art.label(core,definition.name,"Inscrição "..definition.symbol,nil,3.6)
		for j=1,3 do rock(m,pos+Vector3.new(j*2-4,0.4,3),Vector3.new(2.5,1.8,2),j) end
	end
	task.wait()
	local temple=folder(world,"Temple")
	sign(temple,Vector3.new(-16,0,-334),"SANTUÁRIO DA AURORA","Suba a escadaria · Aurora / Raiz / Estrela")
	-- Santuário no alto do platô: `ty` desloca a antiga cota 0 para o piso elevado.
	local ty=Chapter.Relief.Temple-2.5
	Art.part(temple,"TempleFoundation",Vector3.new(84,6,94),CFrame.new(0,ty-2.5,-423),darkStone,Enum.Material.Slate,nil,true)
	for _, x in {-27,27} do
		for _, z in {-408,-433,-450} do
			Art.part(temple,"ColumnBase",Vector3.new(7,1,7),CFrame.new(x,ty+1,z),stone,Enum.Material.Slate,nil,true)
			Art.segment(temple,"AncientColumn",Vector3.new(x,ty+1,z),Vector3.new(x,ty+21,z),4,stone,Enum.Material.Marble,true)
			Art.part(temple,"ColumnCrown",Vector3.new(6,1.2,6),CFrame.new(x,ty+21,z),stone,Enum.Material.Slate)
		end
	end
	Art.part(temple,"Entablature",Vector3.new(61,4,7),CFrame.new(0,ty+23,-408),stone,Enum.Material.Slate)
	local seals=folder(temple,"Seals")
	for i, id in Chapter.SealOrder do
		local m=Instance.new("Model") m.Name=id m.Parent=seals
		local pos=Vector3.new((i-2)*12,ty+1,-420)
		Art.part(m,"Pedestal",Vector3.new(3,3,3),CFrame.new(pos+Vector3.new(0,1,0)),stone,Enum.Material.Slate,nil,true)
		local core=Art.part(m,"Core",Vector3.new(1,1,1),CFrame.new(pos+Vector3.new(0,3,0)),if i==1 then amber elseif i==2 then cyan else Color3.fromRGB(158,130,215),Enum.Material.Neon,Enum.PartType.Ball)
		Art.label(core,if i==1 then "AURORA" elseif i==2 then "RAIZ" else "ESTRELA",nil,nil,2)
	end
	-- Limiar sólido no muro do santuário: o prompt é a única passagem para o caminho suspenso.
	local gate=Art.part(temple,"ArenaGate",Vector3.new(15,13,0.6),CFrame.new(0,ty+7,Chapter.Relief.GateZ),Color3.fromRGB(102,112,173),Enum.Material.Neon,nil,true)
	gate.Transparency=0.65
	Art.label(gate,"O LIMIAR","Os três selos guardam a passagem",nil,7)
	-- Arena suspensa: `ay` desloca a antiga cota 0 para o topo da ilha.
	local ay=Chapter.Relief.Arena-2.6
	local arena=folder(world,"Arena")
	Art.part(arena,"SanctumFloor",Vector3.new(1.2,91,91),CFrame.new(0,ay,-550)*CFrame.Angles(0,0,math.pi/2),darkStone,Enum.Material.Slate,Enum.PartType.Cylinder,true)
	for i=1,12 do
		local angle=i*math.pi*2/12
		local pos=Vector3.new(math.cos(angle)*44,ay,math.sin(angle)*44-550)
		-- Abertura ao norte para o caminho de pedras flutuantes.
		if math.abs(math.cos(angle))<0.3 and math.sin(angle)>0 then continue end
		Art.part(arena,"BrokenPillar",Vector3.new(4,10+(i%3)*3,4),CFrame.new(pos+Vector3.new(0,5,0))*CFrame.Angles(0,angle,0),stone,Enum.Material.Slate,nil,true)
		Art.part(arena,"RuneLight",Vector3.new(0.35,3,0.1),CFrame.new(pos+Vector3.new(0,4,-2.1)),cyan,Enum.Material.Neon)
	end
	local fragment=Art.part(arena,"AuroraFragment",Vector3.new(1.5,3,1.5),CFrame.new(0,ay+4,-578)*CFrame.Angles(0,0,0.4),amber,Enum.Material.Neon)
	Art.part(arena,"FragmentAltar",Vector3.new(6,2,6),CFrame.new(0,ay+1,-578),stone,Enum.Material.Marble,nil,true)
	Art.label(fragment,"FRAGMENTO DA AURORA","Uma memória entre mundos",amber,4)
	for i=1,32 do
		local a=i*math.pi*2/32 local b=(i+1)*math.pi*2/32
		Art.segment(arena,"SanctumBoundary",Vector3.new(math.cos(a)*46,ay+0.68,math.sin(a)*46-550),Vector3.new(math.cos(b)*46,ay+0.68,math.sin(b)*46-550),0.12,cyan,Enum.Material.Neon)
	end
	local rests=folder(world,"RestShrines")
	for _, definition in {{"Forest",Vector3.new(12,0,-145)},{"Temple",Vector3.new(-15,ty,-390)}} do
		local m=Instance.new("Model") m.Name=definition[1] m.Parent=rests
		local pos=definition[2]
		Art.part(m,"Basin",Vector3.new(4,1.3,4),CFrame.new(pos+Vector3.new(0,0.6,0)),stone,Enum.Material.Marble,Enum.PartType.Ball,true)
		Art.part(m,"Water",Vector3.new(2.5,0.15,2.5),CFrame.new(pos+Vector3.new(0,1.2,0)),cyan,Enum.Material.Neon,Enum.PartType.Ball)
		local core=Art.part(m,"Core",Vector3.new(0.8,2,0.8),CFrame.new(pos+Vector3.new(0,2.5,0)),cyan,Enum.Material.Neon,Enum.PartType.Ball)
		Art.label(core,"FONTE DE LÚMEN","Descanso e ponto de retorno",nil,3)
	end
	local home=Art.part(arena,"ReturnStone",Vector3.new(2,4,2),CFrame.new(22,ay+2,-529),cyan,Enum.Material.Neon)
	Art.label(home,"VALE DE LÚMEN","Retornar ao refúgio",nil,3)
	local vistas=folder(world,"DistantIslands")
	for i=1,6 do
		local pos=Vector3.new((if i%2==0 then -1 else 1)*(220+i*17),-30+i*6,-200-i*85)
		rock(vistas,pos,Vector3.new(56,30,60),i)
		Art.part(vistas,"DistantGrass",Vector3.new(48,4,49),CFrame.new(pos+Vector3.new(0,12,0)),Color3.fromRGB(65,104,85),Enum.Material.Grass,Enum.PartType.Ball)
	end
	folder(workspace,"PortalEnemies")
	LumenScenery.build(world)
	-- A superfície suave dos voxels termina em Y=2; alinhar a cenografia.
	world:PivotTo(world:GetPivot()+Vector3.new(0,2,0))
	-- Estruturas do relevo usam alturas absolutas (Chapter.Relief): depois do ajuste.
	LumenRelief.build(world)
	world:SetAttribute("Ready",true)
	print("[PortalPerdido] Vale, floresta e templo construídos.")
end

return WorldBuilder
