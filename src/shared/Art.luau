--!strict
-- Kit procedural original. Sem modelos externos ou scripts de Toolbox.
local Face=require(script.Parent.FacePresentation)
local Art = {}
Art.ApprovedTemplates = {IlyraTemplate = true}

-- A sincronização ao vivo do Rojo não consegue preencher MeshContent de MeshParts (plugins não
-- escrevem essa propriedade): um template recriado por ela vira caixas brancas. O lugar salvo e o
-- `rojo build` têm as malhas. Template incompleto → aviso no Output e contingência procedural.
local warnedTemplates: {[string]: boolean}={}
function Art.templateReady(template: Instance?): boolean
	if not template or not template:IsA("Model") then return false end
	for _,item in template:GetDescendants() do
		if item:IsA("MeshPart") and item.MeshId=="" then
			if not warnedTemplates[template.Name] then
				warnedTemplates[template.Name]=true
				warn("[PortalPerdido][Template] "..template.Name.." sem malha (MeshId vazio); usando contingência. Reabra o lugar salvo ou reimporte o .rbxm.")
			end
			return false
		end
	end
	return true
end
local stone = Color3.fromRGB(119, 124, 134)
local bark = Color3.fromRGB(86, 72, 59)
local gold = Color3.fromRGB(191, 157, 99)
local cyan = Color3.fromRGB(76, 201, 205)

function Art.part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?, solid: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	-- PartType.Ball usa o menor eixo; o mesh nativo preserva elipsoides.
	if shape==Enum.PartType.Ball then
		local mesh=Instance.new("SpecialMesh") mesh.MeshType=Enum.MeshType.Sphere mesh.Parent=p
	end
	p.Anchored = true
	p.CanCollide = solid == true
	p.CanTouch = false
	p.CanQuery = solid == true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function Art.segment(parent: Instance, name: string, a: Vector3, b: Vector3, width: number, color: Color3, material: Enum.Material?, solid: boolean?): Part
	return Art.part(parent, name, Vector3.new((b-a).Magnitude, width, width), CFrame.lookAt((a+b)*0.5, b)*CFrame.Angles(0, math.pi/2, 0), color, material, Enum.PartType.Cylinder, solid)
end

local function articulated(base: BasePart,piece: BasePart,pivot: CFrame,name: string): Motor6D
	piece.Anchored=false piece.Massless=true
	local joint=Instance.new("Motor6D") joint.Name=name
	joint.Part0=base joint.Part1=piece
	joint.C0=base.CFrame:ToObjectSpace(pivot)
	joint.C1=piece.CFrame:ToObjectSpace(pivot)
	joint.Parent=piece
	return joint
end

local function attach(base: BasePart,piece: BasePart)
	piece.Anchored=false piece.Massless=true
	local weld=Instance.new("WeldConstraint") weld.Part0=base weld.Part1=piece weld.Parent=piece
end

