--!strict
-- Prólogo 3D local em cinco cenas: feira de ciências na escola, apagão, silêncio, despertar
-- e confusão em Aetherion já com roupas de aventureiro e poderes. Tudo é criado só no cliente
-- e destruído ao final; não altera o mundo do servidor nem o progresso.
--
-- Todos os corpos (público, os seis jovens e os aventureiros) usam CinematicBody: articulações
-- animadas, com caminhada/corrida, conversa, susto, fuga, desmaio e despertar. Para evitar o
-- aspecto robótico: nenhum corpo fica congelado (respiração e microgestos sempre ativos) e, no
-- despertar, cabeça e braços acompanham o tronco com atraso.
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Art=require(script.Parent.Art)
local Body=require(script.Parent.CinematicBody)
local Classes=require(script.Parent.Config.Classes)
local V=Vector3.new
local Cinematic={}
-- Duração de cada página (escola, apagão, silêncio, despertar, confusão).
local PAGE_SECONDS={9,11,6,12,11}
Cinematic.pageCount=#PAGE_SECONDS
local origin=V(0,2000,0)
-- Centro do despertar, ao lado da Entrada de Lúmen (spawn em z 32), com vista para o vale ao norte.
local wakeCenter=V(0,0,20)

local SKIN_PARTS={Head=true,LeftLowerArm=true,RightLowerArm=true,LeftHand=true,RightHand=true}
local SHIRT_PARTS={UpperTorso=true,LeftUpperArm=true,RightUpperArm=true}
local PANTS_PARTS={LowerTorso=true,LeftUpperLeg=true,RightUpperLeg=true,LeftLowerLeg=true,RightLowerLeg=true}
local SHOE_PARTS={LeftFoot=true,RightFoot=true}
-- Os seis jovens são os seis heróis (ordem das classes); faltando um retrato, repete os existentes.
local CLASS_ORDER={"Guardian","Explorer","Artificer","Brawler","Arcanist","Shade"}
local UNIFORM_SHIRTS={Color3.fromRGB(236,238,240),Color3.fromRGB(214,228,243),Color3.fromRGB(226,232,222)}
local UNIFORM_PANTS={Color3.fromRGB(38,52,86),Color3.fromRGB(58,74,110),Color3.fromRGB(34,40,58)}
local ADULT_SHIRTS={Color3.fromRGB(44,62,104),Color3.fromRGB(122,44,54),Color3.fromRGB(104,112,64),Color3.fromRGB(196,178,140),Color3.fromRGB(44,110,120),Color3.fromRGB(150,96,150)}
local ADULT_PANTS={Color3.fromRGB(62,82,122),Color3.fromRGB(168,148,110),Color3.fromRGB(42,42,48)}
local SHOES={Color3.fromRGB(232,232,232),Color3.fromRGB(46,46,52),Color3.fromRGB(110,74,50)}
local BAGS={Color3.fromRGB(176,64,58),Color3.fromRGB(58,112,160),Color3.fromRGB(214,168,64),Color3.fromRGB(70,140,90)}

local function staticClone(template: Model, name: string, parent: Instance): Model
	local actor=template:Clone() actor.Name=name
	for _,item in actor:GetDescendants() do
		if item:IsA("LuaSourceContainer") or item:IsA("BillboardGui") or item:IsA("Humanoid") then item:Destroy()
		elseif item:IsA("BasePart") then item.Anchored=true item.CanCollide=false item.CanTouch=false item.CanQuery=false end
	end
	actor.Parent=parent
	return actor
end

-- Troca a roupa de aventureiro (textura do rig + equipamento) por roupa comum.
local function dress(actor: Model, shirt: Color3, pants: Color3, shoes: Color3, bag: Color3?, labCoat: boolean?)
	local equipment=actor:FindFirstChild("ClassEquipment")
	if equipment then equipment:Destroy() end
	for _,part in actor:GetDescendants() do
		-- Gola, capuz e acessórios rígidos do traje de aventureiro não fazem parte da roupa comum.
		if part:IsA("BasePart") and part.Name:sub(1,9)=="RBX_RIGID" and part.Name~="RBX_RIGID_hair" then part.Transparency=1 end
		if part:IsA("BasePart") and not SKIN_PARTS[part.Name] then
			local color=if SHIRT_PARTS[part.Name] then shirt elseif PANTS_PARTS[part.Name] then pants elseif SHOE_PARTS[part.Name] then shoes else nil
			if color then
				local appearance=part:FindFirstChildOfClass("SurfaceAppearance")
				if appearance then appearance:Destroy() end
				part.Color=color
				part.Material=if PANTS_PARTS[part.Name] then Enum.Material.Fabric else Enum.Material.SmoothPlastic
			end
		end
	end
	local torso=actor:FindFirstChild("UpperTorso")
	if not torso or not torso:IsA("BasePart") then return end
	-- Acessórios novos são soldados ao tronco: CinematicBody os leva junto.
	local function attach(part: BasePart)
		part.Anchored=true
		local weld=Instance.new("WeldConstraint") weld.Part0=torso weld.Part1=part weld.Parent=part
	end
	if bag then
		attach(Art.part(actor,"SchoolBackpack",V(1.35,1.6,0.75),torso.CFrame*CFrame.new(0,-0.05,0.72),bag,Enum.Material.Fabric,Enum.PartType.Ball))
		attach(Art.part(actor,"BackpackPocket",V(0.9,0.7,0.4),torso.CFrame*CFrame.new(0,-0.4,1.05),bag:Lerp(Color3.new(0,0,0),0.2),Enum.Material.Fabric,Enum.PartType.Ball))
	end
	if labCoat then
		local hips=actor:FindFirstChild("LowerTorso")
		local tail=Art.part(actor,"LabCoatTail",V(1.9,1.7,1.05),torso.CFrame*CFrame.new(0,-1.55,0.02),Color3.fromRGB(240,242,244),Enum.Material.SmoothPlastic)
		tail.Anchored=true
		if hips and hips:IsA("BasePart") then local weld=Instance.new("WeldConstraint") weld.Part0=hips weld.Part1=tail weld.Parent=tail end
	end
end

local function smooth(t: number): number
	local x=math.clamp(t,0,1)
	return x*x*(3-2*x)
end

local function yawTo(from: Vector3, to: Vector3): number
	local d=to-from
	return math.deg(math.atan2(-d.X,-d.Z))
end

local function turnToward(current: number, target: number, amount: number): number
	return current+(((target-current+180)%360)-180)*math.clamp(amount,0,1)
end

local function groundY(x: number, z: number, ignore: {Instance}): number
	local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances=ignore
	local hit=workspace:Raycast(V(x,300,z),V(0,-600,0),params)
	return if hit then hit.Position.Y else 0.3
end

local function with(...: Body.Pose): Body.Pose
	local result: Body.Pose={}
	for _,pose in {...} do for key,value in pose do result[key]=value end end
	return result
end

