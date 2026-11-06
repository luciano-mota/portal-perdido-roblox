--!strict
-- Prólogo 3D local em quatro cenas: feira de ciências na escola, apagão, desmaio e despertar
-- em Aetherion já com roupas de aventureiro. Tudo é criado só no cliente e destruído ao final;
-- não altera o mundo do servidor nem o progresso.
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Art=require(script.Parent.Art)
local Cinematic={}
Cinematic.pageCount=4
local PAGE_SECONDS=8
local origin=Vector3.new(0,2000,0)
-- Centro do despertar, ao lado da Entrada de Lúmen (spawn em z 32), com vista para o vale ao norte.
local wakeCenter=Vector3.new(0,0,20)

local SKIN_PARTS={Head=true,LeftLowerArm=true,RightLowerArm=true,LeftHand=true,RightHand=true}
local SHIRT_PARTS={UpperTorso=true,LeftUpperArm=true,RightUpperArm=true}
local PANTS_PARTS={LowerTorso=true,LeftUpperLeg=true,RightUpperLeg=true,LeftLowerLeg=true,RightLowerLeg=true}
local SHOE_PARTS={LeftFoot=true,RightFoot=true}
-- Uniforme escolar: camiseta clara com variação discreta, calça escura e tênis.
local SHIRTS={Color3.fromRGB(236,238,240),Color3.fromRGB(214,228,243),Color3.fromRGB(236,238,240),Color3.fromRGB(226,232,222),Color3.fromRGB(236,238,240),Color3.fromRGB(214,228,243)}
local PANTS={Color3.fromRGB(38,52,86),Color3.fromRGB(58,74,110),Color3.fromRGB(34,40,58)}
local SHOES={Color3.fromRGB(232,232,232),Color3.fromRGB(46,46,52)}
local CLASS_ORDER={"Guardian","Explorer","Artificer"}

local function staticClone(template: Model, name: string, parent: Instance): Model
	local actor=template:Clone() actor.Name=name
	for _,item in actor:GetDescendants() do
		if item:IsA("LuaSourceContainer") or item:IsA("BillboardGui") or item:IsA("Humanoid") then item:Destroy()
		elseif item:IsA("BasePart") then item.Anchored=true item.CanCollide=false item.CanTouch=false item.CanQuery=false end
	end
	actor.Parent=parent
	return actor
end

-- O rig de retrato fica em pose A (braços ~38° abertos). Gira cada braço pelo ombro até ficar
-- quase junto ao corpo, levando junto peças de equipamento soldadas ao braço (arma, escudo).
local ARM_PARTS={UpperArm=true,LowerArm=true,Hand=true}
local function relaxArms(actor: Model)
	local torso=actor:FindFirstChild("UpperTorso")
	if not torso or not torso:IsA("BasePart") then return end
	for _,side in {"Left","Right"} do
		local upper=actor:FindFirstChild(side.."UpperArm")
		local hand=actor:FindFirstChild(side.."Hand")
		local shoulder=upper and upper:FindFirstChild(side.."ShoulderRigAttachment")
		if not (upper and hand and shoulder and shoulder:IsA("Attachment") and hand:IsA("BasePart")) then continue end
		local pivot=shoulder.WorldPosition
		local current=torso.CFrame:VectorToObjectSpace(hand.Position-pivot)
		local sign=if side=="Left" then -1 else 1
		local angle=math.atan2(sign*0.32,1)-math.atan2(current.X,-current.Y)
		local rotate=CFrame.new(pivot)*CFrame.fromAxisAngle(torso.CFrame.ZVector,angle)*CFrame.new(-pivot)
		local moving: {[BasePart]: boolean}={}
		for name in ARM_PARTS do local part=actor:FindFirstChild(side..name) if part and part:IsA("BasePart") then moving[part]=true end end
		for _,weld in actor:GetDescendants() do
			if weld:IsA("WeldConstraint") and weld.Part0 and moving[weld.Part0] and weld.Part1 then moving[weld.Part1]=true end
		end
		for part in moving do part.CFrame=rotate*part.CFrame end
	end
end