function Art.label(parent: BasePart, title: string, subtitle: string?, color: Color3?, offset: number?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Identity"
	gui.Size = UDim2.fromOffset(220, 55)
	gui.StudsOffset = Vector3.new(0, offset or 4, 0)
	gui.MaxDistance = 65
	gui.AlwaysOnTop = false
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 16
	label.TextColor3 = color or Color3.fromRGB(244, 232, 203)
	label.TextStrokeTransparency = 0.4
	label.Text = title .. (if subtitle then "\n" .. subtitle else "")
	label.Parent = gui
end

function Art.npc(parent: Instance, position: Vector3): Model
	local template=game:GetService("ServerStorage"):FindFirstChild("IlyraTemplate")
	-- Aprovação versionada no código: revisão visual de 03/11/2026 (ver docs/ILYRA_VISUAL_REVIEW.md).
	-- O atributo ArtApproved do .rbxm continua aceito para aprovações futuras feitas no Studio.
	local approved=template~=nil and (Art.ApprovedTemplates[template.Name]==true or template:GetAttribute("ArtApproved")==true)
	if template and template:IsA("Model") and approved and Art.templateReady(template) then
		local npc=template:Clone()
		local root=npc:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			npc.Name="Ilyra" npc.PrimaryPart=root
			for _,item in npc:GetDescendants() do
				if item:IsA("LuaSourceContainer") then item:Destroy()
				elseif item:IsA("BasePart") then item.Anchored=false item.CanCollide=false item.CanTouch=false item.Massless=true end
			end
			root.Anchored=true
			local h=npc:FindFirstChildOfClass("Humanoid")
			if h then h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None h.AutoRotate=false end
			npc:PivotTo(CFrame.new(position)*CFrame.Angles(0,math.pi,0))
			local box,size=npc:GetBoundingBox()
			npc:PivotTo(npc:GetPivot()+Vector3.new(0,position.Y-(box.Position.Y-size.Y/2),0))
			npc:SetAttribute("PresentationKind","Ilyra")
			npc:SetAttribute("GeneratedNPC",true)
			Art.label(root,"ILYRA","Guardiã do Vale",nil,4)
			npc.Parent=parent
			return npc
		end
		npc:Destroy()
	end
	local m = Instance.new("Model")
	m.Name = "Ilyra"
	local function p(name: string, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material?, shape: Enum.PartType?)
		return Art.part(m, name, size, CFrame.new(position+offset), color, material, shape)
	end
	local robe = Color3.fromRGB(45, 84, 110)
	local skin = Color3.fromRGB(211, 174, 145)
	local hair = Color3.fromRGB(213, 219, 218)
	local root = p("Root", Vector3.new(2,5,2), Vector3.new(0,3,0), robe)
	root.Transparency = 1
	m.PrimaryPart = root
	p("Robe", Vector3.new(2.7,4.1,1.8), Vector3.new(0,2.2,0), robe, Enum.Material.Fabric, Enum.PartType.Ball)
	p("Bodice", Vector3.new(2.1,2.2,1.4), Vector3.new(0,4.1,0), robe, Enum.Material.Fabric, Enum.PartType.Ball)
	p("Mantle", Vector3.new(2.7,0.5,1.7), Vector3.new(0,4.8,0.12), Color3.fromRGB(62,115,119), Enum.Material.Fabric, Enum.PartType.Ball)
	p("Belt", Vector3.new(2.2,0.22,1.5), Vector3.new(0,3.5,0), bark, Enum.Material.Leather)
	p("Buckle", Vector3.new(0.35,0.35,0.2), Vector3.new(0,3.5,-0.8), cyan, Enum.Material.Neon, Enum.PartType.Ball)
	p("Head", Vector3.new(1.25,1.55,1.2), Vector3.new(0,5.95,0), skin, nil, Enum.PartType.Ball)
	p("Hair", Vector3.new(1.4,1.4,1.35), Vector3.new(0,6.25,0.2), hair, nil, Enum.PartType.Ball)
	for _, side in {-1,1} do
		p("Braid", Vector3.new(0.28,2.1,0.32), Vector3.new(side*0.62,5.4,-0.04), hair, nil, Enum.PartType.Ball)
		p("BraidRing", Vector3.new(0.32,0.14,0.36), Vector3.new(side*0.62,4.65,-0.04), gold, Enum.Material.Metal)
		p("Eye", Vector3.new(0.25,0.12,0.06), Vector3.new(side*0.24,5.98,-0.56), Color3.fromRGB(238,237,224), nil, Enum.PartType.Ball)
		p("Iris", Vector3.new(0.1,0.11,0.04), Vector3.new(side*0.24,5.98,-0.6), Color3.fromRGB(60,113,114), nil, Enum.PartType.Ball)
		local sleeve=Art.segment(m,"Sleeve",position+Vector3.new(side*1.2,4.6,0),position+Vector3.new(side*1.6,3.4,-0.15),0.65,robe,Enum.Material.Fabric)
		local hand=p("Hand", Vector3.new(0.4,0.57,0.4), Vector3.new(side*1.6,3.05,-0.15), skin, nil, Enum.PartType.Ball)
		local sideName=if side<0 then "Left" else "Right"
		sleeve.Name=sideName.."Sleeve" hand.Name=sideName.."Hand"
		articulated(root,sleeve,CFrame.new(position+Vector3.new(side*1.2,4.6,0)),sideName.."Shoulder")
		attach(sleeve,hand)
		p("Boot",Vector3.new(0.65,0.7,1.55),Vector3.new(side*0.6,0.35,-0.6),bark,Enum.Material.Leather,Enum.PartType.Ball)
		p("Pupil",Vector3.new(0.044,0.085,0.025),Vector3.new(side*0.24,5.98,-0.625),Color3.fromRGB(28,37,42),nil,Enum.PartType.Ball)
		p("Eyebrow",Vector3.new(0.25,0.045,0.06),Vector3.new(side*0.24,6.12,-0.56),hair,nil,Enum.PartType.Ball)
		p("Ear",Vector3.new(0.18,0.28,0.22),Vector3.new(side*0.62,5.86,0),skin,nil,Enum.PartType.Ball)
	end
	p("Nose",Vector3.new(0.18,0.28,0.22),Vector3.new(0,5.77,-0.59),skin,nil,Enum.PartType.Ball)
	p("Smile",Vector3.new(0.29,0.045,0.05),Vector3.new(0,5.51,-0.53),Color3.fromRGB(147,99,86))
	p("Circlet",Vector3.new(1.32,0.11,1.25),Vector3.new(0,6.4,0),gold,Enum.Material.Metal)
	p("CircletGem",Vector3.new(0.22,0.3,0.15),Vector3.new(0,6.38,-0.65),cyan,Enum.Material.Neon,Enum.PartType.Ball)
	Art.segment(m,"Staff",position+Vector3.new(1.9,0.1,-0.4),position+Vector3.new(1.9,6.4,-0.4),0.18,bark,Enum.Material.Wood)
	p("StaffHalo",Vector3.new(0.65,0.65,0.23),Vector3.new(1.9,6.5,-0.4),gold,Enum.Material.Metal,Enum.PartType.Ball)
	p("StaffLight",Vector3.new(0.35,0.35,0.3),Vector3.new(1.9,6.6,-0.56),cyan,Enum.Material.Neon,Enum.PartType.Ball)
	local head=m:FindFirstChild("Head") :: BasePart
	articulated(root,head,CFrame.new(position+Vector3.new(0,5.2,0)),"Neck")
	local headPieces={Hair=true,Braid=true,BraidRing=true,Eye=true,Iris=true,Pupil=true,Eyebrow=true,Ear=true,Nose=true,Smile=true,Circlet=true,CircletGem=true}
	for _,piece in m:GetChildren() do
		if piece:IsA("BasePart") and piece~=root and piece~=head and not piece:FindFirstChildWhichIsA("JointInstance") and not piece:FindFirstChildOfClass("WeldConstraint") then
			attach(if headPieces[piece.Name] then head else root,piece)
		end
	end
	m:SetAttribute("PresentationKind","Ilyra")
	Art.label(root,"ILYRA","Guardiã do Vale",nil,5)
	m:PivotTo(m:GetPivot()*CFrame.Angles(0,math.pi,0))
	m.Parent = parent
	return m
end

-- Criaturas geradas (assets/characters/models/*-generated-v1.rbxm). Templates com frente em −Z e
-- pivô no centro da caixa. Offsets em unidades do template (antes da escala).
--   joints: peça → {nome do Motor6D, fração da altura da peça para o pivô, peça-base opcional}
--   baseY: altura da base da malha em relação ao chão (negativo afunda base modelada; positivo flutua)
--   glow: peças neon extras; "Core"/"Eye" são recoloridas pelo EnemyService na fase 2 do chefe.
local GENERATED: {[string]: any}={
	Boss={
		template="RootGuardianTemplate", scale=1.5, baseY=-0.85,
		-- Tronco (com a base de pedras modelada) gira a partir de baixo; cabeça e braços acompanham o tronco.
		joints={Torso={"Waist",-0.45},Head={"Neck",-0.4,"Torso"},LeftArm={"LeftShoulder",0.38,"Torso"},RightArm={"RightShoulder",0.38,"Torso"},LeftLeg={"LeftHip",0.4},RightLeg={"RightHip",0.4}},
		-- Offsets medidos por raycast no template (peito ≈ z −1,1; máscara ≈ z −0,75).
		glow={
			{name="Core",size=Vector3.new(1.0,0.95,0.3),offset=Vector3.new(0,0.62,-1.02),shape=Enum.PartType.Ball,on="Torso",light=14},
			{name="Eye",size=Vector3.new(0.3,0.15,0.08),offset=Vector3.new(-0.3,2.72,-0.74),on="Head"},
			{name="Eye",size=Vector3.new(0.3,0.15,0.08),offset=Vector3.new(0.3,2.72,-0.74),on="Head"},
		},
	},
	Wisp={
		-- Espectro flutuante: o corpo oscila no motor SpiritCore e leva cabeça e mãos junto.
		template="VoidEchoTemplate", scale=1.15, baseY=0.7,
		joints={Body={"SpiritCore",0},Head={"Neck",-0.4,"Body"},LeftArm={"LeftShoulder",0.3,"Body"},RightArm={"RightShoulder",0.3,"Body"}},
		bodyLight={on="Body",range=10,brightness=1.2},
	},
	Thorn={
		-- Quadrúpede de espinhos: nomes de quadril seguem ActorPresentation (Left/Right + Front/Rear).
		template="ThornStalkerTemplate", scale=1.25, baseY=0,
		joints={Body={"Waist",0},Head={"Neck",0.3,"Body"},FrontLeftLeg={"LeftFrontHip",0.4},FrontRightLeg={"RightFrontHip",0.4},RearLeftLeg={"LeftRearHip",0.4},RearRightLeg={"RightRearHip",0.4}},
		bodyLight={on="Body",range=7,brightness=0.9,color=Color3.fromRGB(236,160,72)},
	},
}

local function buildGenerated(m: Model,root: BasePart,spec: any,template: Model,position: Vector3,parent: Instance,color: Color3): Model
	local visual=template:Clone()
	visual:ScaleTo(spec.scale)
	local _,size=visual:GetBoundingBox()
	-- Chão medido só contra o cenário (o mundo é construído antes dos inimigos; no reaparecimento
	-- um jogador pode estar exatamente no ponto de origem).
	local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances={workspace:FindFirstChild("PortalChapter") or workspace.Terrain,workspace.Terrain}
	local hit=workspace:Raycast(position+Vector3.new(0,4,0),Vector3.new(0,-40,0),params)
	local floorY=if hit then hit.Position.Y else position.Y-2.5
	local center=CFrame.new(position.X,floorY+size.Y/2+spec.baseY,position.Z)
	visual:PivotTo(center)
	local pieces: {[string]: BasePart}={Root=root}
	for _,piece in visual:GetChildren() do
		if piece:IsA("BasePart") then
			piece.CanCollide=false piece.CanTouch=false piece.CanQuery=false
			piece.Parent=m
			pieces[piece.Name]=piece
		end
	end
	visual:Destroy()
	for name,piece in pieces do
		if piece==root then continue end
		local config=spec.joints[name]
		if config then
			local base=pieces[config[3] or "Root"] or root
			articulated(base,piece,CFrame.new(piece.Position+Vector3.new(0,piece.Size.Y*config[2],0)),config[1])
		else attach(root,piece) end
	end
	for _,g in spec.glow or {} do
		local part=Art.part(m,g.name,g.size*spec.scale,center*CFrame.new(g.offset*spec.scale),cyan,Enum.Material.Neon,g.shape)
		attach(pieces[g.on] or root,part)
		if g.light then
			local light=Instance.new("PointLight") light.Color=cyan light.Range=g.light light.Brightness=1.4 light.Shadows=false light.Parent=part
		end
	end
	if spec.bodyLight and pieces[spec.bodyLight.on] then
		local light=Instance.new("PointLight") light.Color=spec.bodyLight.color or color light.Range=spec.bodyLight.range light.Brightness=spec.bodyLight.brightness light.Shadows=false light.Parent=pieces[spec.bodyLight.on]
	end
	m:SetAttribute("GeneratedCreature",true)
	m.Parent=parent
	return m
end

function Art.enemy(parent: Instance, kind: string, position: Vector3, color: Color3): Model
	local m = Instance.new("Model")
	local boss = kind == "Boss"
	local scale = if boss then 2.2 else 1
	local root = Art.part(m,"Root",Vector3.new(4,5,4)*scale,CFrame.new(position),color)
	root.Transparency = 1
	root.CanQuery = true
	m.PrimaryPart = root
	local function p(name: string, size: Vector3, offset: Vector3, tint: Color3, material: Enum.Material?, shape: Enum.PartType?)
		return Art.part(m,name,size*scale,CFrame.new(position+offset*scale),tint,material,shape)
	end
	if kind=="Moss" then
		local template=game:GetService("ServerStorage"):FindFirstChild("SentinelTemplate")
		if template and template:IsA("Model") and Art.templateReady(template) then
			local visual=template:Clone()
			visual:ScaleTo(visual:GetScale()*1.3)
			visual:PivotTo(CFrame.new(position))
			local joints={['head_geom']={'Head','Neck',-0.55},['left arm_geom']={'LeftArm','LeftShoulder',1.25},['right arm_geom']={'RightArm','RightShoulder',1.25},['left leg_geom']={'LeftLeg','LeftHip',1.15},['right leg_geom']={'RightLeg','RightHip',1.15}}
			-- Tronco ganha articulação própria (Waist) para balançar/inclinar; cabeça e braços o acompanham.
			local torso: BasePart?=nil
			for _,piece in visual:GetDescendants() do
				if piece:IsA("BasePart") and piece.Name=="torso_geom" then torso=piece end
			end
			if torso then
				torso.Name="Torso" torso.CanCollide=false torso.CanTouch=false torso.CanQuery=false torso.Parent=m
				articulated(root,torso,CFrame.new(torso.Position-Vector3.new(0,torso.Size.Y*0.4,0)),"Waist")
			end
			for _,piece in visual:GetDescendants() do
				if piece:IsA("BasePart") then
					piece.CanCollide=false piece.CanTouch=false piece.CanQuery=false
					local config=joints[piece.Name]
					piece.Parent=m
					if config then
						piece.Name=config[1]
						local base=if torso and (config[2]=="Neck" or config[2]:find("Shoulder")) then torso else root
						articulated(base,piece,CFrame.new(piece.Position+Vector3.new(0,config[3],0)),config[2])
					else attach(root,piece) end
				end
			end
			visual:Destroy()
			m:SetAttribute("GeneratedCreature",true)
			m.Parent=parent
			return m
		end
	end
	local spec=GENERATED[kind]
	local template=spec and game:GetService("ServerStorage"):FindFirstChild(spec.template)
	if spec and template and template:IsA("Model") and Art.templateReady(template) then
		return buildGenerated(m,root,spec,template,position,parent,color)
	end
	if kind == "Wisp" then
		p("Core",Vector3.new(1.6,2.1,1.6),Vector3.zero,color,Enum.Material.Neon,Enum.PartType.Ball)
		for i=1,5 do
			local a=i*math.pi*2/5
			p("Shard",Vector3.new(0.45,2.3,0.6),Vector3.new(math.cos(a)*1.5,-0.2,math.sin(a)*1.5),stone,Enum.Material.Slate)
		end
		p("Eye",Vector3.new(0.8,0.2,0.2),Vector3.new(0,0.3,-0.85),Color3.fromRGB(233,212,255),Enum.Material.Neon)
	elseif kind == "Thorn" then
		p("Body",Vector3.new(3,2.2,4),Vector3.new(0,-0.5,0),color,Enum.Material.Wood,Enum.PartType.Ball)
		p("Head",Vector3.new(2,1.7,2),Vector3.new(0,0.1,-2),color,Enum.Material.Slate,Enum.PartType.Ball)
		for _, side in {-1,1} do
			for _, z in {-1.2,1.2} do
				p("Leg",Vector3.new(0.65,1.6,0.7),Vector3.new(side*1.1,-1.6,z),bark,Enum.Material.Wood)
			end
			p("Eye",Vector3.new(0.25,0.2,0.1),Vector3.new(side*0.55,0.35,-2.9),Color3.fromRGB(228,180,88),Enum.Material.Neon)
		end
		for i=1,5 do p("Thorn",Vector3.new(0.35,1.6,0.4),Vector3.new(0,1,-1.7+i*0.65),Color3.fromRGB(162,146,113),Enum.Material.Wood) end
	else
		p("Chest",Vector3.new(3.3,3.3,2.2),Vector3.new(0,0.1,0),stone,Enum.Material.Slate,Enum.PartType.Ball)
		p("MossMantle",Vector3.new(3.9,1,2.6),Vector3.new(0,1.4,0),color,Enum.Material.Grass,Enum.PartType.Ball)
		p("Head",Vector3.new(2,1.8,1.7),Vector3.new(0,2.2,0),stone,Enum.Material.Slate,Enum.PartType.Ball)
		p("Core",Vector3.new(0.7,1.1,0.28),Vector3.new(0,0.4,-1.15),cyan,Enum.Material.Neon,Enum.PartType.Ball)
		for _, side in {-1,1} do
			p("Arm",Vector3.new(1.2,2.8,1.3),Vector3.new(side*2,0,0),color,Enum.Material.Wood,Enum.PartType.Ball)
			p("Hand",Vector3.new(1.5,1.2,1.5),Vector3.new(side*2,-1.3,0),stone,Enum.Material.Slate,Enum.PartType.Ball)
			p("Leg",Vector3.new(1.25,2.1,1.45),Vector3.new(side*0.9,-2.1,0),bark,Enum.Material.Wood,Enum.PartType.Ball)
			p("Foot",Vector3.new(1.6,0.7,2.3),Vector3.new(side*0.9,-3,-0.3),stone,Enum.Material.Slate,Enum.PartType.Ball)
			p("Eye",Vector3.new(0.35,0.22,0.15),Vector3.new(side*0.5,2.35,-0.85),cyan,Enum.Material.Neon)
			if boss then
				Art.segment(m,"CrownRoot",position+Vector3.new(side*0.6,2.8,0)*scale,position+Vector3.new(side*1.9,4.5,0)*scale,0.25*scale,bark,Enum.Material.Wood)
				Art.segment(m,"CrownBranch",position+Vector3.new(side*1.4,3.9,0)*scale,position+Vector3.new(side*2.5,4.1,0)*scale,0.18*scale,bark,Enum.Material.Wood)
			end
		end
	end
	local arms: {[number]: BasePart}={}
	local legs: {[number]: BasePart}={}
	local head=m:FindFirstChild("Head")
	for _,piece in m:GetChildren() do
		if piece:IsA("BasePart") then
			local off=root.CFrame:PointToObjectSpace(piece.Position)
			local side=if off.X<0 then -1 else 1
			if piece.Name=="Arm" then arms[side]=piece elseif piece.Name=="Leg" and kind~="Thorn" then legs[side]=piece end
		end
	end
	for _,piece in m:GetChildren() do
		if not piece:IsA("BasePart") or piece==root then continue end
		local off=root.CFrame:PointToObjectSpace(piece.Position)
		local side=if off.X<0 then -1 else 1
		local sideName=if side<0 then "Left" else "Right"
		if piece.Name=="Arm" then
			articulated(root,piece,CFrame.new(piece.Position+Vector3.new(0,1.2*scale,0)),sideName.."Shoulder")
		elseif piece.Name=="Leg" then
			local label=if kind=="Thorn" then (if off.Z<0 then "Front" else "Rear") else ""
			articulated(root,piece,CFrame.new(piece.Position+Vector3.new(0,0.8*scale,0)),sideName..label.."Hip")
		elseif piece.Name=="Head" then
			articulated(root,piece,CFrame.new(piece.Position+Vector3.new(0,-0.65*scale,0)),"Neck")
		elseif piece.Name=="Core" and kind=="Wisp" then
			articulated(root,piece,piece.CFrame,"SpiritCore")
		elseif piece.Name=="Hand" and arms[side] then attach(arms[side],piece)
		elseif piece.Name=="Foot" and legs[side] then attach(legs[side],piece)
		elseif (piece.Name=="Eye" or piece.Name=="CrownRoot" or piece.Name=="CrownBranch") and head and head:IsA("BasePart") then attach(head,piece)
		elseif piece.Name=="Eye" and kind=="Wisp" then attach(m:FindFirstChild("Core") :: BasePart,piece)
		else attach(root,piece) end
	end

	m.Parent = parent
	return m
end

function Art.tree(parent: Instance, position: Vector3, seed: number, forest: boolean?)
	local rng=Random.new(seed)
	local m=Instance.new("Model") m.Name="LumenOak"
	local height=rng:NextNumber(17,26)
	local lean=Vector3.new(rng:NextNumber(-2.5,2.5),0,rng:NextNumber(-1.5,1.5))
	local mid=position+Vector3.new(0,height*0.48,0)+lean*0.35
	local crown=position+Vector3.new(0,height*0.83,0)+lean
	Art.segment(m,"LowerTrunk",position,mid,2.3,bark,Enum.Material.Wood,true)
	Art.segment(m,"UpperTrunk",mid,crown,1.55,bark:Lerp(Color3.fromRGB(110,99,79),0.2),Enum.Material.Wood,true)
	-- Ramos e copas em alturas diferentes: silhueta assimétrica com vazios de céu.
	for i=1,7 do
		local angle=i*2.39996+seed
		local radius=rng:NextNumber(3,7)
		local endPoint=crown+Vector3.new(math.cos(angle)*radius,rng:NextNumber(-3,4),math.sin(angle)*radius)
		local branchBase=mid:Lerp(crown,rng:NextNumber(0.1,0.75))
		Art.segment(m,"Branch",branchBase,endPoint,0.42+rng:NextNumber()*0.28,bark,Enum.Material.Wood)
		local tint=if forest then Color3.fromRGB(58,83,51) else Color3.fromRGB(77,101,56)
		tint=tint:Lerp(Color3.fromRGB(115,132,69),rng:NextNumber(0.05,0.33))
		local size=Vector3.new(rng:NextNumber(5,8),rng:NextNumber(3,4.8),rng:NextNumber(5,8))
		Art.part(m,"LeafCluster",size,CFrame.new(endPoint)*CFrame.Angles(rng:NextNumber(-0.45,0.45),angle,rng:NextNumber(-0.3,0.3)),tint,Enum.Material.Grass,Enum.PartType.Ball)
		if i%2==1 then
			local tip=endPoint+Vector3.new(math.cos(angle)*2.5,1.3,math.sin(angle)*2.5)
			Art.segment(m,"Twig",endPoint,tip,0.18,bark,Enum.Material.Wood)
			Art.part(m,"OuterLeaves",size*0.53,CFrame.new(tip)*CFrame.Angles(0,angle,0.4),tint,Enum.Material.Grass,Enum.PartType.Ball)
		end
	end
	for i=1,4 do
		local a=i*math.pi/2+seed
		Art.segment(m,"SurfaceRoot",position+Vector3.new(0,0.7,0),position+Vector3.new(math.cos(a)*rng:NextNumber(2.5,4.2),0.1,math.sin(a)*3.2),0.5,bark,Enum.Material.Wood)
	end
	m.Parent=parent
end

function Art.portal(parent: Instance, position: Vector3, radius: number): Model
	local m = Instance.new("Model")
	m.Name = "PortalPrimordial"
	for i=1,16 do
		local a=(i/16)*math.pi*2
		local cf=CFrame.new(position+Vector3.new(math.cos(a)*radius, radius+math.sin(a)*radius,0))*CFrame.Angles(0,0,a)
		Art.part(m,"ArchStone",Vector3.new(radius*0.42,3.3,3.6),cf,stone,Enum.Material.Slate,nil,true)
		Art.part(m,"ArcaneInset",Vector3.new(0.22,1.9,0.12),cf*CFrame.new(-1.1,0,-1.86),cyan,Enum.Material.Neon)
	end
	local rift=Art.part(m,"Rift",Vector3.new(radius*1.45,radius*1.7,0.3),CFrame.new(position+Vector3.new(0,radius,0)),cyan,Enum.Material.Neon,Enum.PartType.Ball)
	rift.Transparency=0.32
	local light=Instance.new("PointLight")
	light.Color=cyan
	light.Brightness=0.9
	light.Range=23
	light.Shadows=false
	light.Parent=rift
	m.Parent=parent
	return m
end

function Art.equipment(character: Model, classId: string, color: Color3)
	local old=character:FindFirstChild("ClassEquipment")
	if old then old:Destroy() end
	local torso=character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not torso or not torso:IsA("BasePart") then return end
	local folder=Instance.new("Model")
	folder.Name="ClassEquipment"
	local right=character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm") or torso
	local left=character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm") or torso
	local function equip(name: string,size: Vector3,offset: CFrame,tint: Color3,material: Enum.Material?,shape: Enum.PartType?,target: Instance?)
		local base=if target and target:IsA("BasePart") then target else torso
		local piece=Art.part(folder,name,size,base.CFrame*offset,tint,material,shape)
		piece.Anchored=false
		piece.Massless=true
		local weld=Instance.new("WeldConstraint")
		weld.Part0=base weld.Part1=piece weld.Parent=piece
		return piece
	end
	-- Camadas leves acompanham o rig; sem colisões ou alteração de movimento.
	local leather=Color3.fromRGB(91,65,46)
	local iron=Color3.fromRGB(98,112,119)
	equip("TravelBelt",Vector3.new(1.95,0.19,1.15),CFrame.new(0,-0.72,0),leather,Enum.Material.Leather)
	equip("BeltBuckle",Vector3.new(0.26,0.23,0.09),CFrame.new(0,-0.72,-0.62),gold,Enum.Material.Metal)
	equip("TravelPouch",Vector3.new(0.44,0.56,0.31),CFrame.new(-0.82,-0.65,-0.5),leather,Enum.Material.Leather,Enum.PartType.Ball)
	if classId=="Guardian" then
		equip("Breastplate",Vector3.new(1.65,1.3,0.24),CFrame.new(0,0,-0.58),iron,Enum.Material.Metal,Enum.PartType.Ball)
		for _,side in {-1,1} do
			equip("Pauldrons",Vector3.new(0.75,0.45,1.1),CFrame.new(side*1.02,0.67,0),iron,Enum.Material.Metal,Enum.PartType.Ball)
			equip("PlateTrim",Vector3.new(0.08,1.05,0.08),CFrame.new(side*0.6,0,-0.73),gold,Enum.Material.Metal)
		end
	elseif classId=="Explorer" then
		equip("TravelScarf",Vector3.new(1.2,0.28,1),CFrame.new(0,0.82,0),Color3.fromRGB(77,97,60),Enum.Material.Fabric,Enum.PartType.Ball)
		equip("LeatherBaldric",Vector3.new(0.22,2.2,0.12),CFrame.new(0,0,-0.61)*CFrame.Angles(0,0,-0.5),leather,Enum.Material.Leather)
		equip("ShortCloak",Vector3.new(1.75,1.65,0.17),CFrame.new(0,-0.12,0.68)*CFrame.Angles(-0.12,0,0),Color3.fromRGB(65,81,52),Enum.Material.Fabric)
	else
		equip("WovenStole",Vector3.new(0.42,1.95,0.16),CFrame.new(-0.53,-0.05,-0.63),Color3.fromRGB(91,68,113),Enum.Material.Fabric)
		for i=1,3 do
			equip("RunicClasp",Vector3.new(0.18,0.13,0.06),CFrame.new(-0.53,0.65-i*0.38,-0.74),gold,Enum.Material.Metal)
		end
		-- Grimório pendurado no quadril, com a capa rente ao corpo, páginas e fecho dourado.
		local book=CFrame.new(0.8,-1.08,0.1)*CFrame.Angles(0,math.pi/2,-0.08)
		equip("Grimoire",Vector3.new(0.62,0.82,0.24),book,Color3.fromRGB(71,55,81),Enum.Material.Leather)
		equip("GrimoirePages",Vector3.new(0.6,0.76,0.2),book*CFrame.new(0.03,0,0),Color3.fromRGB(226,214,186),Enum.Material.SmoothPlastic)
		equip("GrimoireClasp",Vector3.new(0.12,0.2,0.27),book*CFrame.new(0.3,0,0),gold,Enum.Material.Metal)
	end
	equip("Mantle",Vector3.new(2.1,0.35,1.2),CFrame.new(0,0.65,0),color,Enum.Material.Fabric)
	equip("Crest",Vector3.new(0.35,0.5,0.15),CFrame.new(0,0.4,-0.65),gold,Enum.Material.Metal,Enum.PartType.Ball)
	if classId=="Guardian" then
		-- Escudo redondo azul com aro e estrela de oito pontas dourados (referência guardian-reference-v1).
		-- Preso ao antebraço como um escudo real, com a face para fora do braço: em repouso fica ao
		-- lado do corpo; com o antebraço em guarda, a face vira para a frente. Sem antebraço
		-- (boneco da seleção), usa a mão como antes. Peças em coordenadas do escudo (face = −Z).
		local forearm=character:FindFirstChild("LeftLowerArm")
		local mount: Instance=left
		local shieldFrame=CFrame.new(-0.25,0,-0.33)
		if forearm and forearm:IsA("BasePart") then
			-- Suporte articulado: em repouso a face aponta para fora do braço (ao lado do corpo);
			-- em guarda, AvatarFallback gira o motor "ShieldOrientation" para a rotação medida no Play
			-- (antebraço em guarda → face para a frente). O mesmo padrão do BowOrientation do arco.
			local rest=CFrame.Angles(0,math.pi/2,0)
			local guard=CFrame.Angles(-2.39,0.03,-0.62)
			local holder=equip("ShieldMount",Vector3.new(0.05,0.05,0.05),CFrame.new(-0.42,-0.05,0)*rest,iron,nil,nil,forearm)
			holder.Transparency=1
			local weld=holder:FindFirstChildOfClass("WeldConstraint") if weld then weld:Destroy() end
			local joint=Instance.new("Motor6D") joint.Name="ShieldOrientation" joint.Part0=forearm joint.Part1=holder
			joint.C0=forearm.CFrame:ToObjectSpace(holder.CFrame) joint.Parent=holder
			holder:SetAttribute("GuardTransform",rest:Inverse()*guard)
			mount=holder shieldFrame=CFrame.identity
		end
		local face=CFrame.Angles(0,math.pi/2,0) -- eixo do cilindro ao longo da normal do escudo
		local royal=Color3.fromRGB(38,58,132)
		local steel=Color3.fromRGB(196,206,216)
		equip("ShieldRim",Vector3.new(0.16,2.3,2.3),shieldFrame*face,gold,Enum.Material.Metal,Enum.PartType.Cylinder,mount)
		equip("AstralShield",Vector3.new(0.2,2.08,2.08),shieldFrame*CFrame.new(0,0,-0.04)*face,royal,Enum.Material.Metal,Enum.PartType.Cylinder,mount)
		for i=0,3 do
			local long=i%2==0
			-- Elipsoides afilam nas pontas e formam a estrela de oito pontas.
			equip("ShieldStar",Vector3.new(if long then 0.3 else 0.2,if long then 1.75 else 1.1,0.05),shieldFrame*CFrame.new(0,0,-0.16)*CFrame.Angles(0,0,i*math.pi/4),gold,Enum.Material.Metal,Enum.PartType.Ball,mount)
		end
		equip("ShieldSigil",Vector3.new(0.34,0.34,0.14),shieldFrame*CFrame.new(0,0,-0.19),color,Enum.Material.Neon,Enum.PartType.Ball,mount)
		-- Espada longa montada no próprio eixo (Y = lâmina) e encaixada no punho fechado:
		-- o punho cruza a palma e a lâmina sai para frente (−Z da mão), inclinada ~20° para cima.
		local hold=CFrame.new(0,-0.18,0)*CFrame.Angles(-1.22,0,0)
		local function sword(name: string,size: Vector3,y: number,tint: Color3,material: Enum.Material,shape: Enum.PartType?,extra: CFrame?)
			equip(name,size,hold*CFrame.new(0,y,0)*(extra or CFrame.identity),tint,material,shape,right)
		end
		sword("SwordGrip",Vector3.new(0.62,0.13,0.13),0,bark,Enum.Material.Leather,Enum.PartType.Cylinder,CFrame.Angles(0,0,math.pi/2))
		sword("SwordPommel",Vector3.new(0.24,0.24,0.24),-0.38,gold,Enum.Material.Metal,Enum.PartType.Ball)
		sword("SwordGuard",Vector3.new(0.86,0.12,0.16),0.37,gold,Enum.Material.Metal)
		for _,side in {-1,1} do sword("SwordGuardCap",Vector3.new(0.16,0.16,0.16),0.37,gold,Enum.Material.Metal,Enum.PartType.Ball,CFrame.new(side*0.45,0,0)) end
		sword("SwordBlade",Vector3.new(0.2,2.45,0.06),1.65,steel,Enum.Material.Metal)
		sword("SwordFuller",Vector3.new(0.05,2.05,0.075),1.52,Color3.fromRGB(140,152,166),Enum.Material.Metal)
		sword("SwordTip",Vector3.new(0.2,0.55,0.06),2.87,steel,Enum.Material.Metal,Enum.PartType.Ball)
		-- Rastro do corte: desligado; AvatarFallback liga só na fase de golpe do ataque.
		local blade=folder:FindFirstChild("SwordBlade")
		if blade then
			local a0=Instance.new("Attachment") a0.Name="TrailBase" a0.Position=Vector3.new(0,-1.0,0) a0.Parent=blade
			local a1=Instance.new("Attachment") a1.Name="TrailTip" a1.Position=Vector3.new(0,1.45,0) a1.Parent=blade
			local trail=Instance.new("Trail") trail.Attachment0=a0 trail.Attachment1=a1 trail.Lifetime=0.16 trail.MinLength=0.05
			trail.Color=ColorSequence.new(Color3.fromRGB(235,245,255),color) trail.LightEmission=0.8
			trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.25),NumberSequenceKeypoint.new(1,1)})
			trail.WidthScale=NumberSequence.new(1,0.3) trail.Enabled=false trail.Parent=blade
		end
	elseif classId=="Explorer" then
		-- Aljava de couro encostada nas costas, na diagonal; flechas emplumadas saem do topo.
		local quiver=CFrame.new(0.32,0.1,0.62)*CFrame.Angles(0,0,1.22)
		equip("Quiver",Vector3.new(1.7,0.44,0.44),quiver,leather,Enum.Material.Leather,Enum.PartType.Cylinder)
		equip("QuiverRim",Vector3.new(0.08,0.5,0.5),quiver*CFrame.new(0.82,0,0),gold,Enum.Material.Metal,Enum.PartType.Cylinder)
		for i,o in {Vector2.new(0.09,0.08),Vector2.new(-0.1,0.05),Vector2.new(0,-0.1)} do
			equip("Arrow",Vector3.new(0.5,0.05,0.05),quiver*CFrame.new(1.05,o.X,o.Y),Color3.fromRGB(150,118,80),Enum.Material.Wood,Enum.PartType.Cylinder)
			equip("ArrowFletching",Vector3.new(0.26,0.16,0.03),quiver*CFrame.new(1.2,o.X,o.Y)*CFrame.Angles(i*1.05,0,0),if i==2 then Color3.fromRGB(171,62,49) else Color3.fromRGB(231,224,206),Enum.Material.Fabric,Enum.PartType.Ball)
		end
		-- O centro da empunhadura é a mão; a compensação mantém o arco vertical ao mirar.
		local mount=equip("BowGrip",Vector3.new(0.05,0.05,0.05),CFrame.identity,bark,nil,nil,left)
		mount.Transparency=1
		local oldWeld=mount:FindFirstChildOfClass("WeldConstraint") if oldWeld then oldWeld:Destroy() end
		local mountJoint=Instance.new("Motor6D") mountJoint.Name="BowOrientation" mountJoint.Part0=left :: BasePart mountJoint.Part1=mount mountJoint.Transform=CFrame.Angles(0,-math.pi/2,0) mountJoint.Parent=mount
		local grip=CFrame.identity
		local curve={Vector3.new(0.6,-1.3,0),Vector3.new(0.2,-0.9,0),Vector3.zero,Vector3.new(0.2,0.9,0),Vector3.new(0.6,1.3,0)}
		for i=1,#curve-1 do local a,b=curve[i],curve[i+1] equip("BowLimb",Vector3.new((b-a).Magnitude,0.14,0.14),grip*CFrame.lookAt((a+b)*0.5,b)*CFrame.Angles(0,math.pi/2,0),bark,Enum.Material.Wood,Enum.PartType.Cylinder,mount) end
		local stringColor=Color3.fromRGB(221,212,182)
		equip("BowString",Vector3.new(2.6,0.028,0.028),grip*CFrame.new(0.6,0,0)*CFrame.Angles(0,0,math.pi/2),stringColor,Enum.Material.Fabric,Enum.PartType.Cylinder,mount)
		local function anchor(name: string,offset: CFrame,target: Instance): Attachment
			local piece=equip(name,Vector3.new(0.05,0.05,0.05),offset,bark,nil,nil,target)
			piece.Transparency=1
			local attachment=Instance.new("Attachment") attachment.Parent=piece return attachment
		end
		local top=anchor("BowTipTop",grip*CFrame.new(curve[#curve]),mount)
		local bottom=anchor("BowTipBottom",grip*CFrame.new(curve[1]),mount)
		local nock=anchor("StringDraw",CFrame.new(0,-0.1,0),right)
		for _,tip in {top,bottom} do
			local beam=Instance.new("Beam") beam.Name="DrawnString" beam.Attachment0=tip beam.Attachment1=nock beam.Width0=0.028 beam.Width1=0.028 beam.FaceCamera=true beam.Color=ColorSequence.new(stringColor) beam.Enabled=false beam.Parent=folder
		end

	else
		-- Cristal de foco flutuando junto aos dedos, para fora do casaco e um pouco à frente.
		-- Offset medido no Play: em repouso a mão do rig gerado fica girada (+X aponta para fora/baixo),
		-- e este ponto cai ~1,2 stud à direita e 0,3 à frente da raiz. Neon grande antigo estourava no Bloom.
		local focus=CFrame.new(0.42,-0.3,-0.28)
		local core=equip("ArcaneFocus",Vector3.new(0.3,0.38,0.3),focus,color,Enum.Material.Neon,Enum.PartType.Ball,right)
		local shell=equip("FocusShell",Vector3.new(0.56,0.66,0.56),focus,color:Lerp(Color3.new(1,1,1),0.3),Enum.Material.Glass,Enum.PartType.Ball,right)
		shell.Transparency=0.5
		local glow=Instance.new("PointLight") glow.Color=color glow.Range=6 glow.Brightness=1.1 glow.Shadows=false glow.Parent=core
		equip("Harness",Vector3.new(0.3,2.2,0.1),CFrame.new(0.4,0,-0.65)*CFrame.Angles(0,0,-0.5),gold,Enum.Material.Metal)
	end
	if character:GetAttribute("PortalGeneratedRig") then
		-- Peças já modeladas nos rigs gerados (cinto, capa, armadura do Guardião); armas e foco continuam.
		local baked={TravelBelt=true,BeltBuckle=true,TravelPouch=true,TravelScarf=true,LeatherBaldric=true,ShortCloak=true,Mantle=true,Crest=true,WovenStole=true,RunicClasp=true,Harness=true,Breastplate=true,Pauldrons=true,PlateTrim=true}
		for _,piece in folder:GetChildren() do if baked[piece.Name] then piece:Destroy() end end
	end
	folder.Parent=character
end

function Art.classPreview(classId: string,color: Color3): Model
	local m=Instance.new("Model") m.Name=classId
	local function p(name: string,size: Vector3,position: Vector3,tint: Color3)
		return Art.part(m,name,size,CFrame.new(position),tint,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
	end
	m.PrimaryPart=p("UpperTorso",Vector3.new(1.9,2,1),Vector3.new(0,3.2,0),color:Lerp(Color3.fromRGB(43,58,69),0.55))
	local head=p("Head",Vector3.new(1.2,1.4,1.15),Vector3.new(0,4.9,0),Color3.fromRGB(209,176,143))
	Face.apply(head,classId)
	p("Hair",Vector3.new(1.25,0.85,1.2),Vector3.new(0,5.3,0.1),Color3.fromRGB(76,61,48))
	for _, side in {-1,1} do
		p(if side<0 then "LeftHand" else "RightHand",Vector3.new(0.55,1.9,0.6),Vector3.new(side*1.3,3,0),color)
		p("Leg",Vector3.new(0.7,2.1,0.8),Vector3.new(side*0.5,1.2,0),Color3.fromRGB(51,60,69))
	end
	Art.equipment(m,classId,color)
	return m
end

return Art
