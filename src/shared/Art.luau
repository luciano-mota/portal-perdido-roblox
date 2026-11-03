--!strict
-- Kit procedural original. Sem modelos externos ou scripts de Toolbox.
local Face=require(script.Parent.FacePresentation)
local Art = {}
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
		equip("Grimoire",Vector3.new(0.64,0.87,0.28),CFrame.new(0.85,-0.65,0.1)*CFrame.Angles(0,0,-0.12),Color3.fromRGB(71,55,81),Enum.Material.Leather)
	end
	equip("Mantle",Vector3.new(2.1,0.35,1.2),CFrame.new(0,0.65,0),color,Enum.Material.Fabric)
	equip("Crest",Vector3.new(0.35,0.5,0.15),CFrame.new(0,0.4,-0.65),gold,Enum.Material.Metal,Enum.PartType.Ball)
	if classId=="Guardian" then
		equip("AstralShield",Vector3.new(1.45,2,0.25),CFrame.new(-0.25,0,-0.35),Color3.fromRGB(76,92,118),Enum.Material.Metal,Enum.PartType.Ball,left)
		equip("ShieldSigil",Vector3.new(0.2,1,0.1),CFrame.new(-0.25,0,-0.51),color,Enum.Material.Neon,nil,left)
		equip("SwordBlade",Vector3.new(0.22,2.7,0.12),CFrame.new(0,1.45,-0.2),Color3.fromRGB(183,201,216),Enum.Material.Metal,nil,right)
		equip("SwordGuard",Vector3.new(0.8,0.18,0.25),CFrame.new(0,0.05,-0.2),gold,Enum.Material.Metal,nil,right)
		equip("SwordGrip",Vector3.new(0.15,0.65,0.15),CFrame.new(0,-0.35,-0.2),bark,Enum.Material.Leather,nil,right)
	elseif classId=="Explorer" then
		equip("Quiver",Vector3.new(2,0.7,0.65),CFrame.new(0.65,0,0.8)*CFrame.Angles(0,0,1.3),bark,Enum.Material.Leather,Enum.PartType.Cylinder)
		for i=1,3 do equip("Arrow",Vector3.new(0.06,2.5,0.06),CFrame.new(0.5+i*0.1,0.35,0.85),gold,Enum.Material.Wood) end
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
		equip("ArcaneFocus",Vector3.new(0.7,0.9,0.7),CFrame.new(0,0.25,-0.2),color,Enum.Material.Neon,Enum.PartType.Ball,right)
		equip("FocusCage",Vector3.new(0.12,0.75,0.75),CFrame.new(0,0.25,-0.2),gold,Enum.Material.Metal,Enum.PartType.Cylinder,right)
		equip("Harness",Vector3.new(0.3,2.2,0.1),CFrame.new(0.4,0,-0.65)*CFrame.Angles(0,0,-0.5),gold,Enum.Material.Metal)
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