-- Troca a roupa de aventureiro (textura do rig + equipamento) por uniforme escolar.
local function dressAsStudent(actor: Model, index: number)
	local equipment=actor:FindFirstChild("ClassEquipment")
	if equipment then equipment:Destroy() end
	-- Gola/cachecol de aventureiro do rig gerado não faz parte do uniforme.
	local collar=actor:FindFirstChild("RBX_RIGID_neck")
	if collar and collar:IsA("BasePart") then collar.Transparency=1 end
	for _,part in actor:GetDescendants() do
		if part:IsA("BasePart") and not SKIN_PARTS[part.Name] then
			local color=if SHIRT_PARTS[part.Name] then SHIRTS[index]
				elseif PANTS_PARTS[part.Name] then PANTS[(index-1)%#PANTS+1]
				elseif SHOE_PARTS[part.Name] then SHOES[(index-1)%#SHOES+1]
				else nil
			if color then
				local appearance=part:FindFirstChildOfClass("SurfaceAppearance")
				if appearance then appearance:Destroy() end
				part.Color=color
				part.Material=if PANTS_PARTS[part.Name] then Enum.Material.Fabric else Enum.Material.SmoothPlastic
			end
		end
	end
	-- Mochila escolar em metade do grupo, presa ao tronco.
	local torso=actor:FindFirstChild("UpperTorso")
	if index%2==1 and torso and torso:IsA("BasePart") then
		local bagColor=({Color3.fromRGB(176,64,58),Color3.fromRGB(58,112,160),Color3.fromRGB(214,168,64)})[(index+1)//2]
		Art.part(actor,"SchoolBackpack",Vector3.new(1.35,1.6,0.75),torso.CFrame*CFrame.new(0,-0.05,0.72),bagColor,Enum.Material.Fabric,Enum.PartType.Ball)
		Art.part(actor,"BackpackPocket",Vector3.new(0.9,0.7,0.4),torso.CFrame*CFrame.new(0,-0.4,1.05),bagColor:Lerp(Color3.new(0,0,0),0.2),Enum.Material.Fabric,Enum.PartType.Ball)
		for _,x in {-0.45,0.45} do
			Art.part(actor,"BackpackStrap",Vector3.new(0.16,1.1,0.12),torso.CFrame*CFrame.new(x,-0.1,-0.5),bagColor:Lerp(Color3.new(0,0,0),0.35),Enum.Material.Fabric)
		end
	end
end

-- Distância do pivô até a sola: usada para deitar/levantar o corpo girando pelos pés.
local function footOffset(actor: Model): number
	local box,size=actor:GetBoundingBox()
	return actor:GetPivot().Y-(box.Y-size.Y/2)
end

-- fall=0 em pé; fall=1 deitado. side escolhe cair de costas ou de lado.
local function pose(actor: {model: Model, feet: Vector3, facing: CFrame, offset: number, side: number}, fall: number, sway: number)
	local angle=fall*math.pi/2
	local tilt=if actor.side==0 then CFrame.Angles(angle,0,0) else CFrame.Angles(angle*0.85,0,angle*0.25*actor.side)
	local lift=Vector3.new(0,0.55*math.sin(angle),0)
	actor.model:PivotTo(CFrame.new(actor.feet+lift)*actor.facing*tilt*CFrame.Angles(0,0,sway)*CFrame.new(0,actor.offset,0))
end

local function groundY(x: number, z: number, ignore: {Instance}): number
	local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances=ignore
	local hit=workspace:Raycast(Vector3.new(x,300,z),Vector3.new(0,-600,0),params)
	return if hit then hit.Position.Y else 0.3
end

function Cinematic.start(onPage: (number) -> (),onFinish: () -> ())
	local scene=Instance.new("Model") scene.Name="PortalArrivalCinematic" scene.Parent=workspace
	local function block(name: string,size: Vector3,p: Vector3,color: Color3,material: Enum.Material,shape: Enum.PartType?)
		return Art.part(scene,name,size,CFrame.new(origin+p),color,material,shape)
	end

	-- Ginásio da escola durante a feira de ciências.
	local wall=Color3.fromRGB(214,204,182)
	block("GymFloor",Vector3.new(80,1,80),Vector3.new(0,-0.5,0),Color3.fromRGB(196,150,98),Enum.Material.WoodPlanks)
	block("CourtLine",Vector3.new(60,0.05,0.4),Vector3.new(0,0.03,14),Color3.fromRGB(232,232,226),Enum.Material.SmoothPlastic)
	block("CourtCircle",Vector3.new(0.05,14,14),Vector3.new(0,0.03,14),Color3.fromRGB(232,232,226),Enum.Material.SmoothPlastic,Enum.PartType.Cylinder).CFrame=CFrame.new(origin+Vector3.new(0,0.03,14))*CFrame.Angles(0,0,math.pi/2)
	block("CourtCircleInner",Vector3.new(0.06,13.2,13.2),Vector3.new(0,0.04,14),Color3.fromRGB(196,150,98),Enum.Material.WoodPlanks,Enum.PartType.Cylinder).CFrame=CFrame.new(origin+Vector3.new(0,0.04,14))*CFrame.Angles(0,0,math.pi/2)
	for _,x in {-40,40} do block("SideWall",Vector3.new(1,26,80),Vector3.new(x,13,0),wall,Enum.Material.Concrete) end
	block("BackWall",Vector3.new(80,26,1),Vector3.new(0,13,-26),wall,Enum.Material.Concrete)
	block("FrontWall",Vector3.new(80,26,1),Vector3.new(0,13,40),wall,Enum.Material.Concrete)
	block("Ceiling",Vector3.new(80,1,80),Vector3.new(0,26,0),Color3.fromRGB(150,146,138),Enum.Material.Metal)
	block("WallStripe",Vector3.new(79,2,0.2),Vector3.new(0,4,-25.4),Color3.fromRGB(46,92,150),Enum.Material.SmoothPlastic)
	-- Palco e faixa da feira.
	block("Stage",Vector3.new(36,2,14),Vector3.new(0,1,-18),Color3.fromRGB(122,84,56),Enum.Material.WoodPlanks)
	block("StageStep",Vector3.new(10,1,2),Vector3.new(0,0.5,-10),Color3.fromRGB(122,84,56),Enum.Material.WoodPlanks)
	local banner=block("FairBanner",Vector3.new(30,5,0.2),Vector3.new(0,17,-25.3),Color3.fromRGB(32,78,138),Enum.Material.Fabric)
	local gui=Instance.new("SurfaceGui") gui.Face=Enum.NormalId.Back gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud gui.PixelsPerStud=30 gui.LightInfluence=0.6 gui.Parent=banner
	local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1 label.Font=Enum.Font.GothamBlack
	label.Text="FEIRA DE CIÊNCIAS" label.TextScaled=true label.TextColor3=Color3.fromRGB(250,236,190) label.Parent=gui
	local padding=Instance.new("UIPadding") padding.PaddingTop=UDim.new(0.15,0) padding.PaddingBottom=UDim.new(0.15,0) padding.PaddingLeft=UDim.new(0.05,0) padding.PaddingRight=UDim.new(0.05,0) padding.Parent=label
	-- Bancadas de outros projetos nas laterais.
	for i,x in {-30,-30,30,30} do
		local z=if i%2==1 then 4 else 20
		block("FairTable",Vector3.new(6,0.3,3),Vector3.new(x,3,z),Color3.fromRGB(236,236,232),Enum.Material.SmoothPlastic)
		block("FairTableSkirt",Vector3.new(6,2.8,0.1),Vector3.new(x,1.5,z-1.5),Color3.fromRGB(46,92,150),Enum.Material.Fabric)
		block("FairPoster",Vector3.new(0.1,3.5,4.5),Vector3.new(x+(if x<0 then -9.4 else 9.4),6.5,z),({Color3.fromRGB(226,190,92),Color3.fromRGB(120,180,120),Color3.fromRGB(210,120,110),Color3.fromRGB(130,160,210)})[i],Enum.Material.SmoothPlastic)
		block("FairProject",Vector3.new(1.4,1.4,1.4),Vector3.new(x,3.85,z),({Color3.fromRGB(150,90,60),Color3.fromRGB(80,140,90),Color3.fromRGB(90,90,110),Color3.fromRGB(200,170,80)})[i],Enum.Material.SmoothPlastic,Enum.PartType.Ball)
	end
	-- Experimento: bobina com esfera condutora, eletrodos e painel de controle.
	local base=Vector3.new(0,2,-18)
	block("CoilBase",Vector3.new(1,5,5),base+Vector3.new(0,0.5,0),Color3.fromRGB(58,62,70),Enum.Material.Metal,Enum.PartType.Cylinder).CFrame=CFrame.new(origin+base+Vector3.new(0,0.5,0))*CFrame.Angles(0,0,math.pi/2)
	block("Coil",Vector3.new(6,1.6,1.6),base+Vector3.new(0,4,0),Color3.fromRGB(184,108,58),Enum.Material.Metal,Enum.PartType.Cylinder).CFrame=CFrame.new(origin+base+Vector3.new(0,4,0))*CFrame.Angles(0,0,math.pi/2)
	local sphere=block("CoilSphere",Vector3.new(3.2,3.2,3.2),base+Vector3.new(0,8,0),Color3.fromRGB(196,206,214),Enum.Material.Metal,Enum.PartType.Ball)
	local electrodes={}
	for _,x in {-7,7} do
		block("ElectrodePole",Vector3.new(0.4,6,0.4),base+Vector3.new(x,3,1),Color3.fromRGB(70,74,82),Enum.Material.Metal)
		table.insert(electrodes,block("ElectrodeTip",Vector3.new(1,1,1),base+Vector3.new(x,6.4,1),Color3.fromRGB(196,206,214),Enum.Material.Metal,Enum.PartType.Ball).Position)
	end
	block("ControlDesk",Vector3.new(5,2.6,2),Vector3.new(12,3.3,-14),Color3.fromRGB(88,92,100),Enum.Material.Metal)
	local monitor=block("ControlMonitor",Vector3.new(3,2,0.2),Vector3.new(12,5.8,-14.6),Color3.fromRGB(90,190,220),Enum.Material.Neon)
	local glow=Instance.new("PointLight") glow.Color=Color3.fromRGB(150,200,255) glow.Range=22 glow.Brightness=1 glow.Parent=sphere
	local arcs: {Part}={}
	for i=1,8 do local arc=Art.part(scene,"Arc"..i,Vector3.new(0.12,0.12,1),CFrame.new(origin),Color3.fromRGB(190,220,255),Enum.Material.Neon) arc.CastShadow=false arc.Transparency=1 arcs[i]=arc end
	-- Luminárias do teto: apagam no blecaute.
	local lamps: {{part: BasePart, light: Light}}={}
	for _,x in {-22,0,22} do for _,z in {-12,6,24} do
		local lamp=block("CeilingLamp",Vector3.new(8,0.3,2),Vector3.new(x,25.4,z),Color3.fromRGB(255,250,232),Enum.Material.Neon)
		local light=Instance.new("SpotLight") light.Face=Enum.NormalId.Bottom light.Angle=110 light.Range=34 light.Brightness=1.6 light.Color=Color3.fromRGB(255,244,220) light.Parent=lamp
		table.insert(lamps,{part=lamp,light=light})
	end end

	-- Seis jovens: uniforme escolar na escola; roupas de aventureiro ao acordar.
	local previews=ReplicatedStorage:FindFirstChild("ClassPreviews")
	local students={}
	local adventurers={}
	local ignore: {Instance}={scene}
	for _,other in game:GetService("Players"):GetPlayers() do if other.Character then table.insert(ignore,other.Character) end end
	for i=1,6 do
		local template=previews and previews:FindFirstChild(CLASS_ORDER[(i-1)%3+1])
		if template and template:IsA("Model") then
			local student=staticClone(template,"Student"..i,scene)
			relaxArms(student)
			dressAsStudent(student,i)
			local feet=origin+Vector3.new((i-3.5)*3.4,0,4+(i%2)*2.6)
			table.insert(students,{model=student,feet=feet,facing=CFrame.lookAt(feet,Vector3.new(origin.X+base.X,feet.Y,origin.Z+base.Z)).Rotation,offset=footOffset(student),side=({0,1,-1})[i%3+1],phase=i*0.9})
			local adventurer=staticClone(template,"Adventurer"..i,scene)
			relaxArms(adventurer)
			local angle=(i-1)/6*math.pi*2+0.3
			local x,z=wakeCenter.X+math.cos(angle)*4.6,wakeCenter.Z+math.sin(angle)*4.6
			local spot=Vector3.new(x,groundY(x,z,ignore),z)
			-- Deitados em roda, pés para o centro; ao levantar ficam voltados para o grupo.
			table.insert(adventurers,{model=adventurer,feet=spot,facing=CFrame.lookAt(spot,Vector3.new(wakeCenter.X,spot.Y,wakeCenter.Z)).Rotation,offset=footOffset(adventurer),side=0,phase=i*0.45})
		end
	end
	for _,actor in students do pose(actor,0,0) end
	for _,actor in adventurers do pose(actor,1,0) end
	local wakeGround=groundY(wakeCenter.X,wakeCenter.Z,ignore)
	local wake=Vector3.new(wakeCenter.X,wakeGround,wakeCenter.Z)

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
		local top=origin+base+Vector3.new(0,8,0)
		for i,arc in arcs do
			if intensity<=0 or math.random()>intensity then arc.Transparency=1 continue end
			local target=if i%3==0 then top+Vector3.new(math.random(-6,6),math.random(-4,6),math.random(-4,4)) else origin+electrodes[(i%2)+1]
			local mid=(top+target)/2+Vector3.new(math.random()-0.5,math.random()-0.5,math.random()-0.5)*2.5*intensity
			local a=if i%2==0 then top else mid
			local b=if i%2==0 then mid else target
			arc.Size=Vector3.new(0.08+0.1*intensity,0.08+0.1*intensity,(b-a).Magnitude)
			arc.CFrame=CFrame.lookAt((a+b)/2,b)
			arc.Transparency=0.15
		end
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
		if elapsed>=PAGE_SECONDS then setPage(page+1) return end
		if not camera then return end
		camera.CameraType=Enum.CameraType.Scriptable
		local t=elapsed/PAGE_SECONDS
		if page==1 then
			-- A turma assiste à demonstração; a bobina solta faíscas discretas.
			darkness(0) lightsOn(true)
			camera.FieldOfView=60
			camera.CFrame=CFrame.lookAt(origin+Vector3.new(16-8*t,9-1*t,30-6*t),origin+Vector3.new(0,6,-12))
			drawArcs(0.25+0.15*math.sin(elapsed*3)) glow.Brightness=1+0.5*math.sin(elapsed*4)
			for _,s in students do pose(s,0,math.sin(elapsed*1.2+s.phase)*0.02) end
		elseif page==2 then
			-- Sobrecarga: arcos crescem, luzes piscam e tudo apaga; os jovens desmaiam.
			camera.FieldOfView=62
			local shake=if t>0.25 and t<0.6 then Vector3.new(math.random()-0.5,math.random()-0.5,0)*0.35 else Vector3.zero
			camera.CFrame=CFrame.lookAt(origin+Vector3.new(-10+4*t,7-2*t,22-6*t)+shake,origin+Vector3.new(0,4.5,-4))
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
			for _,s in students do
				local fall=math.clamp((t-0.58-s.phase*0.012)/0.22,0,1)
				pose(s,fall*fall,0)
			end
		elseif page==3 then
			-- Escuridão e silêncio; depois a luz volta, agora sob um céu desconhecido.
			if t<0.45 then
				darkness(1)
				camera.CFrame=CFrame.lookAt(origin+Vector3.new(0,12,10),origin+Vector3.new(0,0,4))
			else
				local reveal=(t-0.45)/0.55
				darkness(1-reveal*reveal)
				camera.FieldOfView=55
				camera.CFrame=CFrame.lookAt(wake+Vector3.new(1.5,11-2.5*reveal,3),wake)
			end
			for _,a in adventurers do pose(a,1,0) end
		else
			-- Despertar: o grupo se levanta com roupas de aventureiro e a câmera revela o vale.
			darkness(0)
			camera.FieldOfView=60+8*t
			local ease=t*t*(3-2*t)
			camera.CFrame=CFrame.lookAt(wake+Vector3.new(4+10*ease,4+16*ease,12+26*ease),wake+Vector3.new(0,2+4*ease,-28*ease))
			for _,a in adventurers do
				local rise=math.clamp((t-0.05-a.phase*0.04)/0.45,0,1)
				pose(a,1-rise*rise*(3-2*rise),0)
			end
		end
	end)
	return {stop=stop,next=function() if not stopped then setPage(page+1) end end}
end
return Cinematic