-- Espelha uma pose (esquerda ↔ direita), para variar quem usa qual mão.
local function mirror(pose: Body.Pose): Body.Pose
	local result: Body.Pose={}
	for key,value in pose do
		local name=if key:sub(1,4)=="Left" then "Right"..key:sub(5) elseif key:sub(1,5)=="Right" then "Left"..key:sub(6) else key
		result[name]=V(value.X,-value.Y,-value.Z)
	end
	return result
end

-- Poses (convenções em CinematicBody). Ângulos de braço calibrados nos rigs: mão na testa,
-- mãos à frente do peito e mão no joelho.
local RIGHT_HEAD={RightUpperArm=V(110,0,12),RightLowerArm=V(85,0,-52)}
local LEFT_HEAD={LeftUpperArm=V(110,0,-12),LeftLowerArm=V(85,0,52)}
local POSES: {[string]: Body.Pose}={
	Idle={UpperTorso=V(-2,0,0),LeftUpperArm=V(4,0,-3),RightUpperArm=V(4,0,3),LeftLowerArm=V(10,0,0),RightLowerArm=V(10,0,0)},
	Point={Head=V(6,0,0),UpperTorso=V(2,0,0),RightUpperArm=V(100,0,8),RightLowerArm=V(8,0,0)},
	-- Susto: braços diante do rosto, tronco recua.
	Protect={UpperTorso=V(10,0,0),Head=V(-10,0,0),LeftUpperArm=V(80,0,-12),LeftLowerArm=V(95,0,45),RightUpperArm=V(80,0,12),RightLowerArm=V(95,0,-45)},
	-- Tentando segurar/desligar o experimento: braços estendidos, corpo inclinado para trás.
	Reach={UpperTorso=V(8,0,0),Head=V(-6,0,0),LeftUpperArm=V(78,0,-6),LeftLowerArm=V(22,0,0),RightUpperArm=V(78,0,6),RightLowerArm=V(22,0,0),
		LeftUpperLeg=V(18,0,-4),LeftLowerLeg=V(-22,0,0),RightUpperLeg=V(-12,0,4)},
	-- Joelhos cedendo no desmaio.
	Slump={UpperTorso=V(-24,0,0),Head=V(-30,0,10),LeftUpperLeg=V(62,0,-6),LeftLowerLeg=V(-104,0,0),RightUpperLeg=V(54,0,6),RightLowerLeg=V(-98,0,0),
		LeftUpperArm=V(-6,0,-10),RightUpperArm=V(-4,0,12)},
	Lying={Root=V(90,0,0),Head=V(0,22,0),LeftUpperArm=V(0,0,-16),RightUpperArm=V(0,0,16),LeftUpperLeg=V(6,0,-6),RightLowerLeg=V(-10,0,0)},
	-- Despertar.
	Stir=with({Root=V(90,0,0),Head=V(0,-18,0),RightUpperLeg=V(40,0,4),RightLowerLeg=V(-70,0,0),LeftUpperArm=V(0,0,-20)},RIGHT_HEAD),
	Prop={Root=V(55,0,0),UpperTorso=V(-12,0,0),Head=V(-18,10,0),LeftUpperLeg=V(35,0,-4),RightUpperLeg=V(60,0,6),RightLowerLeg=V(-60,0,0),
		LeftUpperArm=V(-45,0,-12),LeftLowerArm=V(45,0,0),RightUpperArm=V(-45,0,12),RightLowerArm=V(45,0,0)},
	Sit=with({UpperTorso=V(6,0,0),Head=V(-16,0,-6),LeftUpperLeg=V(88,0,-4),LeftLowerLeg=V(-6,0,0),RightUpperLeg=V(135,0,6),RightLowerLeg=V(-130,0,0),
		LeftUpperArm=V(-35,0,-10),LeftLowerArm=V(10,0,0)},RIGHT_HEAD),
	Kneel=with({UpperTorso=V(-18,0,0),Head=V(-8,14,6),RightUpperLeg=V(88,0,4),RightLowerLeg=V(-88,0,0),LeftUpperLeg=V(4,0,-3),LeftLowerLeg=V(-88,0,0),
		RightUpperArm=V(38,0,-6),RightLowerArm=V(4,0,-4)},LEFT_HEAD),
	-- Quase de pé, curvado, mãos nos joelhos recuperando o fôlego.
	Rise={UpperTorso=V(-34,0,0),Head=V(22,0,0),LeftUpperLeg=V(28,0,-5),LeftLowerLeg=V(-26,0,0),RightUpperLeg=V(24,0,5),RightLowerLeg=V(-22,0,0),
		LeftUpperArm=V(42,0,-4),LeftLowerArm=V(6,0,0),RightUpperArm=V(42,0,4),RightLowerArm=V(6,0,0)},
	-- Cambaleio: tronco inclina, braço abre para equilibrar.
	Sway={UpperTorso=V(-6,0,-7),Head=V(-4,0,8),LeftUpperArm=V(6,0,-38),LeftLowerArm=V(18,0,0),RightUpperArm=V(-4,0,10),
		LeftUpperLeg=V(-4,0,-9),RightUpperLeg=V(6,0,3),RightLowerLeg=V(-8,0,0)},
	Stand={UpperTorso=V(-4,0,0),Head=V(-6,0,0),LeftLowerArm=V(10,0,0),RightLowerArm=V(10,0,0)},
	-- Gestos de confusão e descoberta dos poderes (de pé).
	HeadHand=with({Head=V(-14,0,-6),UpperTorso=V(-3,0,0)},RIGHT_HEAD),
	Hands={Head=V(-36,0,0),UpperTorso=V(-6,0,0),LeftUpperArm=V(40,0,-6),LeftLowerArm=V(62,0,48),RightUpperArm=V(40,0,6),RightLowerArm=V(62,0,-48)},
	Clothes={Head=V(-40,-12,0),UpperTorso=V(-8,0,0),LeftUpperArm=V(12,0,-34),LeftLowerArm=V(20,0,0),RightUpperArm=V(12,0,34),RightLowerArm=V(20,0,0)},
	Shrug={Head=V(4,0,8),LeftUpperArm=V(10,0,-24),LeftLowerArm=V(75,0,0),RightUpperArm=V(10,0,24),RightLowerArm=V(75,0,0)},
	LookAround={Head=V(6,0,0),UpperTorso=V(2,0,0)},
	-- Guarda de luta (o lutador testando os punhos).
	Guard={UpperTorso=V(-6,14,0),Head=V(-4,-12,0),LeftUpperArm=V(70,0,-10),LeftLowerArm=V(105,0,30),RightUpperArm=V(55,0,14),RightLowerArm=V(120,0,-30),
		LeftUpperLeg=V(16,0,-6),LeftLowerLeg=V(-14,0,0),RightUpperLeg=V(-10,0,8)},
	-- Mão aberta erguida (energia na palma).
	Palm={Head=V(-10,0,0),RightUpperArm=V(85,0,20),RightLowerArm=V(40,0,-20),LeftUpperArm=V(10,0,-8)},
}

