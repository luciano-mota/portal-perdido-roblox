--!strict
-- Fase 6 — Domínio do Vazio. Referência: assets/world/references/05-dominio-do-vazio.png.
-- Fortaleza suspensa sobre o vazio dimensional. Varanda de chegada com balaustrada, lanternas de
-- cristal e estandartes → ponte quebrada com fissuras luminosas → ilha do santuário → pedras de
-- salto → ilha da âncora (objetivo) → escadaria e ponte → platô da fortaleza: Átrio do Regente
-- (arena final) diante da fachada com o Portal Primordial (saída/encerramento). Abaixo, o
-- vórtice violeta com arcos partidos e rochas à deriva.
local Kit=require(script.Parent.Parent.RegionKit)
local Region={}

local C=Color3.fromRGB
local stone=C(112,104,128)
local dark=C(66,58,84)
local rock=C(84,72,102)
local gold=C(198,160,90)
local violet=C(176,104,255)
local cyan=C(90,236,236)
local cloth=C(70,36,104)
local P=30 -- topo do platô da fortaleza

-- Lanterna de cristal: base dourada e cristal turquesa.
local function lantern(parent: Instance,base: Vector3)
	Kit.block(parent,"LanternPost",Vector3.new(1.6,3.2,1.6),CFrame.new(base+Vector3.new(0,1.6,0)),stone,Enum.Material.Slate)
	Kit.pyramid(parent,"LanternCrown",base+Vector3.new(0,3.2,0),2.2,0.8,gold,Enum.Material.Metal)
	Kit.crystal(parent,base+Vector3.new(0,3.6,0),3.4,1.1,cyan,0,0,0.6,false)
end

-- Fissura luminosa em zigue-zague no piso.
local function crack(parent: Instance,a: Vector3,b: Vector3,rng: Random)
	local points={a}
	for k=1,4 do
		local p=a:Lerp(b,k/5)
		table.insert(points,p+Vector3.new(rng:NextNumber(-1.5,1.5),0,rng:NextNumber(-1.5,1.5)))
	end
	table.insert(points,b)
	for k=1,#points-1 do
		local p,q=points[k],points[k+1]
		Kit.glow(parent,"VoidCrack",Vector3.new(0.25,0.08,(q-p).Magnitude+0.2),CFrame.lookAt((p+q)/2,q),cyan)
	end
end

