--!strict
-- Fase 4 — Cidadela do Eclipse (fortaleza TERRESTRE). Referência: 07-cidadela-do-eclipse.png.
-- Estrada com tochas → muralha e portão com torres e estandartes do eclipse → cidade baixa
-- (casas góticas, praça com fonte) → ponte em arcos sobre a ravina com rio e cascata →
-- escadaria da barbacã → pátio do castelo (arena) → fachada com o Selo do Eclipse (objetivo)
-- e a passagem escondida no átrio (saída). Horizonte de agulhas acesas; eclipse no céu (cliente).
local Kit=require(script.Parent.Parent.RegionKit)
local Region={}

local C=Color3.fromRGB
local wall=C(88,84,108)
local dark=C(56,52,72)
local roof=C(62,56,90)
local trim=C(156,120,66)
local window=C(255,150,70)
local cloth=C(84,22,34)
local emblem=C(255,136,58)
local cobble=C(98,94,112)
local U=24 -- topo da cidadela alta (múltiplo de 4)

function Region.build(world: Instance,O: Vector3): Model
	local function L(x: number,y: number,z: number): Vector3 return O+Vector3.new(x,y,z) end
	local rng=Random.new(40404)
	local model=Instance.new("Model") model.Name="EclipseCitadel" model:SetAttribute("RegionId","EclipseCitadel") model.Parent=world
	local terrain=workspace.Terrain
	terrain:SetMaterialColor(Enum.Material.Basalt,C(62,60,76))

	-- Terreno: planalto, ravina com rio, rocha da cidadela alta e montanhas ao redor.
	terrain:FillBlock(CFrame.new(L(0,-42,-200)),Vector3.new(540,84,820),Enum.Material.Basalt)
	terrain:FillBlock(CFrame.new(L(0,-2,30)),Vector3.new(540,4,90),Enum.Material.Grass)
	terrain:FillBlock(CFrame.new(L(0,-2,30)),Vector3.new(20,4,92),Enum.Material.Basalt)
	terrain:FillBlock(CFrame.new(L(0,-30,-185)),Vector3.new(540,60,92),Enum.Material.Air)
	terrain:FillBlock(CFrame.new(L(0,-58,-185)),Vector3.new(540,4,88),Enum.Material.Water)
	for i=0,26 do
		local x=-260+i*20
		for _,edge in {-139,-231} do
			terrain:FillBall(L(x+rng:NextNumber(-5,5),rng:NextNumber(-48,-10),edge+rng:NextNumber(-3,3)),rng:NextNumber(7,12),Enum.Material.Basalt)
		end
	end
	task.wait()
	terrain:FillBlock(CFrame.new(L(0,-10,-420)),Vector3.new(420,68,380),Enum.Material.Basalt)
	for i=0,20 do
		terrain:FillBall(L(-200+i*20,rng:NextNumber(-6,16),-232+rng:NextNumber(-3,2)),rng:NextNumber(9,14),Enum.Material.Basalt)
	end
	-- Bordas laterais e fundo irregulares da rocha alta.
	for i=0,18 do
		for _,s in {-1,1} do terrain:FillBall(L(s*(208+rng:NextNumber(-6,6)),rng:NextNumber(-10,18),-240-i*20),rng:NextNumber(12,20),Enum.Material.Basalt) end
		terrain:FillBall(L(-200+i*22,rng:NextNumber(-10,18),-608+rng:NextNumber(-4,4)),rng:NextNumber(12,20),Enum.Material.Basalt)
	end
	terrain:FillBlock(CFrame.new(L(0,16,-244)),Vector3.new(26,32,60),Enum.Material.Air)
	for i=0,14 do
		local a=i/14*math.pi
		local h=rng:NextNumber(100,180)
		local r=rng:NextNumber(40,70)
		local p=L(math.cos(a)*340,30,-260-math.sin(a)*420)
		terrain:FillCylinder(CFrame.new(p),h,r,Enum.Material.Basalt)
		terrain:FillBall(p+Vector3.new(rng:NextNumber(-10,10),h/2,0),r*0.9,Enum.Material.Basalt)
	end
	task.wait()

	-- Chegada: estrada com tochas até o portão.
	local approach=Kit.folder(model,"Approach")
	local arrival=Kit.arrival(approach,"Arrival",L(0,0.4,70),Vector3.new(0,0,-1),emblem,wall)
	Kit.block(approach,"Road",Vector3.new(12,0.6,94),CFrame.new(L(0,0.1,28)),cobble,Enum.Material.Cobblestone)
	local function torch(p: Vector3,lit: boolean)
		Kit.block(approach,"TorchPost",Vector3.new(0.6,6,0.6),CFrame.new(p+Vector3.new(0,3,0)),dark,Enum.Material.Metal)
		Kit.deco(approach,"TorchBowl",Vector3.new(1.4,0.6,1.4),CFrame.new(p+Vector3.new(0,6.2,0)),trim,Enum.Material.Metal)
		local flame=Kit.deco(approach,"TorchFlame",Vector3.new(0.9,1.6,0.9),CFrame.new(p+Vector3.new(0,7.2,0)),window,Enum.Material.Neon,Enum.PartType.Ball)
		if lit then Kit.light(flame,window,22,1.4) end
	end
	for i=0,5 do
		for _,s in {-1,1} do torch(L(s*8,0,64-i*15),i%2==0) end
	end
	task.wait()

	-- Muralha, portão e torres.
	local walls=Kit.folder(model,"Walls")
	for _,s in {-1,1} do
		Kit.block(walls,"CurtainWall",Vector3.new(140,26,8),CFrame.new(L(s*80,13,-20)),wall,Enum.Material.Slate)
		for k=0,34 do
			Kit.block(walls,"Merlon",Vector3.new(2.2,2.4,8.4),CFrame.new(L(s*(13+k*4),27.2,-20)),wall,Enum.Material.Slate)
		end
		Kit.spire(walls,L(s*16,0,-20),14,40,24,wall,roof,Enum.Material.Slate,window)
		Kit.spire(walls,L(s*150,0,-20),12,34,20,wall,roof,Enum.Material.Slate,window)
		Kit.banner(walls,CFrame.lookAt(L(s*16,26,-12.8),L(s*16,26,10)),7,13,cloth,emblem,C(24,10,14))
		Kit.banner(walls,CFrame.lookAt(L(s*60,17,-15.8),L(s*60,17,10)),5,9,cloth,emblem,C(24,10,14))
	end
	Kit.block(walls,"GateLintel",Vector3.new(18,8,8),CFrame.new(L(0,22,-20)),wall,Enum.Material.Slate)
	Kit.archway(walls,"GateArch",L(0,0,-15.6),Vector3.new(0,0,1),14,19,1.2,trim,Enum.Material.Slate,emblem)
	local portcullis=Kit.folder(walls,"Portcullis")
	for k=-3,3 do Kit.deco(portcullis,"PortcullisBar",Vector3.new(0.35,6,0.35),CFrame.new(L(k*2,16,-20)),dark,Enum.Material.Metal) end
	task.wait()

	-- Cidade baixa: avenida, casas góticas e praça com fonte.
	local city=Kit.folder(model,"LowerCity")
	Kit.block(city,"Avenue",Vector3.new(14,0.6,116),CFrame.new(L(0,0.1,-78)),cobble,Enum.Material.Cobblestone)
	local function house(p: Vector3,w: number,d: number,h: number,face: number)
		local m=Kit.folder(city,"GothicHouse")
		Kit.block(m,"HouseWalls",Vector3.new(w,h,d),CFrame.new(p+Vector3.new(0,h/2,0)),wall:Lerp(dark,rng:NextNumber(0,0.4)),Enum.Material.Slate)
		Kit.pyramid(m,"HouseRoof",p+Vector3.new(0,h,0),math.max(w,d)+1.2,h*rng:NextNumber(0.6,0.95),roof,Enum.Material.Slate)
		local rows=math.max(1,math.floor(h/7))
		for r=1,rows do
			for k=-1,1 do
				if rng:NextNumber()<0.7 then
					local q=p+Vector3.new(k*w*0.28,r*h/(rows+1),face*(d/2+0.06))
					Kit.glow(m,"HouseWindow",Vector3.new(1.3,2.4,0.12),CFrame.new(q),window)
				end
			end
		end
		Kit.block(m,"HouseDoor",Vector3.new(2.6,4.2,0.3),CFrame.new(p+Vector3.new(0,2.1,face*(d/2+0.1))),C(54,38,30),Enum.Material.WoodPlanks)
	end
	for _,s in {-1,1} do
		local z=-32
		while z>-128 do
			local d=rng:NextNumber(10,14)
			local w=rng:NextNumber(11,15)
			if not (z<-64 and z>-98) then house(L(s*(14+d/2),0,z-w/2),w,d,rng:NextNumber(12,22),1) end
			z-=w+rng:NextNumber(2,5)
		end
		for k=0,2 do
			local w=rng:NextNumber(12,16)
			house(L(s*(46+k*2),0,-40-k*30),w,14,rng:NextNumber(14,24),1)
		end
		Kit.spire(city,L(s*70,0,-90),10,34,20,wall,roof,Enum.Material.Slate,window)
	end
	-- Casas com a frente para a avenida: janelas na face lateral (giradas depois).
	for _,folderItem in city:GetChildren() do
		if folderItem.Name=="GothicHouse" then
			local body=folderItem:FindFirstChild("HouseWalls")
			if body and body:IsA("BasePart") then
				local side=if body.Position.X>O.X then -1 else 1
				local pivot=CFrame.new(body.Position.X,O.Y,body.Position.Z)
				for _,piece in folderItem:GetChildren() do
					if piece:IsA("BasePart") then
						piece.CFrame=pivot*CFrame.Angles(0,side*math.pi/2,0)*pivot:ToObjectSpace(piece.CFrame)
					end
				end
			end
		end
	end
	local plaza=L(0,0,-81)
	Kit.disc(city,"Plaza",plaza,17,0.6,O.Y+0.5,cobble:Lerp(trim,0.1),Enum.Material.Cobblestone)
	Kit.disc(city,"FountainBasin",plaza,5,1.6,O.Y+1.9,wall,Enum.Material.Slate)
	Kit.disc(city,"FountainWater",plaza,4.2,0.2,O.Y+1.95,C(90,120,170),Enum.Material.Glass,false).Transparency=0.3
	Kit.column(city,plaza+Vector3.new(0,1.9,0),4,0.6,trim,Enum.Material.Slate,true)
	local orb=Kit.deco(city,"FountainOrb",Vector3.new(1.6,1.6,1.6),CFrame.new(plaza+Vector3.new(0,7,0)),emblem,Enum.Material.Neon,Enum.PartType.Ball)
	Kit.light(orb,emblem,28,1.2)
	task.wait()

	-- Ponte sobre a ravina e cascata.
	local ravine=Kit.folder(model,"Ravine")
	Kit.bridge(ravine,"GreatBridge",L(0,0,-134),L(0,0,-240),O.Y,O.Y-60,12,5,wall,Enum.Material.Slate,trim)
	for i=0,5 do
		for _,s in {-1,1} do
			local p=L(s*5.4,1.9,-134-i*21.2)
			Kit.deco(ravine,"BridgeLamp",Vector3.new(0.9,1.2,0.9),CFrame.new(p+Vector3.new(0,0.8,0)),window,Enum.Material.Neon)
		end
	end
	Kit.fall(ravine,"RavineFall",L(150,0,-142),58,14,Vector3.new(0,0,-1),C(150,170,220))
	Kit.fall(ravine,"RavineFall",L(-180,0,-228),58,9,Vector3.new(0,0,1),C(150,170,220))
	for i=1,6 do
		local mist=Kit.deco(ravine,"RavineMist",Vector3.new(80,10,60),CFrame.new(L(-220+i*70,-50,-185)),C(130,120,170),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
		mist.Transparency=0.85
	end
	-- Barbacã: escadaria talhada até a cidadela alta.
	Kit.stairs(ravine,"BarbicanStair",L(0,0,-242),Vector3.new(0,0,-1),24,O.Y+U+0.3,1.35,24,O.Y-1,cobble,Enum.Material.Slate)
	for _,s in {-1,1} do
		Kit.spire(ravine,L(s*19,U,-280),12,26,18,wall,roof,Enum.Material.Slate,window)
		Kit.banner(ravine,CFrame.lookAt(L(s*19,U+14,-273.8),L(s*19,U+14,-250)),5,9,cloth,emblem,C(24,10,14))
	end
	task.wait()

	-- Cidadela alta: pátio (arena), alas, castelo e Selo.
	local keep=Kit.folder(model,"Keep")
	local court=L(0,0,-332)
	Kit.disc(keep,"CourtyardFloor",court,42,1,O.Y+U+0.4,cobble,Enum.Material.Cobblestone)
	for _,p in Kit.ring(keep,"CourtyardRunes",court,37,0.6,0.1,O.Y+U+0.46,40,emblem,Enum.Material.Neon,nil,nil,false) do p.CanQuery=false end
	for _,s in {-1,1} do
		Kit.block(keep,"WingWall",Vector3.new(10,22,96),CFrame.new(L(s*60,U+11,-340)),wall,Enum.Material.Slate)
		for k=0,3 do
			Kit.archway(keep,"WingArcade",L(s*54.8,U,-306-k*22),Vector3.new(-s,0,0),8,14,0.8,trim,Enum.Material.Slate,emblem)
			Kit.spire(keep,L(s*60,U+22,-300-k*26),7,10+k*3,14,wall,roof,Enum.Material.Slate,window,false)
		end
	end
	-- Fachada do castelo com átrio aberto e o Selo do Eclipse acima.
	local facadeZ=-392
	for _,s in {-1,1} do
		Kit.block(keep,"Facade",Vector3.new(32,46,8),CFrame.new(L(s*25,U+23,facadeZ)),wall,Enum.Material.Slate)
		Kit.spire(keep,L(s*44,U,facadeZ-4),14,58,30,wall,roof,Enum.Material.Slate,window)
		for k=0,2 do Kit.glow(keep,"FacadeWindow",Vector3.new(2,6,0.15),CFrame.new(L(s*(16+k*8),U+26,facadeZ+4.1)),window) end
	end
	Kit.block(keep,"FacadeLintel",Vector3.new(18,22,8),CFrame.new(L(0,U+35,facadeZ)),wall,Enum.Material.Slate)
	Kit.archway(keep,"AtriumArch",L(0,U,facadeZ+4.4),Vector3.new(0,0,1),14,24,1,trim,Enum.Material.Slate,emblem)
	Kit.block(keep,"AtriumBack",Vector3.new(18,24,2),CFrame.new(L(0,U+12,facadeZ-17)),dark,Enum.Material.Slate)
	for _,s in {-1,1} do Kit.block(keep,"AtriumSide",Vector3.new(2,24,16),CFrame.new(L(s*9,U+12,facadeZ-9)),dark,Enum.Material.Slate) end
	Kit.block(keep,"AtriumFloor",Vector3.new(18,1,18),CFrame.new(L(0,U+0.1,facadeZ-8)),cobble,Enum.Material.Cobblestone)
	local seal=CFrame.lookAt(L(0,U+36,facadeZ+4.3),L(0,U+36,facadeZ+40))
	Kit.deco(keep,"SealCorona",Vector3.new(0.3,22,22),seal*CFrame.Angles(0,math.pi/2,0),emblem,Enum.Material.Neon,Enum.PartType.Cylinder)
	Kit.deco(keep,"SealDisc",Vector3.new(0.4,18,18),seal*CFrame.new(0,0,-0.2)*CFrame.Angles(0,math.pi/2,0),C(14,10,20),Enum.Material.SmoothPlastic,Enum.PartType.Cylinder)
	for k=0,11 do
		local a=k*math.pi/6
		Kit.glow(keep,"SealRay",Vector3.new(0.8,4,0.12),seal*CFrame.Angles(0,0,a)*CFrame.new(0,13.5,0),emblem)
	end
	-- Corpo do castelo e torre central.
	Kit.block(keep,"KeepHall",Vector3.new(80,40,60),CFrame.new(L(0,U+20,facadeZ-50)),wall:Lerp(dark,0.2),Enum.Material.Slate)
	Kit.spire(keep,L(0,U+40,facadeZ-48),18,46,42,wall,roof,Enum.Material.Slate,window)
	for _,s in {-1,1} do
		Kit.spire(keep,L(s*30,U+40,facadeZ-62),10,22,24,wall,roof,Enum.Material.Slate,window)
		-- Coroa de agulhas ao redor da torre central (silhueta da referência 7).
		for k=0,2 do
			Kit.spire(keep,L(s*(14+k*8),U+40,facadeZ-36-k*7),5+k,10+k*9,12+k*4,wall,roof,Enum.Material.Slate,window,false)
		end
	end
	-- Fileiras de janelas acesas nas faces do castelo.
	for row=0,3 do
		for _,s in {-1,1} do
			for col=0,5 do
				if rng:NextNumber()<0.7 then
					local p=L(s*40.1,U+7+row*9,facadeZ-26-col*9)
					Kit.glow(keep,"KeepWindow",Vector3.new(0.15,3.2,1.6),CFrame.new(p),window)
				end
			end
		end
	end
	local exitGate=Kit.travelGate(keep,"ExitGate",L(0,U+0.6,facadeZ-12),Vector3.new(0,0,1),6.5,wall,C(186,120,255),"PASSAGEM OCULTA","Além do selo")
	exitGate:SetAttribute("RegionId","EclipseCitadel")
	task.wait()

	-- Horizonte de agulhas acesas.
	local skyline=Kit.folder(model,"Skyline")
	for i=1,26 do
		local s=if i%2==0 then -1 else 1
		local x=s*rng:NextNumber(90,190)
		local z=rng:NextNumber(-560,-260)
		Kit.spire(skyline,L(x,U,z),rng:NextNumber(8,16),rng:NextNumber(30,80),rng:NextNumber(18,34),wall:Lerp(dark,rng:NextNumber(0,0.5)),roof,Enum.Material.Slate,window,false)
		if i%8==0 then task.wait() end
	end
	for i=1,8 do
		Kit.spire(skyline,L(rng:NextNumber(-80,80),U,rng:NextNumber(-580,-480)),rng:NextNumber(10,18),rng:NextNumber(50,100),rng:NextNumber(26,40),wall:Lerp(dark,0.3),roof,Enum.Material.Slate,window,false)
	end

	-- Marcadores de jogabilidade futura.
	local slots=Kit.folder(model,"Slots")
	Kit.slot(slots,"Encounter","GateEncounter",L(0,3,10),16,"Diante do portão")
	Kit.slot(slots,"Encounter","PlazaEncounter",L(0,3,-81),16,"Praça da fonte")
	Kit.slot(slots,"Encounter","BridgeEncounter",L(0,3,-187),12,"Ponte da ravina")
	Kit.slot(slots,"BossArena","CourtyardArena",L(0,U+3,-332),40,"Pátio do castelo")
	Kit.slot(slots,"Objective","EclipseSeal",L(0,U+3,facadeZ+10),12,"Selo do Eclipse")
	Kit.arrival(slots,"SafePlaza",L(0,0.9,-66),Vector3.new(0,0,-1),emblem,wall)
	Kit.arrival(slots,"SafeBarbican",L(0,U+0.7,-292),Vector3.new(0,0,-1),emblem,wall)
	arrival.Parent=model
	return model
end

return Region