-- Sequência para se levantar: {pose, transição até ela, tempo nela, avanço do quadril}.
-- Os tempos "parados" nunca congelam: respiração e balanço da cabeça continuam por cima.
local GET_UP={
	{"Lying",0,0.5,0},{"Stir",0.9,0.4,0},{"Prop",1.0,0.2,0.1},{"Sit",0.9,0.7,0.25},
	{"Kneel",1.1,0.2,0.95},{"Rise",1.0,0.5,1.2},{"Sway",0.7,0.1,1.3},{"Stand",0.9,0,1.35},
}
local GET_UP_END=0
for _,step in GET_UP do GET_UP_END+=step[2]+step[3] end

local function getUpPose(time: number): (Body.Pose, number)
	local clock=0
	local previous=GET_UP[1]
	for _,step in GET_UP do
		local blendEnd=clock+step[2]
		if time<blendEnd and step[2]>0 then
			local t=smooth((time-clock)/step[2])
			return Body.blend(POSES[previous[1]],POSES[step[1]],t),previous[4]+(step[4]-previous[4])*t
		end
		clock=blendEnd+step[3]
		if time<clock then return POSES[step[1]],step[4] end
		previous=step
	end
	return POSES.Stand,GET_UP[#GET_UP][4]
end

local HEAD_KEYS={Head=true}
local ARM_KEYS={LeftUpperArm=true,LeftLowerArm=true,RightUpperArm=true,RightLowerArm=true}
-- Despertar com atraso por grupo: o tronco conduz, a cabeça segue 0,18 s depois e os braços 0,32 s.
local function layeredGetUp(time: number): (Body.Pose, number)
	local core,advance=getUpPose(time)
	local head=getUpPose(time-0.18)
	local arms=getUpPose(time-0.32)
	local result: Body.Pose={}
	for key,value in core do if not HEAD_KEYS[key] and not ARM_KEYS[key] then result[key]=value end end
	for key in HEAD_KEYS do if head[key] then result[key]=head[key] end end
	for key in ARM_KEYS do if arms[key] then result[key]=arms[key] end end
	return result,advance
end

-- Caminhada/corrida: pernas alternadas com o joelho dobrando ao avançar, braços opostos.
local function gait(cycle: number, amp: number, run: boolean): Body.Pose
	local s,c=math.sin(cycle),math.cos(cycle)
	return {
		LeftUpperLeg=V(s*amp,0,-2),RightUpperLeg=V(-s*amp,0,2),
		LeftLowerLeg=V(-math.max(0,c)*amp*1.35-6,0,0),RightLowerLeg=V(-math.max(0,-c)*amp*1.35-6,0,0),
		LeftUpperArm=V(-s*amp*0.8,0,-6),RightUpperArm=V(s*amp*0.8,0,6),
		LeftLowerArm=V(if run then 80 else 16,0,0),RightLowerArm=V(if run then 80 else 16,0,0),
		UpperTorso=V(if run then -14 else -3,s*6,0),Head=V(if run then 10 else 2,-s*4,0),
	}
end

-- Quem fala gesticula; quem escuta acena com a cabeça.
local function talking(time: number, phase: number, speaking: boolean): Body.Pose
	if speaking then
		local g=math.sin(time*2.3+phase)
		return {Head=V(math.sin(time*3.1+phase)*5,g*6,math.sin(time*1.7)*4),UpperTorso=V(0,g*5,0),
			RightUpperArm=V(30+g*12,0,10),RightLowerArm=V(62+math.sin(time*4.2+phase)*20,0,-26),
			LeftUpperArm=V(10,0,-5),LeftLowerArm=V(20+math.max(0,math.sin(time*1.3+phase))*40,0,16)}
	end
	return {Head=V(math.max(0,math.sin(time*1.6+phase))*9,0,math.sin(time*0.7+phase)*5),UpperTorso=V(-2,0,0),
		LeftLowerArm=V(14,0,0),RightLowerArm=V(14,0,0)}
end

-- Respiração e peso alternando entre as pernas: ninguém fica imóvel.
local function alive(time: number, phase: number): Body.Pose
	local w=math.sin(time*0.55+phase)
	return {UpperTorso=V(math.sin(time*1.7+phase)*1.4,0,w*1.2),Head=V(0,math.sin(time*0.4+phase*2)*6,0),
		LeftUpperLeg=V(0,0,-1+w*2),RightUpperLeg=V(0,0,1+w*2),Root=V(0,0,w*0.8)}
end

-- Onde cada um cai no vale (deslocamento do quadril, rumo em graus), gestos de confusão e atraso.
local WAKE_LAYOUT={
	{offset=V(-4.6,0,1.5),yaw=25,gestures={"HeadHand","Hands","LookAround"},delay=0.2,speed=1.0,mirror=false},
	{offset=V(-0.8,0,-3.2),yaw=-40,gestures={"Hands","LookAround","Clothes"},delay=1.3,speed=1.12,mirror=true},
	{offset=V(3.6,0,-0.4),yaw=110,gestures={"LookAround","Palm","Shrug"},delay=0.7,speed=0.92,mirror=false},
	{offset=V(0.6,0,3.6),yaw=200,gestures={"Clothes","Guard","HeadHand"},delay=2.0,speed=1.18,mirror=true},
	{offset=V(-3.2,0,-4.8),yaw=-120,gestures={"Shrug","Palm","LookAround"},delay=1.6,speed=0.95,mirror=false},
	{offset=V(4.4,0,4.4),yaw=160,gestures={"LookAround","Hands","Clothes"},delay=2.5,speed=1.05,mirror=true},
}
local POWER_GESTURES={Hands=true,Palm=true,Guard=true}

-- Público da feira: posição (relativa ao ginásio), comportamento e com quem conversa.
local CROWD={
	{p=V(-10.5,0,11.5),kind="student",act="talk",partner=2,speaks=true},{p=V(-7.6,0,13.4),kind="adult",act="talk",partner=1},
	{p=V(-3.4,0,11.2),kind="student",act="point"},
	{p=V(0.4,0,13.6),kind="adult",act="talk",partner=5,speaks=true},{p=V(3.4,0,11.6),kind="student",act="talk",partner=4},
	{p=V(7.6,0,13.9),kind="student",act="watch"},{p=V(11,0,11.6),kind="adult",act="watch"},
	{p=V(-14,0,3.4),kind="student",act="talk",partner=9,speaks=true},{p=V(-15.2,0,7.2),kind="adult",act="talk",partner=8},
	{p=V(14.2,0,2.6),kind="adult",act="talk",partner=11},{p=V(15.4,0,6.6),kind="student",act="talk",partner=10,speaks=true},
	{p=V(-26,0,-2),kind="student",act="walk",route={V(-26,0,-2),V(-24,0,24),V(-34,0,24),V(-34,0,-2)}},
	{p=V(26,0,26),kind="adult",act="walk",route={V(26,0,26),V(24,0,-2),V(34,0,-2),V(34,0,26)}},
	{p=V(8.6,2,-12.8),kind="teacher",act="teach"},
	{p=V(-20,0,16),kind="adult",act="watch"},{p=V(19,0,18),kind="student",act="point"},
}
local DOORS={V(-12,0,37),V(12,0,37)}
-- Onde cada um dos seis tenta parar o experimento (relativo ao ginásio; palco em y 2).
local STOP_SPOTS={V(10.5,0,-12.6),V(-3,0,-14.2),V(-6.2,0,-15.6),V(6.2,0,-15.6),V(3,0,-14.2),V(0,0,-12.2)}

type Actor={model: Model, body: Body.Body, pos: Vector3, yaw: number, phase: number, cycle: number, spec: any, from: Body.Pose?}

function Cinematic.start(onPage: (number) -> (),onFinish: () -> ())
	local scene=Instance.new("Model") scene.Name="PortalArrivalCinematic" scene.Parent=workspace
	local function block(name: string,size: Vector3,p: Vector3,color: Color3,material: Enum.Material,shape: Enum.PartType?)
		return Art.part(scene,name,size,CFrame.new(origin+p),color,material,shape)
	end

	-- Ginásio da escola durante a feira de ciências.
	local wall=Color3.fromRGB(214,204,182)
	block("GymFloor",V(80,1,80),V(0,-0.5,0),Color3.fromRGB(196,150,98),Enum.Material.WoodPlanks)
	block("CourtLine",V(60,0.05,0.4),V(0,0.03,14),Color3.fromRGB(232,232,226),Enum.Material.SmoothPlastic)
	block("CourtCircle",V(0.05,14,14),V(0,0.03,14),Color3.fromRGB(232,232,226),Enum.Material.SmoothPlastic,Enum.PartType.Cylinder).CFrame=CFrame.new(origin+V(0,0.03,14))*CFrame.Angles(0,0,math.pi/2)
	block("CourtCircleInner",V(0.06,13.2,13.2),V(0,0.04,14),Color3.fromRGB(196,150,98),Enum.Material.WoodPlanks,Enum.PartType.Cylinder).CFrame=CFrame.new(origin+V(0,0.04,14))*CFrame.Angles(0,0,math.pi/2)
	for _,x in {-40,40} do block("SideWall",V(1,26,80),V(x,13,0),wall,Enum.Material.Concrete) end
	block("BackWall",V(80,26,1),V(0,13,-26),wall,Enum.Material.Concrete)
	-- Parede de saída com duas portas abertas e placas luminosas.
	for _,segment in {{-27.5,25},{0,18},{27.5,25}} do block("FrontWall",V(segment[2],26,1),V(segment[1],13,40),wall,Enum.Material.Concrete) end
	for _,x in {-12,12} do
		block("DoorHeader",V(6,16,1),V(x,18,40),wall,Enum.Material.Concrete)
		block("Doorway",V(6,10,0.2),V(x,5,41.5),Color3.fromRGB(20,22,28),Enum.Material.SmoothPlastic)
		block("ExitSign",V(2.6,0.9,0.2),V(x,11,39.4),Color3.fromRGB(60,220,120),Enum.Material.Neon)
	end
	block("Ceiling",V(80,1,80),V(0,26,0),Color3.fromRGB(150,146,138),Enum.Material.Metal)
	block("WallStripe",V(79,2,0.2),V(0,4,-25.4),Color3.fromRGB(46,92,150),Enum.Material.SmoothPlastic)
	-- Palco e faixa da feira.
	block("Stage",V(36,2,14),V(0,1,-18),Color3.fromRGB(122,84,56),Enum.Material.WoodPlanks)
	block("StageStep",V(10,1,2),V(0,0.5,-10),Color3.fromRGB(122,84,56),Enum.Material.WoodPlanks)
	local banner=block("FairBanner",V(30,5,0.2),V(0,17,-25.3),Color3.fromRGB(32,78,138),Enum.Material.Fabric)
	local gui=Instance.new("SurfaceGui") gui.Face=Enum.NormalId.Back gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud gui.PixelsPerStud=30 gui.LightInfluence=0.6 gui.Parent=banner
	local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1 label.Font=Enum.Font.GothamBlack
	label.Text="FEIRA DE CIÊNCIAS" label.TextScaled=true label.TextColor3=Color3.fromRGB(250,236,190) label.Parent=gui
	local padding=Instance.new("UIPadding") padding.PaddingTop=UDim.new(0.15,0) padding.PaddingBottom=UDim.new(0.15,0) padding.PaddingLeft=UDim.new(0.05,0) padding.PaddingRight=UDim.new(0.05,0) padding.Parent=label
	for i,x in {-30,-30,30,30} do
		local z=if i%2==1 then 4 else 20
		block("FairTable",V(6,0.3,3),V(x,3,z),Color3.fromRGB(236,236,232),Enum.Material.SmoothPlastic)
		block("FairTableSkirt",V(6,2.8,0.1),V(x,1.5,z-1.5),Color3.fromRGB(46,92,150),Enum.Material.Fabric)
		block("FairPoster",V(0.1,3.5,4.5),V(x+(if x<0 then -9.4 else 9.4),6.5,z),({Color3.fromRGB(226,190,92),Color3.fromRGB(120,180,120),Color3.fromRGB(210,120,110),Color3.fromRGB(130,160,210)})[i],Enum.Material.SmoothPlastic)
		block("FairProject",V(1.4,1.4,1.4),V(x,3.85,z),({Color3.fromRGB(150,90,60),Color3.fromRGB(80,140,90),Color3.fromRGB(90,90,110),Color3.fromRGB(200,170,80)})[i],Enum.Material.SmoothPlastic,Enum.PartType.Ball)
	end
	-- Experimento: bobina com esfera condutora, eletrodos e painel de controle.
	local base=V(0,2,-18)
	block("CoilBase",V(1,5,5),base+V(0,0.5,0),Color3.fromRGB(58,62,70),Enum.Material.Metal,Enum.PartType.Cylinder).CFrame=CFrame.new(origin+base+V(0,0.5,0))*CFrame.Angles(0,0,math.pi/2)
	block("Coil",V(6,1.6,1.6),base+V(0,4,0),Color3.fromRGB(184,108,58),Enum.Material.Metal,Enum.PartType.Cylinder).CFrame=CFrame.new(origin+base+V(0,4,0))*CFrame.Angles(0,0,math.pi/2)
	local sphere=block("CoilSphere",V(3.2,3.2,3.2),base+V(0,8,0),Color3.fromRGB(196,206,214),Enum.Material.Metal,Enum.PartType.Ball)
	local electrodes={}
	for _,x in {-7,7} do
		block("ElectrodePole",V(0.4,6,0.4),base+V(x,3,1),Color3.fromRGB(70,74,82),Enum.Material.Metal)
		table.insert(electrodes,block("ElectrodeTip",V(1,1,1),base+V(x,6.4,1),Color3.fromRGB(196,206,214),Enum.Material.Metal,Enum.PartType.Ball).Position)
	end
	block("ControlDesk",V(5,2.6,2),V(12,3.3,-14),Color3.fromRGB(88,92,100),Enum.Material.Metal)
	local monitor=block("ControlMonitor",V(3,2,0.2),V(12,5.8,-14.6),Color3.fromRGB(90,190,220),Enum.Material.Neon)
	local glow=Instance.new("PointLight") glow.Color=Color3.fromRGB(150,200,255) glow.Range=22 glow.Brightness=1 glow.Parent=sphere
	local arcs: {Part}={}
	for i=1,10 do local arc=Art.part(scene,"Arc"..i,V(0.12,0.12,1),CFrame.new(origin),Color3.fromRGB(190,220,255),Enum.Material.Neon) arc.CastShadow=false arc.Transparency=1 arcs[i]=arc end
	local lamps: {{part: BasePart, light: Light}}={}
	for _,x in {-22,0,22} do for _,z in {-12,6,24} do
		local lamp=block("CeilingLamp",V(8,0.3,2),V(x,25.4,z),Color3.fromRGB(255,250,232),Enum.Material.Neon)
		local light=Instance.new("SpotLight") light.Face=Enum.NormalId.Bottom light.Angle=110 light.Range=34 light.Brightness=1.6 light.Color=Color3.fromRGB(255,244,220) light.Parent=lamp
		table.insert(lamps,{part=lamp,light=light})
	end end

	local previews=ReplicatedStorage:FindFirstChild("ClassPreviews")
	local available: {Model}={}
	for _,id in CLASS_ORDER do
		local found=previews and previews:FindFirstChild(id)
		if found and found:IsA("Model") then table.insert(available,found) end
	end
	local function template(index: number): Model?
		local found=previews and previews:FindFirstChild(CLASS_ORDER[(index-1)%#CLASS_ORDER+1])
		if found and found:IsA("Model") then return found end
		return if #available>0 then available[(index-1)%#available+1] else nil
	end
	-- Piso do ginásio: palco (y 2) e degrau (y 1).
	local function schoolGround(p: Vector3): number
		local x,z=p.X-origin.X,p.Z-origin.Z
		if math.abs(x)<=18 and z<=-11 and z>=-25 then return origin.Y+2 end
		if math.abs(x)<=5 and z<-9 and z>-11 then return origin.Y+1 end
		return origin.Y
	end
	local function place(pos: Vector3, yaw: number, advance: number?): CFrame
		return CFrame.new(V(pos.X,0,pos.Z))*CFrame.Angles(0,math.rad(yaw),0)*CFrame.new(0,0,-(advance or 0))
	end
	local coilTarget=origin+base+V(0,0,6)

	-- Público: outros alunos, pais e o professor.
	local crowd: {Actor}={}
	for i,spec in CROWD do
		local source=template(i+1)
		if not source then continue end
		local person=staticClone(source,"Spectator"..i,scene)
		if spec.kind=="adult" or spec.kind=="teacher" then person:ScaleTo(1.06+(i%3)*0.03) else person:ScaleTo(0.9+(i%4)*0.035) end
		Body.relaxArms(person)
		if spec.kind=="teacher" then
			dress(person,Color3.fromRGB(240,242,244),Color3.fromRGB(78,80,88),SHOES[2],nil,true)
		elseif spec.kind=="adult" then
			dress(person,ADULT_SHIRTS[i%#ADULT_SHIRTS+1],ADULT_PANTS[i%#ADULT_PANTS+1],SHOES[i%#SHOES+1])
		else
			dress(person,UNIFORM_SHIRTS[i%#UNIFORM_SHIRTS+1],UNIFORM_PANTS[i%#UNIFORM_PANTS+1],SHOES[i%2+1],if i%3==0 then BAGS[i%#BAGS+1] else nil)
		end
		local body=Body.new(person,true)
		if not body then person:Destroy() continue end
		local pos=origin+spec.p
		table.insert(crowd,{model=person,body=body,pos=pos,yaw=yawTo(pos,coilTarget),phase=i*1.7,cycle=0,spec=spec})
	end
	local byIndex: {[number]: Actor}={}
	for _,actor in crowd do for i,spec in CROWD do if actor.spec==spec then byIndex[i]=actor end end end
	for _,actor in crowd do
		if actor.spec.partner and byIndex[actor.spec.partner] then
			-- Pares conversando: meio virados um para o outro, meio para o experimento.
			local other=byIndex[actor.spec.partner]
			actor.yaw=turnToward(yawTo(actor.pos,coilTarget),yawTo(actor.pos,other.pos),0.7)
		end
	end

	-- Os seis jovens: uniforme na escola; trajes, armas e poderes ao acordar.
	local students: {Actor}={}
	type Waking={model: Model, body: Body.Body, hips: Vector3, yaw: number, faceYaw: number, ground: number, layout: typeof(WAKE_LAYOUT[1]), head: BasePart?, color: Color3, aura: {BasePart}, classId: string}
	local adventurers: {Waking}={}
	local ignore: {Instance}={scene}
	for _,other in game:GetService("Players"):GetPlayers() do if other.Character then table.insert(ignore,other.Character) end end
	for i=1,6 do
		local source=template(i)
		if not source then continue end
		local student=staticClone(source,"Student"..i,scene)
		Body.relaxArms(student)
		dress(student,UNIFORM_SHIRTS[(i-1)%#UNIFORM_SHIRTS+1],UNIFORM_PANTS[(i-1)%#UNIFORM_PANTS+1],SHOES[(i-1)%2+1],if i%2==1 then BAGS[(i+1)//2] else nil)
		local studentBody=Body.new(student,true)
		if studentBody then
			local pos=origin+V((i-3.5)*3.4,0,4+(i%2)*2.6)
			table.insert(students,{model=student,body=studentBody,pos=pos,yaw=yawTo(pos,coilTarget),phase=i*0.9,cycle=0,spec={index=i}})
		end

		local adventurer=staticClone(source,"Adventurer"..i,scene)
		Body.relaxArms(adventurer)
		local body=Body.new(adventurer,true)
		if not body then adventurer:Destroy() continue end
		local layout=WAKE_LAYOUT[i]
		local hips=wakeCenter+layout.offset
		hips=V(hips.X,0,hips.Z)
		local toCenter=wakeCenter-hips
		local faceYaw=math.deg(math.atan2(-toCenter.X,-toCenter.Z))
		local head=adventurer:FindFirstChild("Head")
		local classId=source.Name
		local definition=(Classes :: any)[classId]
		local color=if definition then definition.color else Color3.fromRGB(150,220,255)
		-- Aura dos poderes recém-descobertos: brilho nas duas mãos.
		local aura: {BasePart}={}
		for _=1,2 do
			local orb=Art.part(scene,"PowerAura",V(0.9,0.9,0.9),CFrame.new(origin),color,Enum.Material.Neon,Enum.PartType.Ball)
			orb.CastShadow=false orb.Transparency=1
			local light=Instance.new("PointLight") light.Color=color light.Range=8 light.Brightness=0 light.Shadows=false light.Parent=orb
			local sparks=Instance.new("ParticleEmitter") sparks.Color=ColorSequence.new(color) sparks.LightEmission=1 sparks.Rate=0
			sparks.Lifetime=NumberRange.new(0.3,0.6) sparks.Speed=NumberRange.new(1.5,3) sparks.SpreadAngle=Vector2.new(180,180)
			sparks.Size=NumberSequence.new(0.25,0) sparks.Parent=orb
			table.insert(aura,orb)
		end
		table.insert(adventurers,{model=adventurer,body=body,hips=hips,yaw=layout.yaw,faceYaw=faceYaw,ground=groundY(hips.X,hips.Z,ignore),layout=layout,head=if head and head:IsA("BasePart") then head else nil,color=color,aura=aura,classId=classId})
	end
	local function applyActor(actor: Actor, pose: Body.Pose, advance: number?)
		actor.body:apply(pose,place(actor.pos,actor.yaw,advance),schoolGround(actor.pos))
	end
	for _,actor in crowd do applyActor(actor,POSES.Idle) end
	for _,actor in students do applyActor(actor,POSES.Idle) end
	local function wakePlace(actor: Waking, yaw: number, advance: number): CFrame
		return CFrame.new(actor.hips)*CFrame.Angles(0,math.rad(yaw),0)*CFrame.new(0,0,-advance)
	end
	for _,actor in adventurers do actor.body:apply(POSES.Lying,wakePlace(actor,actor.yaw,0),actor.ground) end
	local wake=V(wakeCenter.X,groundY(wakeCenter.X,wakeCenter.Z,ignore),wakeCenter.Z)

	local camera=workspace.CurrentCamera
	local savedFov=if camera then camera.FieldOfView else 70
	local fade=Instance.new("ColorCorrectionEffect") fade.Name="PrologueFade" fade.Parent=camera
	local function darkness(amount: number, flash: number?)
		local a=math.clamp(amount,0,1)
		fade.TintColor=Color3.new(1,1,1):Lerp(Color3.new(0,0,0),a)
		fade.Brightness=-0.35*a+(flash or 0)
	end
	local function lightsOn(on: boolean)
		for _,lamp in lamps do
			lamp.light.Enabled=on
			lamp.part.Color=if on then Color3.fromRGB(255,250,232) else Color3.fromRGB(70,70,74)
			lamp.part.Material=if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end
	local function drawArcs(intensity: number)
		local top=origin+base+V(0,8,0)
		for i,arc in arcs do
			if intensity<=0 or math.random()>intensity then arc.Transparency=1 continue end
			local target=if i%3==0 then top+V(math.random(-8,8),math.random(-4,8),math.random(-4,10)*intensity) else origin+electrodes[(i%2)+1]
			local mid=(top+target)/2+V(math.random()-0.5,math.random()-0.5,math.random()-0.5)*2.5*intensity
			local a=if i%2==0 then top else mid
			local b=if i%2==0 then mid else target
			arc.Size=V(0.08+0.12*intensity,0.08+0.12*intensity,(b-a).Magnitude)
			arc.CFrame=CFrame.lookAt((a+b)/2,b)
			arc.Transparency=0.15
		end
	end

	-- Desloca um ator pela rota (lista de pontos) com o ciclo de passos; devolve a pose do passo.
	local function stepAlong(actor: Actor, route: {Vector3}, speed: number, dt: number, run: boolean, loop: boolean): (Body.Pose, boolean)
		local data=actor.spec
		data.leg=data.leg or 1
		local target=route[data.leg]
		if not target then return POSES.Idle,true end
		local flat=V(target.X-actor.pos.X,0,target.Z-actor.pos.Z)
		if flat.Magnitude<0.6 then
			data.leg+=1
			if data.leg>#route then
				if loop then data.leg=1 else data.leg=#route+1 return POSES.Idle,true end
			end
			return gait(actor.cycle,if run then 46 else 24,run),false
		end
		local move=flat.Unit*math.min(flat.Magnitude,speed*dt)
		actor.pos+=move
		actor.yaw=turnToward(actor.yaw,yawTo(V(0,0,0),flat),dt*8)
		actor.cycle+=dt*speed*(if run then 1.25 else 1.7)
		return gait(actor.cycle,if run then 46 else 24,run),false
	end

	local function relRoute(points: {Vector3}): {Vector3}
		local result={}
		for _,p in points do table.insert(result,origin+p) end
		return result
	end

	-- Página 1: feira viva.
	local function animateFair(elapsed: number, dt: number)
		for _,actor in crowd do
			local spec=actor.spec
			local pose: Body.Pose=POSES.Idle
			if spec.act=="talk" and spec.partner then
				-- Revezam a fala a cada ~3 s.
				local turn=math.floor((elapsed+(if spec.speaks then 0 else 3))/3)%2==0
				pose=Body.add(POSES.Idle,talking(elapsed,actor.phase,turn))
			elseif spec.act=="point" then
				local cycle=(elapsed+actor.phase)%6
				local w=if cycle<2.5 then smooth(cycle/0.6)*(1-smooth((cycle-1.9)/0.6)) else 0
				pose=Body.blend(POSES.Idle,POSES.Point,w)
			elseif spec.act=="walk" and spec.route then
				spec.routeAbs=spec.routeAbs or relRoute(spec.route)
				pose=stepAlong(actor,spec.routeAbs,4.5,dt,false,true)
			elseif spec.act=="teach" then
				-- Professor alterna explicar ao público e mostrar a esfera.
				local show=math.sin(elapsed*0.8)>0.2
				actor.yaw=turnToward(actor.yaw,if show then yawTo(actor.pos,origin+base) else yawTo(actor.pos,origin+V(0,0,12)),dt*3)
				pose=if show then Body.blend(POSES.Idle,POSES.Palm,0.85) else Body.add(POSES.Idle,talking(elapsed,1,true))
			end
			applyActor(actor,Body.add(pose,alive(elapsed,actor.phase)))
		end
		for _,actor in students do
			local i=actor.spec.index
			local pose: Body.Pose=POSES.Idle
			if i==1 or i==2 then
				local other=students[if i==1 then 2 else 1]
				if other then actor.yaw=turnToward(actor.yaw,turnToward(yawTo(actor.pos,coilTarget),yawTo(actor.pos,other.pos),0.5),dt*2) end
				pose=Body.add(POSES.Idle,talking(elapsed,actor.phase,math.floor(elapsed/2.5+i)%2==0))
			elseif i==3 then
				local cycle=elapsed%5
				pose=Body.blend(POSES.Idle,POSES.Point,smooth(cycle/0.5)*(1-smooth((cycle-2.2)/0.5)))
			end
			applyActor(actor,Body.add(pose,alive(elapsed,actor.phase)))
		end
	end

	-- Página 2: sobrecarga, pânico, os seis tentam parar o experimento, clarão e desmaio.
	local function animateDisaster(elapsed: number, dt: number)
		for _,actor in crowd do
			local spec=actor.spec
			local startle=smooth((elapsed-1.6-(actor.phase%1)*0.5)/0.5)
			local flee=elapsed-2.8-(actor.phase%1.3)
			local pose: Body.Pose
			if flee>0 then
				if not spec.escape then
					local door=if actor.pos.X<origin.X then DOORS[1] else DOORS[2]
					local list={}
					if schoolGround(actor.pos)>origin.Y then table.insert(list,origin+V(actor.pos.X-origin.X,0,-8)) end
					table.insert(list,origin+door) table.insert(list,origin+door+V(0,0,14))
					spec.escape=list spec.leg=1
				end
				pose=stepAlong(actor,spec.escape,11+(actor.phase%2),dt,true,false)
			else
				pose=Body.blend(POSES.Idle,POSES.Protect,startle)
				if startle>0 then actor.yaw=turnToward(actor.yaw,yawTo(actor.pos,origin+base),dt*4) end
			end
			applyActor(actor,Body.add(pose,alive(elapsed,actor.phase)))
		end
		for _,actor in students do
			local i=actor.spec.index
			local spot=origin+STOP_SPOTS[i]
			local runStart=2.4+i*0.12
			local faint=elapsed-7.4-i*0.14
			local pose: Body.Pose
			if faint>0 then
				-- Os joelhos cedem e o corpo tomba.
				local from=actor.from or POSES.Reach
				actor.from=from
				pose=if faint<0.5 then Body.blend(from,POSES.Slump,smooth(faint/0.5)) else Body.blend(POSES.Slump,POSES.Lying,smooth((faint-0.5)/0.7))
			elseif elapsed>runStart then
				local list=actor.spec.run
				if not list then
					list={origin+V(STOP_SPOTS[i].X*0.6,0,-8.5),spot}
					actor.spec.run=list actor.spec.leg=1
				end
				local step,arrived=stepAlong(actor,list,12,dt,true,false)
				if arrived then
					actor.yaw=turnToward(actor.yaw,yawTo(actor.pos,origin+base),dt*6)
					-- Lutando contra a máquina: braços estendidos, tremendo.
					local shake=V(math.sin(elapsed*31+i)*4,math.sin(elapsed*23+i)*3,0)
					pose=Body.add(if i==1 then Body.blend(POSES.Reach,POSES.Hands,0.5) else POSES.Reach,{RightUpperArm=shake,LeftUpperArm=-shake,Head=V(0,math.sin(elapsed*5+i)*12,0)})
				else
					pose=step
				end
				actor.from=pose
			else
				local startle=smooth((elapsed-1.5)/0.4)
				pose=Body.blend(POSES.Idle,POSES.Protect,startle*0.7)
				-- Os seis se entreolham antes de correr para o palco.
				pose=Body.add(pose,{Head=V(0,math.sin(elapsed*6+i)*30*startle,0)})
			end
			applyActor(actor,Body.add(pose,if faint>0 then {} else alive(elapsed,actor.phase)))
		end
	end

	-- Despertar: cada um se levanta no seu ritmo, com o tronco conduzindo cabeça e braços.
	local function animateGetUp(elapsed: number)
		for _,actor in adventurers do
			local layout=actor.layout
			local local_=(elapsed-layout.delay)*layout.speed
			local body,advance=layeredGetUp(local_)
			if layout.mirror then body=mirror(body) end
			local breathe=math.sin(elapsed*1.6+layout.delay)
			body=Body.add(body,{UpperTorso=V(breathe*1.8,0,0)})
			if local_>2 and local_<GET_UP_END then
				-- Tontura: cabeça pende e balança devagar.
				body=Body.add(body,{Head=V(math.sin(elapsed*0.9+layout.delay)*6,math.sin(elapsed*1.3+layout.delay*2)*14,0)})
			elseif local_>=GET_UP_END then
				body=Body.add(body,{Head=V(0,math.sin(elapsed*0.8+layout.delay)*22,0)})
			end
			actor.body:apply(body,wakePlace(actor,actor.yaw,advance),actor.ground)
		end
	end
	local function showAura(actor: Waking, strength: number, elapsed: number)
		local hands={actor.model:FindFirstChild("RightHand"),actor.model:FindFirstChild("LeftHand")}
		for k,orb in actor.aura do
			local hand=hands[k]
			if hand and hand:IsA("BasePart") and strength>0 then
				local pulse=0.5+0.5*math.sin(elapsed*9+k)
				orb.CFrame=hand.CFrame
				orb.Size=V(1,1,1)*(0.7+0.5*pulse*strength)
				orb.Transparency=1-strength*(0.45+0.25*pulse)
				local light=orb:FindFirstChildOfClass("PointLight") if light then light.Brightness=strength*2.5 end
				local sparks=orb:FindFirstChildOfClass("ParticleEmitter") if sparks then sparks.Rate=strength*40 end
			else
				orb.Transparency=1
				local light=orb:FindFirstChildOfClass("PointLight") if light then light.Brightness=0 end
				local sparks=orb:FindFirstChildOfClass("ParticleEmitter") if sparks then sparks.Rate=0 end
			end
		end
	end
	-- Confusão e descoberta dos poderes: viram-se para o grupo e alternam gestos.
	local function animateConfusion(elapsed: number)
		for _,actor in adventurers do
			local turn=smooth(elapsed/1.6)
			local yaw=turnToward(actor.yaw,actor.faceYaw,turn)
			local gestures=actor.layout.gestures
			local slot=3.4
			local index=math.floor((elapsed+actor.layout.delay)/slot)
			local within=(elapsed+actor.layout.delay)%slot
			local name=gestures[index%#gestures+1]
			local current=POSES[name]
			local previous=POSES[gestures[(index-1)%#gestures+1]]
			local body=Body.blend(previous,current,smooth(within/0.8))
			if actor.layout.mirror then body=mirror(body) end
			local look=math.sin(elapsed*0.9+actor.layout.delay*1.7)
			local extra: Body.Pose={
				Head=V(0,look*(if name=="LookAround" then 48 else 14),0),
				UpperTorso=V(math.sin(elapsed*1.6+actor.layout.delay)*1.5,look*8,0),
				Root=V(0,0,math.sin(elapsed*0.7+actor.layout.delay)*0.6),
			}
			if name=="Guard" then
				-- Socos curtos alternados: o lutador sente a força nos punhos.
				local jab=math.max(0,math.sin(within*7))
				extra.RightUpperArm=V(jab*30,0,0) extra.RightLowerArm=V(-jab*95,0,0)
			end
			body=Body.add(body,extra)
			actor.body:apply(body,wakePlace(actor,yaw,GET_UP[#GET_UP][4]),actor.ground)
			local strength=if POWER_GESTURES[name] then smooth((within-0.4)/0.6)*(1-smooth((within-2.9)/0.5)) else 0
			showAura(actor,strength,elapsed)
		end
	end
	local function headOf(actor: Waking): Vector3
		return if actor.head then actor.head.Position else actor.hips+V(0,actor.ground+5,0)
	end
	local function closeUp(actor: Waking, side: number, t: number): CFrame
		local head=headOf(actor)
		local yaw=math.rad(actor.faceYaw)
		local forward=V(-math.sin(yaw),0,-math.cos(yaw))
		local right=V(math.cos(yaw),0,-math.sin(yaw))
		local eye=head+forward*(4.6-1*t)+right*side*(1.8-0.4*t)+V(0,-0.2,0)
		return CFrame.lookAt(eye,head+V(0,-0.6,0))
	end

	local page=1 local elapsed=0 local stopped=false
	local connection: RBXScriptConnection?=nil
	local function stop()
		if stopped then return end stopped=true
		if connection then connection:Disconnect() end
		scene:Destroy() fade:Destroy()
		if camera then camera.FieldOfView=savedFov end
	end
	local function setPage(index: number)
		page=index elapsed=0
		if index>Cinematic.pageCount then stop() onFinish() else onPage(index) end
	end
	onPage(1)
	connection=RunService.RenderStepped:Connect(function(frameDt)
		if stopped then return end
		-- O relógio segue o tempo real; só o passo de movimento é limitado (sem saltos em FPS baixo).
		elapsed+=frameDt
		local dt=math.min(frameDt,1/20)
		if elapsed>=PAGE_SECONDS[page] then setPage(page+1) return end
		if not camera then return end
		camera.CameraType=Enum.CameraType.Scriptable
		local t=elapsed/PAGE_SECONDS[page]
		if page==1 then
			darkness(0) lightsOn(true)
			camera.FieldOfView=58
			camera.CFrame=CFrame.lookAt(origin+V(20-12*t,11-3*t,34-8*t),origin+V(-2*t,5,-8))
			drawArcs(0.25+0.15*math.sin(elapsed*3)) glow.Brightness=1+0.5*math.sin(elapsed*4)
			animateFair(elapsed,dt)
		elseif page==2 then
			camera.FieldOfView=60
			local shake=if elapsed>1.5 and elapsed<7.6 then V(math.random()-0.5,math.random()-0.5,0)*(0.12+0.25*math.min(1,(elapsed-1.5)/4)) else Vector3.zero
			if elapsed<2.6 then
				-- A bobina dispara: público assustado.
				camera.CFrame=CFrame.lookAt(origin+V(-12,7,14)+shake,origin+V(2,5,-8))
			elseif elapsed<5.4 then
				-- Do palco: o público foge pelas portas, os seis correm na direção contrária.
				local u=(elapsed-2.6)/2.8
				camera.CFrame=CFrame.lookAt(origin+V(-6+4*u,9,-9)+shake,origin+V(0,3,10-4*u))
			elseif elapsed<7.6 then
				-- Os seis na máquina.
				local u=(elapsed-5.4)/2.2
				camera.CFrame=CFrame.lookAt(origin+V(-11+3*u,6,-3-2*u)+shake,origin+V(1,5,-15))
			else
				local u=(elapsed-7.6)/3.4
				camera.CFrame=CFrame.lookAt(origin+V(-5,9-2*u,0-3*u),origin+V(1,2,-14))
			end
			local surge=math.min(1,0.4+elapsed/5)
			if elapsed<7.4 then
				drawArcs(surge)
				sphere.Color=Color3.fromRGB(196,206,214):Lerp(Color3.fromRGB(230,245,255),math.min(1,elapsed/4))
				sphere.Material=if elapsed>1.2 then Enum.Material.Neon else Enum.Material.Metal
				glow.Brightness=1+elapsed*1.6
				local flicker=elapsed>1.4 and math.random()<0.35+elapsed*0.04
				lightsOn(not flicker) monitor.Color=if flicker then Color3.fromRGB(200,40,40) else Color3.fromRGB(90,190,220)
				darkness(if flicker then 0.25 else 0)
			else
				-- Clarão final e apagão.
				local after=elapsed-7.4
				drawArcs(0) lightsOn(false) monitor.Color=Color3.fromRGB(12,14,16) monitor.Material=Enum.Material.SmoothPlastic
				local flash=math.max(0,1-after/0.35)
				sphere.Material=if flash>0 then Enum.Material.Neon else Enum.Material.Metal
				sphere.Color=if flash>0 then Color3.new(1,1,1) else Color3.fromRGB(60,64,70)
				glow.Brightness=10*flash+math.max(0,1.5-after*0.6)
				darkness(math.clamp(0.35+after*0.2,0,1),flash*0.9)
			end
			animateDisaster(elapsed,dt)
		elseif page==3 then
			if t<0.45 then
				darkness(1)
				camera.CFrame=CFrame.lookAt(origin+V(0,12,10),origin+V(0,0,4))
			else
				local reveal=(t-0.45)/0.55
				darkness(1-reveal*reveal)
				camera.FieldOfView=55
				camera.CFrame=CFrame.lookAt(wake+V(1.5,12-3*reveal,4),wake)
			end
			for _,actor in adventurers do
				actor.body:apply(Body.add(POSES.Lying,{UpperTorso=V(math.sin(elapsed*1.4+actor.layout.delay)*1.2,0,0)}),wakePlace(actor,actor.yaw,0),actor.ground)
			end
		elseif page==4 then
			darkness(0)
			camera.FieldOfView=52
			local angle=math.rad(-45+85*smooth(t))
			camera.CFrame=CFrame.lookAt(wake+V(math.sin(angle)*13.5,2.6+2.6*t,math.cos(angle)*13.5),wake+V(0,0.9+1.7*t,0))
			animateGetUp(elapsed)
		else
			darkness(0)
			animateConfusion(elapsed)
			if elapsed<3.6 and adventurers[1] then
				camera.FieldOfView=42
				camera.CFrame=closeUp(adventurers[1],-1,elapsed/3.6)
			elseif elapsed<7 and adventurers[4] then
				camera.FieldOfView=44
				camera.CFrame=closeUp(adventurers[4],1,(elapsed-3.6)/3.4)
			else
				local ease=smooth((elapsed-7)/4)
				camera.FieldOfView=48+18*ease
				camera.CFrame=CFrame.lookAt(wake+V(3+11*ease,3+15*ease,10+26*ease),wake+V(0,2.5+3*ease,-26*ease))
			end
		end
	end)
	return {stop=stop,next=function() if not stopped then setPage(page+1) end end}
end
return Cinematic
