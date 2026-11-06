--!strict
-- Prólogo 3D local em cinco cenas: feira de ciências na escola, apagão, silêncio, despertar
-- e confusão em Aetherion já com roupas de aventureiro. Tudo é criado só no cliente e destruído
-- ao final; não altera o mundo do servidor nem o progresso.
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Art=require(script.Parent.Art)
local Body=require(script.Parent.CinematicBody)
local V=Vector3.new
local Cinematic={}
-- Duração de cada página (escola, apagão, silêncio, despertar, confusão).
local PAGE_SECONDS={8,8,7,11,11}
Cinematic.pageCount=#PAGE_SECONDS
local origin=V(0,2000,0)
-- Centro do despertar, ao lado da Entrada de Lúmen (spawn em z 32), com vista para o vale ao norte.
local wakeCenter=V(0,0,20)

local SKIN_PARTS={Head=true,LeftLowerArm=true,RightLowerArm=true,LeftHand=true,RightHand=true}
local SHIRT_PARTS={UpperTorso=true,LeftUpperArm=true,RightUpperArm=true}
local PANTS_PARTS={LowerTorso=true,LeftUpperLeg=true,RightUpperLeg=true,LeftLowerLeg=true,RightLowerLeg=true}
local SHOE_PARTS={LeftFoot=true,RightFoot=true}
local CLASS_ORDER={"Guardian","Explorer","Artificer"}
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
	-- Gola/cachecol de aventureiro do rig gerado não faz parte da roupa comum.
	local collar=actor:FindFirstChild("RBX_RIGID_neck")
	if collar and collar:IsA("BasePart") then collar.Transparency=1 end
	for _,part in actor:GetDescendants() do
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
	if bag then
		Art.part(actor,"SchoolBackpack",V(1.35,1.6,0.75),torso.CFrame*CFrame.new(0,-0.05,0.72),bag,Enum.Material.Fabric,Enum.PartType.Ball)
		Art.part(actor,"BackpackPocket",V(0.9,0.7,0.4),torso.CFrame*CFrame.new(0,-0.4,1.05),bag:Lerp(Color3.new(0,0,0),0.2),Enum.Material.Fabric,Enum.PartType.Ball)
		for _,x in {-0.45,0.45} do
			Art.part(actor,"BackpackStrap",V(0.16,1.1,0.12),torso.CFrame*CFrame.new(x,-0.1,-0.5),bag:Lerp(Color3.new(0,0,0),0.35),Enum.Material.Fabric)
		end
	end
	if labCoat then
		-- Jaleco do professor: barra branca abaixo do tronco.
		Art.part(actor,"LabCoatTail",V(1.9,1.7,1.05),torso.CFrame*CFrame.new(0,-1.55,0.02),Color3.fromRGB(240,242,244),Enum.Material.SmoothPlastic)
	end
end

-- Distância do pivô até a sola: usada para deitar o corpo girando pelos pés.
local function footOffset(actor: Model): number
	local box,size=actor:GetBoundingBox()
	return actor:GetPivot().Y-(box.Y-size.Y/2)
end

type Standing={model: Model, feet: Vector3, facing: CFrame, offset: number, side: number, phase: number}
-- Corpo inteiro (escola). fall=0 em pé; fall=1 deitado. side escolhe cair de costas ou de lado.
local function pose(actor: Standing, fall: number, sway: number)
	local angle=fall*math.pi/2
	local tilt=if actor.side==0 then CFrame.Angles(angle,0,0) else CFrame.Angles(angle*0.85,0,angle*0.25*actor.side)
	local lift=V(0,0.55*math.sin(angle),0)
	actor.model:PivotTo(CFrame.new(actor.feet+lift)*actor.facing*tilt*CFrame.Angles(0,0,sway)*CFrame.new(0,actor.offset,0))
end

local function groundY(x: number, z: number, ignore: {Instance}): number
	local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances=ignore
	local hit=workspace:Raycast(V(x,300,z),V(0,-600,0),params)
	return if hit then hit.Position.Y else 0.3
end

local function smooth(t: number): number
	local x=math.clamp(t,0,1)
	return x*x*(3-2*x)
end

-- Poses do despertar (ver convenções em CinematicBody). Ângulos de braço calibrados por busca
-- numérica nos três rigs: mão na testa, mãos à frente do peito e mão no joelho.
local function with(...: Body.Pose): Body.Pose
	local result: Body.Pose={}
	for _,pose in {...} do for key,value in pose do result[key]=value end end
	return result