function Region.build(world: Instance,O: Vector3): Model
	local function L(x: number,y: number,z: number): Vector3 return O+Vector3.new(x,y,z) end
	local rng=Random.new(60606)
	local model=Instance.new("Model") model.Name="VoidDominion" model:SetAttribute("RegionId","VoidDominion") model.Parent=world

	-- Varanda de chegada.
	local balcony=Kit.folder(model,"Balcony")
	Kit.block(balcony,"BalconyFloor",Vector3.new(44,3,36),CFrame.new(L(0,-1.5,42)),stone,Enum.Material.Slate)
	Kit.deco(balcony,"BalconyRock",Vector3.new(50,36,42),CFrame.new(L(0,-20,44)),rock,Enum.Material.Rock,Enum.PartType.Ball)
	local arrival=Kit.arrival(balcony,"Arrival",L(0,0.3,44),Vector3.new(0,0,-1),cyan,stone)
	for _,s in {-1,1} do
		Kit.balustrade(balcony,L(s*21.5,0,58),L(s*21.5,0,25),stone,Enum.Material.Slate)
		Kit.balustrade(balcony,L(s*21.5,0,25),L(s*6,0,25),stone,Enum.Material.Slate)
		for k=0,2 do lantern(balcony,L(s*21.5,0,54-k*13)) end
		lantern(balcony,L(s*6,0,25))
		crack(balcony,L(s*4,0.02,50),L(s*12,0.02,28),rng)
	end
	Kit.archway(balcony,"VoidGateway",L(0,0,59),Vector3.new(0,0,-1),14,24,4,stone,Enum.Material.Slate,cyan)
	for _,s in {-1,1} do
		Kit.block(balcony,"GatewayWall",Vector3.new(12,26,4),CFrame.new(L(s*16,13,59)),stone:Lerp(dark,0.3),Enum.Material.Slate)
		Kit.banner(balcony,CFrame.lookAt(L(s*15,16,56.8),L(s*15,16,30)),5,11,cloth,gold,C(36,16,56))
	end
	Kit.flowers(balcony,L(-14,0,52),5,14,{violet,C(140,110,255)},rng,O.Y)
	Kit.flowers(balcony,L(14,0,52),5,14,{violet,C(140,110,255)},rng,O.Y)
	task.wait()

	-- Ponte quebrada até a ilha do santuário.
	local route=Kit.folder(model,"Route")
	Kit.bridge(route,"BrokenBridge",L(0,0,25),L(0,0,-102),O.Y,O.Y-60,10,5,stone,Enum.Material.Slate,stone,true)
	for k=0,4 do crack(route,L(rng:NextNumber(-3,3),0.02,20-k*25),L(rng:NextNumber(-3,3),0.02,2-k*25),rng) end
	for k=0,5 do
		for _,s in {-1,1} do lantern(route,L(s*4.2,0,18-k*24)) end
	end
	local i1=Vector3.new(0,0,-122)
	Kit.island(route,"ShrineIsland",L(i1.X,0,i1.Z),O.Y,20,stone,Enum.Material.Slate,rock,rng,36)
	for k=0,5 do
		local a=k*math.pi/3+0.4
		Kit.column(route,L(i1.X+math.cos(a)*15,0,i1.Z+math.sin(a)*15),if k%2==0 then 10 else 5,1,stone,Enum.Material.Slate,k%2==0,gold)
	end
	Kit.fall(route,"VoidFall",L(i1.X+12,-1,i1.Z+14),90,4,Vector3.new(0.6,0,0.8),cyan,true)
	-- Pedras de salto até a ilha da âncora.
	local i2=Vector3.new(50,8,-212)
	local dir=Vector3.new(i2.X-i1.X,0,i2.Z-i1.Z).Unit
	local startEdge=i1+dir*20
	local endEdge=Vector3.new(i2.X,0,i2.Z)-dir*20
	for k=1,6 do
		local p=startEdge:Lerp(endEdge,k/7)
		Kit.stepStone(route,L(p.X,0,p.Z),O.Y+i2.Y*k/7,3.2,stone,rock,k)
	end
	Kit.island(route,"AnchorIsland",L(i2.X,0,i2.Z),O.Y+i2.Y,20,stone,Enum.Material.Slate,rock,rng,36)
	Kit.crystal(route,L(i2.X,i2.Y,i2.Z),16,4,violet,0,0,0.3,true)
	for k=0,3 do
		local a=k*math.pi/2+0.4
		Kit.crystal(route,L(i2.X+math.cos(a)*6,i2.Y,i2.Z+math.sin(a)*6),7,1.6,cyan,math.sin(a)*0.4,-math.cos(a)*0.4,a,false)
	end
	Kit.ring(route,"AnchorRunes",L(i2.X,0,i2.Z),12,0.5,0.1,O.Y+i2.Y+0.06,32,cyan,Enum.Material.Neon,nil,nil,false)
	task.wait()

	-- Subida ao platô: escadaria e ponte suspensa.
	Kit.stairs(route,"PlateauStair",L(i2.X,i2.Y,i2.Z-18),Vector3.new(0,0,-1),18,O.Y+P,1.3,10,O.Y+i2.Y-6,stone,Enum.Material.Slate)
	Kit.bridge(route,"PlateauBridge",L(i2.X,0,i2.Z-41),L(i2.X,0,-326),O.Y+P,O.Y+P-50,10,4,stone,Enum.Material.Slate,gold,true)
	Kit.block(route,"StairLanding",Vector3.new(12,2,6),CFrame.new(L(i2.X,P-1,i2.Z-42)),stone,Enum.Material.Slate)

	-- Platô da fortaleza: Átrio do Regente, fachada, Portal Primordial e agulhas.
	local fortress=Kit.folder(model,"Fortress")
	Kit.island(fortress,"FortressPlateau",L(0,0,-392),O.Y+P,86,stone,Enum.Material.Slate,rock,rng,120)
	Kit.disc(fortress,"AtriumFloor",L(0,0,-372),42,0.6,O.Y+P+0.3,stone:Lerp(gold,0.08),Enum.Material.Marble)
	for _,r in {38,26,12} do
		for _,p in Kit.ring(fortress,"AtriumSigil",L(0,0,-372),r,if r==38 then 0.8 else 0.5,0.1,O.Y+P+0.36,44,if r==26 then cyan else gold,Enum.Material.Neon,nil,nil,false) do p.CanQuery=false end
	end
	for k=0,5 do crack(fortress,L(0,P+0.62,-372),L(math.cos(k*1.05)*40,P+0.62,-372+math.sin(k*1.05)*40),rng) end
	for k=0,7 do
		local a=math.pi+k*math.pi/7
		local p=L(math.cos(a)*-46,P,-372+math.sin(a)*-46)
		lantern(fortress,p)
	end
	local facadeZ=-424
	for _,s in {-1,1} do
		Kit.block(fortress,"Facade",Vector3.new(46,56,10),CFrame.new(L(s*35,P+28,facadeZ)),stone,Enum.Material.Slate)
		Kit.banner(fortress,CFrame.lookAt(L(s*24,P+34,facadeZ+5.2),L(s*24,P+34,facadeZ+40)),7,16,cloth,gold,C(36,16,56))
		Kit.banner(fortress,CFrame.lookAt(L(s*46,P+30,facadeZ+5.2),L(s*46,P+30,facadeZ+40)),6,14,cloth,gold,C(36,16,56))
		for k=0,2 do
			Kit.spire(fortress,L(s*(18+k*20),P+56,facadeZ-2),8+k,14+k*8,18+k*4,stone,dark,Enum.Material.Slate,violet,false)
		end
		Kit.spire(fortress,L(s*66,P,facadeZ-10),16,64,36,stone,dark,Enum.Material.Slate,violet)
	end
	Kit.block(fortress,"FacadeLintel",Vector3.new(24,26,10),CFrame.new(L(0,P+43,facadeZ)),stone,Enum.Material.Slate)
	Kit.archway(fortress,"GreatGate",L(0,P,facadeZ+5.4),Vector3.new(0,0,1),22,30,1.2,gold,Enum.Material.Metal,violet)
	Kit.block(fortress,"GateRecess",Vector3.new(24,30,2),CFrame.new(L(0,P+15,facadeZ-8)),C(30,20,44),Enum.Material.Slate)
	local exitGate=Kit.travelGate(fortress,"ExitGate",L(0,P+0.6,facadeZ-2),Vector3.new(0,0,1),10,gold:Lerp(dark,0.4),violet,"PORTAL PRIMORDIAL","O selo de todos os mundos")
	exitGate:SetAttribute("RegionId","VoidDominion")
	Kit.block(fortress,"KeepBody",Vector3.new(110,60,46),CFrame.new(L(0,P+30,facadeZ-34)),stone:Lerp(dark,0.3),Enum.Material.Slate)
	Kit.spire(fortress,L(0,P+60,facadeZ-36),22,40,48,stone,dark,Enum.Material.Slate,violet,false)
	-- Sigilo de cristal acima da torre central.
	local sigil=CFrame.lookAt(L(0,P+96,facadeZ-7),L(0,P+96,facadeZ+40))
	Kit.verticalRing(fortress,"SigilRing",sigil,26,2.4,2.4,36,gold,Enum.Material.Metal)
	Kit.verticalRing(fortress,"SigilGlow",sigil,21,0.6,0.6,32,cyan,Enum.Material.Neon,nil,nil,true)
	Kit.crystal(fortress,(sigil*CFrame.new(0,-12,0)).Position,24,6,violet,0,0,0.785,false)
	for _,s in {-1,1} do
		Kit.verticalRing(fortress,"Crescent",sigil*CFrame.new(s*12,0,-4)*CFrame.Angles(0,0,s*0.3),44,4,4,18,gold:Lerp(dark,0.2),Enum.Material.Metal,if s<0 then math.pi*0.55 else -math.pi*0.45,if s<0 then math.pi*1.45 else math.pi*0.45)
	end
	task.wait()

	-- Vórtice do vazio, arcos partidos, rochas à deriva e fortalezas distantes.
	local void=Kit.folder(model,"Vortex")
	local vc=L(0,-240,-250)
	for arm=1,4 do
		for step=1,22 do
			local function point(t: number): Vector3
				local a=t*math.pi*2.4+arm*math.pi/2
				local r=12+t*300
				return vc+Vector3.new(math.cos(a)*r,t*40,math.sin(a)*r)
			end
			local a,b=point((step-1)/22),point(step/22)
			local width=4+step*0.7
			local band=Kit.glow(void,"VortexArm",Vector3.new(width,1,(b-a).Magnitude+4),CFrame.lookAt((a+b)/2,b),if arm%2==0 then violet else C(220,120,255):Lerp(cyan,step/40),0.25+step/22*0.55)
			band.Shape=Enum.PartType.Block
		end
	end
	local eye=Kit.deco(void,"VortexEye",Vector3.new(60,14,60),CFrame.new(vc),C(240,200,255),Enum.Material.Neon,Enum.PartType.Ball)
	eye.Transparency=0.2
	for i=1,7 do
		local a=i*math.pi*2/7
		local frame=CFrame.new(vc+Vector3.new(math.cos(a)*rng:NextNumber(140,220),rng:NextNumber(70,150),math.sin(a)*rng:NextNumber(140,220)))*CFrame.Angles(0,-a,rng:NextNumber(-0.3,0.3))
		Kit.verticalRing(void,"BrokenArc",frame,rng:NextNumber(40,70),6,8,12,rock,Enum.Material.Slate,rng:NextNumber(0,1),rng:NextNumber(2,3.2))
		Kit.verticalRing(void,"BrokenArcRunes",frame*CFrame.new(0,0,-4.1),rng:NextNumber(36,38),0.5,0.2,10,cyan,Enum.Material.Neon,0.2,2,true)
	end
	for i=1,34 do
		local a=rng:NextNumber(0,math.pi*2)
		local r=rng:NextNumber(110,330)
		local size=rng:NextNumber(5,22)
		Kit.rock(void,L(math.cos(a)*r,rng:NextNumber(-170,40),math.sin(a)*r-250),Vector3.new(size,size*1.3,size),rock,Enum.Material.Rock,i,false).CanQuery=false
		if i%12==0 then task.wait() end
	end
	for i,p in {Vector3.new(-230,40,-220),Vector3.new(240,60,-330),Vector3.new(-200,20,-520),Vector3.new(180,80,-560),Vector3.new(-120,90,-60)} do
		Kit.island(void,"DistantBastion",L(p.X,0,p.Z),O.Y+p.Y,24,stone,Enum.Material.Slate,rock,rng,46)
		for k=0,2 do
			Kit.spire(void,L(p.X+(k-1)*12,p.Y,p.Z+rng:NextNumber(-6,6)),7+k*2,20+k*12,14+k*4,stone,dark,Enum.Material.Slate,violet,false)
		end
		Kit.fall(void,"BastionFall",L(p.X+18,p.Y-2,p.Z),70,4,Vector3.new(1,0,0),cyan,true)
		if i==1 then Kit.bridge(void,"BastionBridge",L(p.X+24,0,p.Z),L(p.X+80,0,p.Z+20),O.Y+p.Y,O.Y+p.Y-30,6,3,stone,Enum.Material.Slate,gold,true) end
	end

	-- Marcadores de jogabilidade futura.
	local slots=Kit.folder(model,"Slots")
	Kit.slot(slots,"Encounter","ShrineEncounter",L(i1.X,3,i1.Z),18,"Ilha do santuário")
	Kit.slot(slots,"Objective","VoidAnchor",L(i2.X,i2.Y+3,i2.Z),16,"Âncora do vazio")
	Kit.slot(slots,"BossArena","RegentAtrium",L(0,P+3,-372),40,"Átrio do Regente")
	Kit.slot(slots,"FinalPortal","PortalPrimordial",L(0,P+10,facadeZ-2),12,"Portal Primordial")
	Kit.arrival(slots,"SafeShrine",L(i1.X,0.4,i1.Z+12),Vector3.new(0,0,-1),violet,stone)
	Kit.arrival(slots,"SafeAnchor",L(i2.X-10,i2.Y+0.4,i2.Z+6),Vector3.new(0,0,-1),violet,stone)
	Kit.arrival(slots,"SafeAtrium",L(30,P+0.7,-330),Vector3.new(0,0,-1),violet,stone)
	arrival.Parent=model
	return model
end

return Region
