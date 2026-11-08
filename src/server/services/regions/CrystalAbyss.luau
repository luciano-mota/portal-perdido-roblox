--!strict
-- Fase 2 — Abismo de Cristal. Referência: assets/world/references/03-abismo-de-cristal.png.
-- Penhasco de chegada com arcos e glicínias → ponte em arcos → ilha-pilar → ponte → ilha das
-- ruínas → passarela em anel ao redor do Cristal-Mãe → ilha oeste → escadaria → terraço da
-- catedral de cristal (arena) → portal de saída. Fundo do abismo é decorativo (queda = retorno).
local Kit=require(script.Parent.Parent.RegionKit)
local Region={}

local C=Color3.fromRGB
local stone=C(170,160,168)
local dark=C(102,94,112)
local moss=C(104,126,96)
local cyan=C(110,232,236)
local violet=C(186,140,255)
local pink=C(232,170,240)
local gold=C(196,166,108)
local crystals={cyan,C(150,220,255),violet,pink}

function Region.build(world: Instance,O: Vector3): Model
	local function L(x: number,y: number,z: number): Vector3 return O+Vector3.new(x,y,z) end
	local rng=Random.new(20202)
	local model=Instance.new("Model") model.Name="CrystalAbyss" model:SetAttribute("RegionId","CrystalAbyss") model.Parent=world
	local terrain=workspace.Terrain
	terrain:SetMaterialColor(Enum.Material.Limestone,C(150,140,158))
	terrain:SetMaterialColor(Enum.Material.Grass,C(98,122,88))
	terrain:SetMaterialColor(Enum.Material.Ground,C(104,118,90))

	-- Terreno: penhasco de chegada, paredes laterais, colunas das ilhas, terraço e fundo.
	terrain:FillBlock(CFrame.new(L(0,-75,45)),Vector3.new(184,150,150),Enum.Material.Limestone)
	terrain:FillBlock(CFrame.new(L(0,-2,50)),Vector3.new(176,4,136),Enum.Material.Ground)
	for i=0,10 do
		terrain:FillBall(L(-88+i*17.6,rng:NextNumber(-40,-8),-30+rng:NextNumber(-4,2)),rng:NextNumber(8,13),Enum.Material.Limestone)
	end
	task.wait()
	-- Paredes do abismo: colunas de rocha de alturas variadas (silhueta de penhascos, não caixa).
	for _,s in {-1,1} do
		for i=0,25 do
			local z=110-i*29+rng:NextNumber(-6,6)
			for k=0,2 do
				local x=s*(158+k*34+rng:NextNumber(-6,6))
				local top=rng:NextNumber(30,70)+k*rng:NextNumber(8,22)+(if i%5==2 then 40 else 0)
				local r=rng:NextNumber(19,27)
				terrain:FillCylinder(CFrame.new(L(x,(top-155)/2,z)),top+155,r,Enum.Material.Limestone)
				terrain:FillBall(L(x,top,z),r*0.85,Enum.Material.Limestone)
				if k==0 then
					-- Saliências na face interna e musgo no topo.
					terrain:FillBall(L(x-s*r*0.7,top-rng:NextNumber(30,90),z),rng:NextNumber(9,15),Enum.Material.Limestone)
					if i%2==0 then terrain:FillBall(L(x,top+r*0.6,z),r*0.55,Enum.Material.Grass) end
				end
			end
			if i%6==5 then task.wait() end
		end
	end
	for _,p in {Vector2.new(0,-120),Vector2.new(95,-195),Vector2.new(-30,-305)} do
		terrain:FillCylinder(CFrame.new(L(p.X,-76,p.Y)),150,17,Enum.Material.Limestone)
		for k=0,5 do
			terrain:FillBall(L(p.X+math.cos(k)*14,-20-k*18,p.Y+math.sin(k)*14),rng:NextNumber(7,10),Enum.Material.Limestone)
		end
	end
	terrain:FillBlock(CFrame.new(L(0,-61,-470)),Vector3.new(300,178,270),Enum.Material.Limestone)
	terrain:FillBlock(CFrame.new(L(0,26,-470)),Vector3.new(296,4,262),Enum.Material.Ground)
	-- Face do terraço e bordas laterais irregulares; ruínas de rocha mais altas no fundo.
	for i=0,14 do
		terrain:FillBall(L(-140+i*20,rng:NextNumber(-60,10),-336+rng:NextNumber(-4,3)),rng:NextNumber(9,14),Enum.Material.Limestone)
	end
	for i=0,9 do
		for _,s in {-1,1} do
			terrain:FillBall(L(s*(150+rng:NextNumber(-6,8)),rng:NextNumber(10,40),-350-i*25),rng:NextNumber(14,22),Enum.Material.Limestone)
		end
		terrain:FillBall(L(-130+i*29,rng:NextNumber(45,75),-600+rng:NextNumber(-10,10)),rng:NextNumber(22,34),Enum.Material.Limestone)
	end
	-- Corredor da escadaria talhado na face do terraço.
	terrain:FillBlock(CFrame.new(L(-30,18,-344)),Vector3.new(14,40,26),Enum.Material.Air)
	terrain:FillBlock(CFrame.new(L(0,-155,-250)),Vector3.new(400,10,760),Enum.Material.Limestone)
	-- Serras ao fundo, fora do percurso.
	for i=0,8 do
		terrain:FillBall(L(-320+i*80,rng:NextNumber(20,70),-760+rng:NextNumber(-40,40)),rng:NextNumber(60,90),Enum.Material.Limestone)
	end
	task.wait()

	-- Chegada: praça com círculo rúnico, arcos em ruína e glicínias.
	local arrivalFolder=Kit.folder(model,"Arrival")
	local arrival=Kit.arrival(arrivalFolder,"Arrival",L(0,0.25,30),Vector3.new(0,0,-1),cyan,stone)
	Kit.disc(arrivalFolder,"ArrivalPlaza",L(0,0,30),13,1,O.Y+0.25,stone,Enum.Material.Cobblestone)
	-- Círculo mágico com estrela de oito pontas no piso da praça (referência 3).
	local center=L(0,0.32,30)
	for _,p in Kit.ring(arrivalFolder,"PlazaCircle",center,10.5,0.3,0.08,O.Y+0.32,40,cyan,Enum.Material.Neon,nil,nil,false) do p.CanQuery=false p.CastShadow=false end
	for k=0,7 do
		local a=k*math.pi/4
		local b=(k+3)*math.pi/4
		local pa=center+Vector3.new(math.cos(a)*10,0,math.sin(a)*10)
		local pb=center+Vector3.new(math.cos(b)*10,0,math.sin(b)*10)
		Kit.glow(arrivalFolder,"PlazaStar",Vector3.new(0.22,0.06,(pb-pa).Magnitude),CFrame.lookAt((pa+pb)/2,pb),cyan,0.15)
	end
	for i=0,3 do
		local z=12-i*11
		Kit.block(arrivalFolder,"CliffPath",Vector3.new(8,0.5,11.2),CFrame.new(L(0,0.0,z))*CFrame.Angles(0,rng:NextNumber(-0.04,0.04),0),stone:Lerp(dark,0.15),Enum.Material.Cobblestone)
	end
	for i=0,2 do
		for _,s in {-1,1} do
			Kit.archway(arrivalFolder,"RuinArch",L(s*15,0,18-i*16),Vector3.new(s,0,0),8,15-i,2.4,stone,Enum.Material.Limestone,cyan)
		end
	end
	local function trunk(a: Vector3,b: Vector3)
		local mid=a:Lerp(b,0.5)+Vector3.new(1,0,0.5)
		Kit.block(arrivalFolder,"WisteriaTrunk",Vector3.new(2,(mid-a).Magnitude,2),CFrame.lookAt((a+mid)/2,mid)*CFrame.Angles(math.pi/2,0,0),C(92,74,66),Enum.Material.Wood)
		Kit.block(arrivalFolder,"WisteriaTrunk",Vector3.new(1.5,(b-mid).Magnitude,1.5),CFrame.lookAt((mid+b)/2,b)*CFrame.Angles(math.pi/2,0,0),C(92,74,66),Enum.Material.Wood)
	end
	local function wisteria(base: Vector3,seed: number)
		local r=Random.new(seed)
		local top=base+Vector3.new(r:NextNumber(-2,2),r:NextNumber(14,18),r:NextNumber(-2,2))
		trunk(base,top)
		for k=1,7 do
			local a=k*2.4+seed
			local p=top+Vector3.new(math.cos(a)*r:NextNumber(3,6),r:NextNumber(-2,2),math.sin(a)*r:NextNumber(3,6))
			Kit.deco(arrivalFolder,"WisteriaCanopy",Vector3.new(r:NextNumber(4,5.5),r:NextNumber(2.4,3.2),r:NextNumber(4,5.5)),CFrame.new(p),C(112,132,86),Enum.Material.Grass,Enum.PartType.Ball)
			for j=1,4 do
				local hang=p+Vector3.new(r:NextNumber(-2.4,2.4),-1.5-r:NextNumber(0,2.5),r:NextNumber(-2.4,2.4))
				Kit.deco(arrivalFolder,"WisteriaBloom",Vector3.new(0.8,r:NextNumber(2.5,4.5),0.8),CFrame.new(hang),C(170,120,232),Enum.Material.Neon,Enum.PartType.Ball)
			end
		end
	end
	wisteria(L(-34,0,40),3) wisteria(L(32,0,52),7) wisteria(L(-52,0,4),11)
	Kit.flowers(arrivalFolder,L(-24,0,30),12,26,{violet,C(120,150,255),pink},rng,O.Y)
	Kit.flowers(arrivalFolder,L(26,0,20),12,22,{violet,cyan},rng,O.Y)
	for k=1,6 do Kit.rock(arrivalFolder,L(rng:NextNumber(-60,60),0.5,rng:NextNumber(-20,70)),Vector3.new(6,3,5)*rng:NextNumber(0.7,1.4),stone:Lerp(moss,0.2),Enum.Material.Limestone,k,true) end
	task.wait()

	-- Percurso sobre o abismo.
	local route=Kit.folder(model,"Route")
	Kit.bridge(route,"ChasmBridge",L(0,0,-26),L(0,0,-104),O.Y,O.Y-150,9,4,stone,Enum.Material.Limestone,gold)
	Kit.disc(route,"PillarIsland",L(0,0,-120),18,2,O.Y,stone:Lerp(moss,0.15),Enum.Material.Cobblestone)
	local p2c=Vector3.new(95,0,-195)
	local dirA=(p2c-Vector3.new(0,0,-120)).Unit
	Kit.bridge(route,"EastBridge",L(dirA.X*16,0,-120+dirA.Z*16),L(p2c.X-dirA.X*16,0,p2c.Z-dirA.Z*16),O.Y,O.Y-150,8,3,stone,Enum.Material.Limestone,gold)
	Kit.disc(route,"RuinIsland",L(p2c.X,0,p2c.Z),18,2,O.Y,stone:Lerp(moss,0.15),Enum.Material.Cobblestone)
	-- Passarela em anel ao redor do Cristal-Mãe.
	local ringC=Vector3.new(70,0,-275)
	Kit.ring(route,"HaloWalk",L(ringC.X,0,ringC.Z),30,7,1.2,O.Y,32,stone,Enum.Material.Limestone)
	-- Corrimão externo com aberturas nas duas pontes (norte = pi/2, oeste = pi).
	Kit.ring(route,"HaloRail",L(ringC.X,0,ringC.Z),33.2,0.6,1.1,O.Y+1.1,8,gold,Enum.Material.Limestone,math.pi/2+0.22,math.pi-0.2)
	Kit.ring(route,"HaloRail",L(ringC.X,0,ringC.Z),33.2,0.6,1.1,O.Y+1.1,24,gold,Enum.Material.Limestone,math.pi+0.2,math.pi*2.5-0.22)
	Kit.ring(route,"HaloRunes",L(ringC.X,-1.3,ringC.Z),30,1,0.3,O.Y-1.25,32,cyan,Enum.Material.Neon,nil,nil,false)
	local toRing=(ringC+Vector3.new(0,0,30)-p2c).Unit
	Kit.bridge(route,"HaloBridgeNorth",L(p2c.X+toRing.X*16,0,p2c.Z+toRing.Z*16),L(ringC.X,0,ringC.Z+33.5),O.Y,O.Y-150,6,2,stone,Enum.Material.Limestone,gold)
	local p3c=Vector3.new(-30,0,-305)
	local toP3=(p3c-(ringC-Vector3.new(30,0,0))).Unit
	Kit.bridge(route,"HaloBridgeWest",L(ringC.X-33.5,0,ringC.Z),L(p3c.X-toP3.X*16,0,p3c.Z-toP3.Z*16),O.Y,O.Y-150,7,3,stone,Enum.Material.Limestone,gold)
	Kit.disc(route,"WestIsland",L(p3c.X,0,p3c.Z),18,2,O.Y,stone:Lerp(moss,0.15),Enum.Material.Cobblestone)
	-- Ilha oeste → terraço: escadaria talhada.
	Kit.stairs(route,"TerraceStair",L(-30,0,-319),Vector3.new(0,0,-1),24,O.Y+28.3,1.35,10,O.Y-2,stone,Enum.Material.Limestone)
	task.wait()

	-- Cristal-Mãe, cristais do abismo e pingentes sob as pontes.
	local crystalsFolder=Kit.folder(model,"Crystals")
	Kit.crystal(crystalsFolder,L(ringC.X,-150,ringC.Z),215,17,cyan,0,0,0.3,true)
	for k=0,3 do
		local a=k*math.pi/2+math.pi/4
		local inner=L(ringC.X+math.cos(a)*8,40,ringC.Z+math.sin(a)*8)
		local outer=L(ringC.X+math.cos(a)*30,1,ringC.Z+math.sin(a)*30)
		local beam=Kit.deco(crystalsFolder,"HaloChain",Vector3.new(0.6,0.6,(outer-inner).Magnitude),CFrame.lookAt((inner+outer)/2,outer),gold,Enum.Material.Metal)
		beam.CastShadow=false
	end
	local spots={Vector2.new(-60,-80),Vector2.new(55,-90),Vector2.new(-80,-190),Vector2.new(30,-170),Vector2.new(130,-260),Vector2.new(10,-240),Vector2.new(-90,-280),Vector2.new(120,-320),Vector2.new(-110,-110),Vector2.new(60,-40),Vector2.new(-40,-220),Vector2.new(20,-320)}
	for i,p in spots do
		Kit.crystalCluster(crystalsFolder,L(p.X,-150,p.Y),rng:NextNumber(70,140),rng,crystals,false)
		if i%4==0 then task.wait() end
	end
	-- Cristais presos às paredes: raio horizontal do centro do abismo até a rocha.
	local wallParams=RaycastParams.new() wallParams.FilterType=Enum.RaycastFilterType.Include wallParams.FilterDescendantsInstances={terrain}
	for i=1,14 do
		local s=if i%2==0 then -1 else 1
		local from=L(s*60,rng:NextNumber(-60,30),rng:NextNumber(-320,-20))
		local hit=workspace:Raycast(from,Vector3.new(s*200,0,0),wallParams)
		if hit then Kit.crystalCluster(crystalsFolder,hit.Position+Vector3.new(s*2,-3,0),rng:NextNumber(16,30),rng,crystals,false) end
	end
	for _,z in {-46,-66,-86} do
		Kit.crystal(crystalsFolder,L(0,-9,z),8,1.6,cyan,math.pi,0,0.4,false)
	end
	Kit.crystalCluster(crystalsFolder,L(p2c.X+11,0,p2c.Z-6),14,rng,crystals,true)
	Kit.crystalCluster(crystalsFolder,L(-9,0,-129),10,rng,crystals,true)
	Kit.crystalCluster(crystalsFolder,L(p3c.X-12,0,p3c.Z+4),12,rng,crystals,true)
	task.wait()

	-- Ruínas da ilha leste (objetivo futuro: reflexos).
	local ruins=Kit.folder(model,"EchoRuins")
	for i=0,4 do
		local a=math.pi*0.15+i*math.pi*0.25
		local p=L(p2c.X+math.cos(a)*14,0,p2c.Z-math.sin(a)*14)
		Kit.column(ruins,p,if i%2==0 then 9 else 5,0.9,stone,Enum.Material.Limestone,i%2==0,gold)
	end
	Kit.archway(ruins,"EchoArch",L(p2c.X,0,p2c.Z-13),Vector3.new(0,0,1),7,14,2.2,stone,Enum.Material.Limestone,violet)

	-- Cascatas das paredes do abismo e névoa.
	local water=Kit.folder(model,"Waterfalls")
	for i,p in {Vector3.new(-148,40,-60),Vector3.new(146,45,-140),Vector3.new(-150,30,-230),Vector3.new(148,50,-300),Vector3.new(-120,28,-337),Vector3.new(80,28,-337)} do
		local facing=if math.abs(p.Z+337)<1 then Vector3.new(0,0,1) elseif p.X<0 then Vector3.new(1,0,0) else Vector3.new(-1,0,0)
		Kit.fall(water,"AbyssFall",L(p.X,p.Y,p.Z),120,if i%2==0 then 9 else 6,facing,C(200,236,248))
	end
	-- Referência 3: cristais gigantes no alto dos penhascos e fios de cascata descendo das bordas.
	local downParams=RaycastParams.new() downParams.FilterType=Enum.RaycastFilterType.Include downParams.FilterDescendantsInstances={terrain}
	for i=1,16 do
		local s=if i%2==0 then -1 else 1
		local p=L(s*rng:NextNumber(150,175),220,rng:NextNumber(-470,60))
		local hit=workspace:Raycast(p,Vector3.new(0,-320,0),downParams)
		if hit and hit.Position.Y>O.Y+20 then
			Kit.crystalCluster(crystalsFolder,hit.Position-Vector3.new(0,2,0),rng:NextNumber(26,52),rng,crystals,false)
			if i%3==0 then Kit.fall(water,"CliffThread",hit.Position+Vector3.new(-s*10,-2,0),hit.Position.Y-(O.Y-60),2.4,Vector3.new(-s,0,0),C(214,240,250)) end
		end
		if i%6==0 then task.wait() end
	end
	for i=1,10 do
		local mist=Kit.deco(water,"AbyssMist",Vector3.new(90,14,70),CFrame.new(L(rng:NextNumber(-110,110),-75+rng:NextNumber(-10,10),-40-i*30)),C(232,226,246),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
		mist.Transparency=0.86 mist.CastShadow=false
	end
	task.wait()

	-- Terraço da catedral de cristal: arena e portal de saída.
	local cathedral=Kit.folder(model,"CrystalCathedral")
	Kit.disc(cathedral,"CathedralFloor",L(0,0,-435),40,1,O.Y+28.4,stone,Enum.Material.Cobblestone)
	Kit.ring(cathedral,"ArenaRunes",L(0,0,-435),36,0.5,0.1,O.Y+28.46,40,cyan,Enum.Material.Neon,nil,nil,false)
	-- Lajes do alto da escadaria até a arena.
	for k=0,9 do
		local p=L(-30,0,-352):Lerp(L(-14,0,-398),k/9)
		Kit.block(cathedral,"TerraceFlagstone",Vector3.new(rng:NextNumber(6,8),0.6,4.6),CFrame.new(p.X,O.Y+28.1,p.Z)*CFrame.Angles(0,rng:NextNumber(-0.3,0.3)-0.33,0),stone:Lerp(dark,rng:NextNumber(0,0.25)),Enum.Material.Cobblestone)
	end
	for _,s in {-1,1} do
		for i=0,4 do
			Kit.archway(cathedral,"Arcade",L(s*50,28,-392-i*20),Vector3.new(s,0,0),10,20,3,stone,Enum.Material.Limestone,if i%2==0 then cyan else violet)
		end
		Kit.crystalCluster(cathedral,L(s*62,28,-505),46,rng,crystals,true)
		Kit.crystalCluster(cathedral,L(s*36,28,-380),18,rng,crystals,true)
	end
	-- Anéis partidos (portais quebrados da referência) atrás da arena.
	for i,x in {-40,0,40} do
		Kit.verticalRing(cathedral,"BrokenRing",CFrame.new(L(x,58,-520-i*6))*CFrame.Angles(0,0.2*(i-2),0),24,3.2,4,12,stone,Enum.Material.Limestone,0.5+i*0.7,0.5+i*0.7+math.pi*1.15)
	end
	local exitGate=Kit.travelGate(cathedral,"ExitGate",L(0,28.4,-492),Vector3.new(0,0,1),9,stone,cyan,"PASSAGEM DE CRISTAL","Siga a travessia")
	task.wait()

	-- Ilhas flutuantes decorativas com cristais.
	local sky=Kit.folder(model,"FloatingIsles")
	for i,p in {Vector3.new(-120,70,-150),Vector3.new(130,90,-400),Vector3.new(-90,110,-560),Vector3.new(60,80,40)} do
		Kit.island(sky,"FloatingIsle",L(p.X,0,p.Z),O.Y+p.Y,10+i*2,moss,Enum.Material.Grass,dark,rng)
		Kit.crystalCluster(sky,L(p.X,p.Y,p.Z),16,rng,crystals,false)
	end

	-- Marcadores de jogabilidade futura.
	local slots=Kit.folder(model,"Slots")
	Kit.slot(slots,"Encounter","PillarEncounter",L(0,3,-120),16,"Ecos na ilha-pilar")
	Kit.slot(slots,"Objective","EchoMirror",L(p2c.X,3,p2c.Z),14,"Reflexo das ruínas")
	Kit.slot(slots,"Encounter","HaloEncounter",L(ringC.X,3,ringC.Z-30),10,"Passarela do Cristal-Mãe")
	Kit.slot(slots,"Encounter","WestEncounter",L(p3c.X,3,p3c.Z),16,"Ilha oeste")
	Kit.slot(slots,"BossArena","CathedralArena",L(0,31,-435),38,"Catedral de cristal")
	Kit.arrival(slots,"SafeRuins",L(p2c.X-6,0.3,p2c.Z+8),Vector3.new(0,0,-1),violet,stone)
	Kit.arrival(slots,"SafeWest",L(p3c.X+6,0.3,p3c.Z+6),Vector3.new(0,0,-1),violet,stone)
	Kit.arrival(slots,"SafeTerrace",L(-24,28.7,-372),Vector3.new(0,0,-1),violet,stone)
	arrival.Parent=model
	return model
end

return Region