end
local RIGHT_HEAD={RightUpperArm=V(110,0,12),RightLowerArm=V(85,0,-52)}
local LEFT_HEAD={LeftUpperArm=V(110,0,-12),LeftLowerArm=V(85,0,52)}
local POSES: {[string]: Body.Pose}={
	Lying={Root=V(90,0,0),Head=V(0,22,0),LeftUpperArm=V(0,0,-16),RightUpperArm=V(0,0,16)},
	-- Ainda deitado: cabeça vira, um joelho dobra, a mão sobe ao rosto.
	Stir=with({Root=V(90,0,0),Head=V(0,-18,0),RightUpperLeg=V(40,0,4),RightLowerLeg=V(-70,0,0),LeftUpperArm=V(0,0,-20)},RIGHT_HEAD),
	-- Apoiado nos cotovelos: tronco a meio caminho, pernas ainda no chão.
	Prop={Root=V(55,0,0),UpperTorso=V(-12,0,0),Head=V(-18,10,0),LeftUpperLeg=V(35,0,-4),RightUpperLeg=V(60,0,6),RightLowerLeg=V(-60,0,0),
		LeftUpperArm=V(-45,0,-12),LeftLowerArm=V(45,0,0),RightUpperArm=V(-45,0,12),RightLowerArm=V(45,0,0)},
	-- Sentado, tonto, mão na cabeça.
	Sit=with({UpperTorso=V(6,0,0),Head=V(-16,0,-6),LeftUpperLeg=V(88,0,-4),LeftLowerLeg=V(-6,0,0),RightUpperLeg=V(135,0,6),RightLowerLeg=V(-130,0,0),
		LeftUpperArm=V(-35,0,-10),LeftLowerArm=V(10,0,0)},RIGHT_HEAD),
	-- Um joelho no chão, mão no joelho da frente, a outra ainda na cabeça.
	Kneel=with({UpperTorso=V(-18,0,0),Head=V(-8,14,6),RightUpperLeg=V(88,0,4),RightLowerLeg=V(-88,0,0),LeftUpperLeg=V(4,0,-3),LeftLowerLeg=V(-88,0,0),
		RightUpperArm=V(38,0,-6),RightLowerArm=V(4,0,-4)},LEFT_HEAD),
	Stand={UpperTorso=V(-4,0,0),Head=V(-6,0,0)},
	-- Gestos de confusão (de pé).
	HeadHand=with({Head=V(-14,0,-6),UpperTorso=V(-3,0,0)},RIGHT_HEAD),
	Hands={Head=V(-36,0,0),UpperTorso=V(-6,0,0),LeftUpperArm=V(40,0,-6),LeftLowerArm=V(62,0,48),RightUpperArm=V(40,0,6),RightLowerArm=V(62,0,-48)},
	Clothes={Head=V(-40,-12,0),UpperTorso=V(-8,0,0),LeftUpperArm=V(12,0,-34),LeftLowerArm=V(20,0,0),RightUpperArm=V(12,0,34),RightLowerArm=V(20,0,0)},
	Shrug={Head=V(4,0,8),LeftUpperArm=V(10,0,-24),LeftLowerArm=V(75,0,0),RightUpperArm=V(10,0,24),RightLowerArm=V(75,0,0)},
	LookAround={Head=V(6,0,0),UpperTorso=V(2,0,0)},
}
-- Sequência para se levantar: {pose, duração da transição até ela, tempo parado nela, avanço do quadril}.
local GET_UP={
	{"Lying",0,0.6,0},{"Stir",0.8,0.5,0},{"Prop",0.9,0.3,0.1},{"Sit",0.8,0.9,0.25},
	{"Kneel",1.0,0.4,0.95},{"Stand",1.1,0,1.35},
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

-- Onde cada um cai no vale (deslocamento do quadril, rumo em graus) e a ordem dos gestos de confusão.
local WAKE_LAYOUT={
	{offset=V(-4.6,0,1.5),yaw=25,gestures={"HeadHand","LookAround","Shrug"},delay=0.2},
	{offset=V(-0.8,0,-3.2),yaw=-40,gestures={"Hands","LookAround","Clothes"},delay=1.3},
	{offset=V(3.6,0,-0.4),yaw=110,gestures={"LookAround","HeadHand","Shrug"},delay=0.7},
	{offset=V(0.6,0,3.6),yaw=200,gestures={"Clothes","LookAround","HeadHand"},delay=2.1},
	{offset=V(-3.2,0,-4.8),yaw=-120,gestures={"Shrug","Hands","LookAround"},delay=1.7},
	{offset=V(4.4,0,4.4),yaw=160,gestures={"LookAround","Clothes","Hands"},delay=2.6},
}

-- Público da feira: posição (relativa ao ginásio), para onde olha e tipo de pessoa.
local CROWD={
	{p=V(-10.5,0,11.5),kind="student"},{p=V(-7,0,13.8),kind="adult"},{p=V(-3.4,0,11.2),kind="student"},
	{p=V(0.4,0,13.6),kind="adult"},{p=V(3.9,0,11.4),kind="student"},{p=V(7.6,0,13.9),kind="student"},
	{p=V(11,0,11.6),kind="adult"},{p=V(-14,0,3.4),kind="student"},{p=V(-15.2,0,7.6),kind="adult"},
	{p=V(14.2,0,2.6),kind="adult"},{p=V(15.4,0,7),kind="student"},
	{p=V(-25.5,0,7),kind="student",look=V(-30,0,4)},{p=V(25.5,0,17.2),kind="adult",look=V(30,0,20)},
	{p=V(8.6,2,-12.8),kind="teacher",look=V(0,2,-6)},
}

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
	block("FrontWall",V(80,26,1),V(0,13,40),wall,Enum.Material.Concrete)
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
	-- Bancadas de outros projetos nas laterais.
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
	for i=1,8 do local arc=Art.part(scene,"Arc"..i,V(0.12,0.12,1),CFrame.new(origin),Color3.fromRGB(190,220,255),Enum.Material.Neon) arc.CastShadow=false arc.Transparency=1 arcs[i]=arc end
	-- Luminárias do teto: apagam no blecaute.
	local lamps: {{part: BasePart, light: Light}}={}
	for _,x in {-22,0,22} do for _,z in {-12,6,24} do
		local lamp=block("CeilingLamp",V(8,0.3,2),V(x,25.4,z),Color3.fromRGB(255,250,232),Enum.Material.Neon)
		local light=Instance.new("SpotLight") light.Face=Enum.NormalId.Bottom light.Angle=110 light.Range=34 light.Brightness=1.6 light.Color=Color3.fromRGB(255,244,220) light.Parent=lamp
		table.insert(lamps,{part=lamp,light=light})
	end end

	local previews=ReplicatedStorage:FindFirstChild("ClassPreviews")
	local function template(index: number): Model?
		local found=previews and previews:FindFirstChild(CLASS_ORDER[(index-1)%3+1])
		return if found and found:IsA("Model") then found else nil
	end

	-- Público: outros alunos, pais e o professor que opera o experimento.
	local crowd: {Standing}={}
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
		local feet=origin+spec.p
		local target=origin+(spec.look or V(base.X,spec.p.Y,base.Z+6))
		table.insert(crowd,{model=person,feet=feet,facing=CFrame.lookAt(feet,V(target.X,feet.Y,target.Z)).Rotation,offset=footOffset(person),side=0,phase=i*1.7})
	end

	-- Os seis jovens: uniforme na escola; roupas de aventureiro ao acordar.
	local students: {Standing}={}
	type Waking={model: Model, body: Body.Body, hips: Vector3, yaw: number, faceYaw: number, ground: number, layout: typeof(WAKE_LAYOUT[1]), head: BasePart?}
	local adventurers: {Waking}={}
	local ignore: {Instance}={scene}
	for _,other in game:GetService("Players"):GetPlayers() do if other.Character then table.insert(ignore,other.Character) end end
	for i=1,6 do
		local source=template(i)
		if not source then continue end
		local student=staticClone(source,"Student"..i,scene)
		Body.relaxArms(student)
		dress(student,UNIFORM_SHIRTS[(i-1)%#UNIFORM_SHIRTS+1],UNIFORM_PANTS[(i-1)%#UNIFORM_PANTS+1],SHOES[(i-1)%2+1],if i%2==1 then BAGS[(i+1)//2] else nil)
		local feet=origin+V((i-3.5)*3.4,0,4+(i%2)*2.6)
		table.insert(students,{model=student,feet=feet,facing=CFrame.lookAt(feet,V(origin.X+base.X,feet.Y,origin.Z+base.Z)).Rotation,offset=footOffset(student),side=({0,1,-1})[i%3+1],phase=i*0.9})

		local adventurer=staticClone(source,"Adventurer"..i,scene)
		Body.relaxArms(adventurer)
		local body=Body.new(adventurer,true)
		if not body then adventurer:Destroy() continue end
		local layout=WAKE_LAYOUT[i]
		local hips=wakeCenter+layout.offset
		hips=V(hips.X,0,hips.Z)
		-- Ao final todos se viram para o centro do grupo.
		local toCenter=wakeCenter-hips
		local faceYaw=math.deg(math.atan2(-toCenter.X,-toCenter.Z))
		local head=adventurer:FindFirstChild("Head")
		table.insert(adventurers,{model=adventurer,body=body,hips=hips,yaw=layout.yaw,faceYaw=faceYaw,ground=groundY(hips.X,hips.Z,ignore),layout=layout,head=if head and head:IsA("BasePart") then head else nil})
	end
	for _,actor in crowd do pose(actor,0,0) end
	for _,actor in students do pose(actor,0,0) end
	local function place(actor: Waking, yaw: number, advance: number): CFrame
		local rot=CFrame.Angles(0,math.rad(yaw),0)
		return CFrame.new(actor.hips)*rot*CFrame.new(0,0,-advance)
	end
	for _,actor in adventurers do actor.body:apply(POSES.Lying,place(actor,actor.yaw,0),actor.ground) end
	local wake=V(wakeCenter.X,groundY(wakeCenter.X,wakeCenter.Z,ignore),wakeCenter.Z)

	local camera=workspace.CurrentCamera
	local savedFov=if camera then camera.FieldOfView else 70
	-- Escurecimento só do 3D: o texto do prólogo continua legível por cima.
	local fade=Instance.new("ColorCorrectionEffect") fade.Name="PrologueFade" fade.Parent=camera
	local function darkness(amount: number)
		local a=math.clamp(amount,0,1)
		fade.TintColor=Color3.new(1,1,1):Lerp(Color3.new(0,0,0),a)
		fade.Brightness=-0.35*a
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
			local target=if i%3==0 then top+V(math.random(-6,6),math.random(-4,6),math.random(-4,4)) else origin+electrodes[(i%2)+1]
			local mid=(top+target)/2+V(math.random()-0.5,math.random()-0.5,math.random()-0.5)*2.5*intensity
			local a=if i%2==0 then top else mid
			local b=if i%2==0 then mid else target
			arc.Size=V(0.08+0.1*intensity,0.08+0.1*intensity,(b-a).Magnitude)
			arc.CFrame=CFrame.lookAt((a+b)/2,b)
			arc.Transparency=0.15
		end
	end
	local function swayCrowd(elapsed: number)
		for _,person in crowd do pose(person,0,math.sin(elapsed*1.1+person.phase)*0.018) end
	end

	-- Despertar: cada um segue a sequência de se levantar no seu tempo, com respiração por cima.
	local function animateGetUp(elapsed: number)
		for _,actor in adventurers do
			local local_=elapsed-actor.layout.delay
			local body,advance=getUpPose(local_)
			body=Body.add(body,{UpperTorso=V(math.sin(elapsed*1.6+actor.layout.delay)*1.5,0,0)})
			-- Ainda tonto: a cabeça balança devagar enquanto está sentado/ajoelhado.
			if local_>2 and local_<GET_UP_END then body=Body.add(body,{Head=V(0,math.sin(elapsed*1.3+actor.layout.delay*2)*14,0)}) end
			actor.body:apply(body,place(actor,actor.yaw,advance),actor.ground)
		end
	end
	-- Confusão: viram-se para o grupo e alternam gestos (olhar em volta, mão na cabeça, mãos, roupas).
	local function animateConfusion(elapsed: number)
		for _,actor in adventurers do
			local turn=smooth(elapsed/1.6)
			local yaw=actor.yaw+(((actor.faceYaw-actor.yaw+180)%360)-180)*turn
			local gestures=actor.layout.gestures
			local slot=3.4
			local index=math.floor((elapsed+actor.layout.delay)/slot)
			local within=(elapsed+actor.layout.delay)%slot
			local current=POSES[gestures[index%#gestures+1]]
			local previous=POSES[gestures[(index-1)%#gestures+1]]
			local body=Body.blend(previous,current,smooth(within/0.7))
			local look=math.sin(elapsed*0.9+actor.layout.delay*1.7)
			body=Body.add(body,{
				Head=V(0,look*(if gestures[index%#gestures+1]=="LookAround" then 48 else 16),0),
				UpperTorso=V(math.sin(elapsed*1.6+actor.layout.delay)*1.5,look*8,0),
				Root=V(0,0,math.sin(elapsed*0.7+actor.layout.delay)*0.6),
			})
			actor.body:apply(body,place(actor,yaw,GET_UP[#GET_UP][4]),actor.ground)
		end
	end
	local function headOf(actor: Waking): Vector3
		return if actor.head then actor.head.Position else actor.hips+V(0,actor.ground+5,0)
	end
	-- Close no rosto: câmera à frente da cabeça, levemente de lado, aproximando devagar.
	local function closeUp(actor: Waking, side: number, t: number): CFrame
		local head=headOf(actor)
		local yaw=math.rad(actor.faceYaw)
		local forward=V(-math.sin(yaw),0,-math.cos(yaw))
		local right=V(math.cos(yaw),0,-math.sin(yaw))
		local eye=head+forward*(4.2-1*t)+right*side*(1.6-0.4*t)+V(0,0.25,0)
		return CFrame.lookAt(eye,head+V(0,-0.15,0))
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
	connection=RunService.RenderStepped:Connect(function(dt)
		if stopped then return end
		elapsed+=dt
		if elapsed>=PAGE_SECONDS[page] then setPage(page+1) return end
		if not camera then return end
		camera.CameraType=Enum.CameraType.Scriptable
		local t=elapsed/PAGE_SECONDS[page]
		if page==1 then
			-- A turma e o público assistem à demonstração; a bobina solta faíscas discretas.
			darkness(0) lightsOn(true)
			camera.FieldOfView=60
			camera.CFrame=CFrame.lookAt(origin+V(18-9*t,10-1.5*t,32-6*t),origin+V(0,6,-12))
			drawArcs(0.25+0.15*math.sin(elapsed*3)) glow.Brightness=1+0.5*math.sin(elapsed*4)
			for _,s in students do pose(s,0,math.sin(elapsed*1.2+s.phase)*0.02) end
			swayCrowd(elapsed)
		elseif page==2 then
			-- Sobrecarga: arcos crescem, luzes piscam e tudo apaga; os seis jovens desmaiam.
			camera.FieldOfView=62
			local shake=if t>0.25 and t<0.6 then V(math.random()-0.5,math.random()-0.5,0)*0.35 else Vector3.zero
			camera.CFrame=CFrame.lookAt(origin+V(-10+4*t,7-2*t,22-6*t)+shake,origin+V(0,4.5,-4))
			if t<0.55 then
				drawArcs(math.min(1,0.4+t*1.4))
				sphere.Color=Color3.fromRGB(196,206,214):Lerp(Color3.fromRGB(220,240,255),t*1.8)
				sphere.Material=if t>0.3 then Enum.Material.Neon else Enum.Material.Metal
				glow.Brightness=1+t*8
				local flicker=t>0.3 and math.random()<0.45
				lightsOn(not flicker) monitor.Color=if flicker then Color3.fromRGB(20,24,28) else Color3.fromRGB(90,190,220)
				darkness(0)
			else
				-- Apagão total: um último clarão da esfera e escuridão crescente.
				drawArcs(0) lightsOn(false) monitor.Color=Color3.fromRGB(12,14,16) monitor.Material=Enum.Material.SmoothPlastic
				local after=(t-0.55)/0.45
				sphere.Material=Enum.Material.Metal sphere.Color=Color3.fromRGB(60,64,70)
				glow.Brightness=math.max(0,6*(1-after*4))
				darkness(0.55+after*0.45)
			end
			swayCrowd(elapsed)
			for _,s in students do
				local fall=math.clamp((t-0.58-s.phase*0.012)/0.22,0,1)
				pose(s,fall*fall,0)
			end
		elseif page==3 then
			-- Escuridão e silêncio; depois a luz volta, agora sob um céu desconhecido.
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
				actor.body:apply(Body.add(POSES.Lying,{UpperTorso=V(math.sin(elapsed*1.4+actor.layout.delay)*1.2,0,0)}),place(actor,actor.yaw,0),actor.ground)
			end
		elseif page==4 then
			-- Despertar: câmera baixa contornando o grupo enquanto cada um se levanta.
			darkness(0)
			camera.FieldOfView=55
			-- Do lado sul, com o vale ao fundo.
			local angle=math.rad(-45+80*smooth(t))
			camera.CFrame=CFrame.lookAt(wake+V(math.sin(angle)*13.5,3+2.5*t,math.cos(angle)*13.5),wake+V(0,1+1.6*t,0))
			animateGetUp(elapsed)
		else
			-- Confusão: closes nos rostos e, por fim, a câmera revela o vale.
			darkness(0)
			animateConfusion(elapsed)
			if elapsed<3.6 and adventurers[1] then
				camera.FieldOfView=42
				-- Mão direita na testa: câmera pelo lado esquerdo para não tapar o rosto.
				camera.CFrame=closeUp(adventurers[1],-1,elapsed/3.6)
			elseif elapsed<7 and adventurers[2] then
				camera.FieldOfView=42
				camera.CFrame=closeUp(adventurers[2],1,(elapsed-3.6)/3.4)
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
