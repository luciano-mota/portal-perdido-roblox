--!strict
-- Fase 3 — Deserto das Horas. Referência: assets/world/references/04-deserto-das-horas.png.
-- Portal em ruína com estandarte → estrada de lajes entre aquedutos → praça do relógio de sol
-- inclinado (objetivo futuro) → roda de relógio enterrada e ampulhetas → colunata →
-- escadaria do platô → templo das horas com a grande ampulheta (arena) → portal de saída.
-- Céu: arco de pedra flutuante, anéis de relógio e fitas douradas do tempo.
local Kit=require(script.Parent.Parent.RegionKit)
local Region={}

local C=Color3.fromRGB
local sand=C(222,182,116)
local stone=C(204,170,122)
local dark=C(150,114,80)
local gold=C(214,172,86)
local cyan=C(110,236,226)
local amber=C(255,176,70)
local cloth=C(40,92,96)
local T=28 -- topo do platô do templo (múltiplo de 4 em Y absoluto)

-- Ampulheta: bulbos de vidro empilhados, areia, fio de areia e moldura dourada.
local function hourglass(parent: Instance,base: Vector3,height: number,radius: number,glass: Color3)
	local m=Kit.folder(parent,"Hourglass")
	local plate=height*0.06
	Kit.block(m,"HourglassBase",Vector3.new(radius*2.6,plate,radius*2.6),CFrame.new(base+Vector3.new(0,plate/2,0)),gold,Enum.Material.Metal)
	Kit.block(m,"HourglassTop",Vector3.new(radius*2.6,plate,radius*2.6),CFrame.new(base+Vector3.new(0,height-plate/2,0)),gold,Enum.Material.Metal)
	for k=0,2 do
		local a=k*math.pi*2/3+0.3
		local p=base+Vector3.new(math.cos(a)*radius*1.15,height/2,math.sin(a)*radius*1.15)
		Kit.block(m,"HourglassPost",Vector3.new(radius*0.16,height-plate*2,radius*0.16),CFrame.new(p),gold,Enum.Material.Metal)
	end
	local inner=height-plate*2
	local layers={1,0.96,0.84,0.62,0.3,0.12}
	local h=inner/(#layers*2)
	for i,f in layers do
		for _,half in {-1,1} do
			local y=if half<0 then plate+h*(i-0.5) else height-plate-h*(i-0.5)
			local bulb=Kit.disc(m,"HourglassGlass",base,radius*f,h+0.05,base.Y+y+h/2,glass,Enum.Material.Glass,false)
			bulb.Transparency=0.62 bulb.CastShadow=false bulb.CanQuery=false
		end
	end
	-- Areia: monte embaixo, resto em cima e o fio que cai.
	Kit.disc(m,"HourglassSand",base,radius*0.9,h*2.2,base.Y+plate+h*2.2,sand,Enum.Material.Sand,false).CastShadow=false
	Kit.disc(m,"HourglassSandTop",base,radius*0.55,h*1.1,base.Y+height-plate-h*1.6,sand,Enum.Material.Sand,false).CastShadow=false
	Kit.glow(m,"SandStream",Vector3.new(radius*0.06,inner*0.62,radius*0.06),CFrame.new(base+Vector3.new(0,height/2-h*0.4,0)),amber,0.15)
	return m
end

-- Glifo de ampulheta (X luminoso com barras), voltado para `normal`.
local function glyph(parent: Instance,center: Vector3,normal: Vector3,size: number,color: Color3)
	local frame=CFrame.lookAt(center,center+normal)
	for _,a in {0.5,-0.5} do
		Kit.glow(parent,"HourGlyph",Vector3.new(size*0.1,size*1.05,0.1),frame*CFrame.Angles(0,0,a),color)
	end
	for _,y in {-1,1} do
		Kit.glow(parent,"HourGlyphBar",Vector3.new(size*0.62,size*0.09,0.1),frame*CFrame.new(0,y*size*0.47,0),color)
	end
end

function Region.build(world: Instance,O: Vector3): Model
	local function L(x: number,y: number,z: number): Vector3 return O+Vector3.new(x,y,z) end
	local rng=Random.new(30303)
	local model=Instance.new("Model") model.Name="HourDesert" model:SetAttribute("RegionId","HourDesert") model.Parent=world
	local terrain=workspace.Terrain
	terrain:SetMaterialColor(Enum.Material.Sand,C(220,176,108))
	terrain:SetMaterialColor(Enum.Material.Sandstone,C(190,144,96))

	-- Terreno: chão de areia, dunas fora da estrada, platô do templo e mesas distantes.
	terrain:FillBlock(CFrame.new(L(0,-22,-250)),Vector3.new(600,40,860),Enum.Material.Sandstone)
	terrain:FillBlock(CFrame.new(L(0,-2,-250)),Vector3.new(600,4,860),Enum.Material.Sand)
	local sundial=Vector3.new(-52,0,-170)
	local function clearOfPath(x: number,z: number,reach: number): boolean
		if z>-372 and z<40 and math.abs(x)<reach+16 then return false end
		if (Vector2.new(x,z)-Vector2.new(sundial.X,sundial.Z)).Magnitude<reach+42 then return false end
		if z<-340 and math.abs(x)<130 then return false end
		return true
	end
	local placed=0
	for _=1,160 do
		if placed>=46 then break end
		local x=rng:NextNumber(-280,280)
		local z=rng:NextNumber(-640,140)
		local r=rng:NextNumber(26,58)
		if clearOfPath(x,z,r*0.8) then
			placed+=1
			terrain:FillBall(L(x,-r*0.68,z),r,Enum.Material.Sand)
			if placed%10==0 then task.wait() end
		end
	end
	terrain:FillCylinder(CFrame.new(L(0,4,-476)),48,108,Enum.Material.Sandstone)
	for i=0,23 do
		local a=i/24*math.pi*2
		local p=L(math.cos(a)*106,rng:NextNumber(2,16),-476+math.sin(a)*106)
		if math.abs(math.cos(a)*106)<24 and math.sin(a)>0 then continue end
		terrain:FillBall(p,rng:NextNumber(12,20),Enum.Material.Sandstone)
	end
	terrain:FillBlock(CFrame.new(L(0,16,-377)),Vector3.new(26,36,22),Enum.Material.Air)
	for _,p in {Vector3.new(-230,0,-200),Vector3.new(240,0,-330),Vector3.new(-200,0,-560),Vector3.new(170,0,-640),Vector3.new(-60,0,-720),Vector3.new(250,0,40)} do
		local h=rng:NextNumber(50,95)
		local r=rng:NextNumber(26,40)
		terrain:FillCylinder(CFrame.new(L(p.X,h/2-10,p.Z)),h+20,r,Enum.Material.Sandstone)
		terrain:FillCylinder(CFrame.new(L(p.X,h+4,p.Z)),8,r*1.15,Enum.Material.Sandstone)
	end
	task.wait()

	-- Chegada: portal em ruína com estandarte e glifos.
	local arrivalFolder=Kit.folder(model,"Arrival")
	local arrival=Kit.arrival(arrivalFolder,"Arrival",L(0,0.3,24),Vector3.new(0,0,-1),cyan,stone)
	Kit.archway(arrivalFolder,"RuinGate",L(0,0,8),Vector3.new(0,0,1),14,24,5,stone,Enum.Material.Sandstone,cyan)
	Kit.banner(arrivalFolder,CFrame.lookAt(L(0,17,10.8),L(0,17,30)),6,10,cloth,gold,C(26,52,56))
	for _,s in {-1,1} do
		Kit.block(arrivalFolder,"GateWall",Vector3.new(16,rng:NextNumber(8,14),4),CFrame.new(L(s*20,4,8))*CFrame.Angles(0,0,s*0.04),stone:Lerp(dark,0.2),Enum.Material.Sandstone)
		glyph(arrivalFolder,L(s*12.2,8,10.6),Vector3.new(0,0,1),3.2,cyan)
		Kit.crystalCluster(arrivalFolder,L(s*30,0,18),7,rng,{amber,C(255,206,120)},true)
	end
	for k=1,8 do Kit.rock(arrivalFolder,L(rng:NextNumber(-40,40),0.6,rng:NextNumber(14,46)),Vector3.new(5,3,4)*rng:NextNumber(0.7,1.5),stone:Lerp(dark,0.3),Enum.Material.Sandstone,k,true) end
	task.wait()

	-- Estrada de lajes partidas até o platô.
	local road=Kit.folder(model,"Road")
	for k=0,90 do
		local z=4-k*4.1
		if z<-354 then break end
		for _,x in {-3.1,0,3.1} do
			if rng:NextNumber()<0.86 then
				Kit.block(road,"RoadSlab",Vector3.new(2.9,0.6,3.8),CFrame.new(L(x+rng:NextNumber(-0.2,0.2),0.05,z))*CFrame.Angles(0,rng:NextNumber(-0.05,0.05),rng:NextNumber(-0.03,0.03)),stone:Lerp(dark,rng:NextNumber(0,0.3)),Enum.Material.Sandstone)
			end
		end
		if k%25==24 then task.wait() end
	end
	-- Aquedutos em arcadas dos dois lados.
	for _,s in {-1,1} do
		for i=0,8 do
			if s<0 and i>5 then break end
			local z=-40-i*10
			Kit.archway(road,"Aqueduct",L(s*40,0,z),Vector3.new(1,0,0),7,14,3,stone,Enum.Material.Sandstone,nil)
		end
		local len=if s<0 then 60 else 90
		Kit.block(road,"AqueductDeck",Vector3.new(4,1.6,len),CFrame.new(L(s*40,16.8,-40-len/2+5)),stone,Enum.Material.Sandstone)
		Kit.fall(road,"SandFall",L(s*40,16,-40-len+3),14,3,Vector3.new(0,0,-1),sand,false)
	end
	task.wait()

	-- Praça do relógio de sol: disco inclinado com anéis, marcas e gnômon.
	local dial=Instance.new("Model") dial.Name="Sundial" dial.Parent=model
	local S=L(sundial.X,0,sundial.Z)
	Kit.disc(dial,"DialFace",S,34,3,S.Y+2,C(214,190,150),Enum.Material.Sandstone)
	for _,ring in {{30,1.4,gold,Enum.Material.Metal},{22,0.6,cyan,Enum.Material.Neon},{14,1,gold,Enum.Material.Metal},{6,0.5,cyan,Enum.Material.Neon}} do
		local parts=Kit.ring(dial,"DialRing",S,ring[1],ring[2],0.2,S.Y+2.12,40,ring[3],ring[4],nil,nil,false)
		for _,p in parts do p.CastShadow=false p.CanQuery=false end
	end
	for h=0,11 do
		local a=h*math.pi/6
		local p=S+Vector3.new(math.cos(a)*26,2.1,math.sin(a)*26)
		Kit.glow(dial,"HourMark",Vector3.new(if h%3==0 then 1.2 else 0.6,0.2,if h%3==0 then 5 else 3),CFrame.lookAt(p,S+Vector3.new(0,2.1,0)),if h%3==0 then amber else gold)
	end
	local gnomon=Instance.new("WedgePart") gnomon.Name="Gnomon" gnomon.Size=Vector3.new(1.6,24,30)
	gnomon.CFrame=CFrame.new(S+Vector3.new(0,14,-1))*CFrame.Angles(0,math.pi,0)
	gnomon.Color=gold gnomon.Material=Enum.Material.Metal gnomon.Anchored=true gnomon.CanCollide=true gnomon.Parent=dial
	Kit.glow(dial,"DialCore",Vector3.new(2.4,0.4,2.4),CFrame.new(S+Vector3.new(0,2.2,0)),amber)
	dial.WorldPivot=CFrame.new(S)
	dial:PivotTo(CFrame.new(S+Vector3.new(0,0.6,0))*CFrame.Angles(math.rad(4),0,math.rad(-3)))
	Kit.block(road,"DialSpur",Vector3.new(16,0.6,7),CFrame.new(L(-12,0.05,-170)),stone,Enum.Material.Sandstone)
	task.wait()

	-- Roda de relógio meio enterrada, ampulhetas e colunata.
	local ruins=Kit.folder(model,"TimeRuins")
	local wheel=CFrame.new(L(62,-2,-112))*CFrame.Angles(0,0.5,0)
	Kit.verticalRing(ruins,"ClockWheel",wheel,22,3,3,26,gold:Lerp(dark,0.35),Enum.Material.Metal)
	Kit.verticalRing(ruins,"ClockWheelInner",wheel,15,0.8,1.5,22,cyan,Enum.Material.Neon,nil,nil,true)
	for k=0,7 do
		local a=k*math.pi/4
		Kit.deco(ruins,"ClockSpoke",Vector3.new(1.2,22,1.2),wheel*CFrame.Angles(0,0,a)*CFrame.new(0,11,0),gold:Lerp(dark,0.35),Enum.Material.Metal)
	end
	for k=0,17 do
		local a=k*math.pi*2/18
		Kit.deco(ruins,"ClockTooth",Vector3.new(3,2.4,2.6),wheel*CFrame.Angles(0,0,a)*CFrame.new(23.6,0,0),gold:Lerp(dark,0.35),Enum.Material.Metal)
	end
	for _,p in {Vector3.new(-24,0,-232),Vector3.new(26,0,-262),Vector3.new(-26,0,-300),Vector3.new(24,0,-330)} do
		Kit.block(ruins,"HourglassPlinth",Vector3.new(9,2,9),CFrame.new(L(p.X,1,p.Z)),stone,Enum.Material.Sandstone)
		hourglass(ruins,L(p.X,2,p.Z),14,3,C(236,226,200))
	end
	for i=0,5 do
		for _,s in {-1,1} do
			local base=L(s*14,0,-214-i*22)
			Kit.column(ruins,base,if (i+s)%3==0 then 5 else rng:NextNumber(10,15),1.3,stone,Enum.Material.Sandstone,(i+s)%3~=0,dark)
			glyph(ruins,base+Vector3.new(-s*1.4,6,0),Vector3.new(-s,0,0),2.2,cyan)
		end
	end
	for k=1,14 do
		Kit.rock(ruins,L(rng:NextNumber(-70,70),0.4,rng:NextNumber(-340,-60)),Vector3.new(4,2.5,3.5)*rng:NextNumber(0.6,1.6),stone:Lerp(dark,0.35),Enum.Material.Sandstone,k,false)
	end
	for k=1,6 do
		Kit.crystalCluster(ruins,L(rng:NextNumber(-60,60),0,rng:NextNumber(-330,-60)),rng:NextNumber(4,8),rng,{amber,C(255,206,120)},false)
	end
	task.wait()

	-- Platô do templo: escadaria, quedas de areia, arena, grande ampulheta e saída.
	local temple=Kit.folder(model,"HourTemple")
	Kit.stairs(temple,"TempleStair",L(0,0,-354),Vector3.new(0,0,-1),26,O.Y+T+0.3,1.3,26,O.Y-1,stone,Enum.Material.Sandstone)
	for i=0,3 do
		for _,s in {-1,1} do
			local z=-356-i*8.5
			local y=math.min(T,(i*8.5+2)/1.3*(T+0.3)/26)
			Kit.block(temple,"StairPlinth",Vector3.new(2.4,2.4,2.4),CFrame.new(L(s*11.5,y+1.2,z)),dark,Enum.Material.Sandstone)
		end
	end
	for _,s in {-1,1} do
		Kit.fall(temple,"MesaSandFall",L(s*34,T,-374),T,7,Vector3.new(0,0,1),sand,false)
		glyph(temple,L(s*20,T-8,-372.8),Vector3.new(0,0,1),5,cyan)
	end
	Kit.disc(temple,"ArenaFloor",L(0,0,-452),38,1,O.Y+T+0.4,C(214,186,140),Enum.Material.Sandstone)
	for _,r in {34,20} do
		for _,p in Kit.ring(temple,"ArenaInlay",L(0,0,-452),r,0.6,0.1,O.Y+T+0.46,40,gold,Enum.Material.Neon,nil,nil,false) do p.CanQuery=false end
	end
	for i=0,9 do
		local a=math.pi*0.15+i*math.pi*0.7/9
		for _,s in {-1,1} do
			local p=L(s*math.cos(a)*44,T,-452-math.sin(a)*44)
			Kit.column(temple,p,if i%3==1 then 8 else 16,1.5,stone,Enum.Material.Sandstone,i%3~=1,dark)
		end
	end
	-- Grande ampulheta no arco do templo.
	Kit.archway(temple,"HourglassArch",L(0,T,-520),Vector3.new(0,0,1),30,52,6,stone,Enum.Material.Sandstone,cyan)
	Kit.block(temple,"HourglassDais",Vector3.new(26,2,16),CFrame.new(L(0,T+1,-520)),stone:Lerp(dark,0.2),Enum.Material.Sandstone)
	hourglass(temple,L(0,T+2,-520),40,10,C(236,226,200))
	-- Templo escalonado atrás do arco (silhueta da referência).
	for k,tier in {Vector3.new(96,14,34),Vector3.new(74,12,26),Vector3.new(52,10,20),Vector3.new(30,8,14)} do
		local y=T+({7,20,31,40})[k]
		Kit.block(temple,"TempleTier",tier,CFrame.new(L(0,y,-552-k*2)),stone:Lerp(dark,0.08*k),Enum.Material.Sandstone)
		for _,s in {-1,1} do glyph(temple,L(s*tier.X*0.3,y,-552-k*2+tier.Z/2+0.06),Vector3.new(0,0,1),tier.Y*0.55,cyan) end
	end
	for _,s in {-1,1} do
		Kit.block(temple,"TempleWall",Vector3.new(40,22,5),CFrame.new(L(s*42,T+11,-524)),stone:Lerp(dark,0.15),Enum.Material.Sandstone)
		for k=0,2 do glyph(temple,L(s*(30+k*11),T+12,-521.4),Vector3.new(0,0,1),4,cyan) end
		Kit.banner(temple,CFrame.lookAt(L(s*20,T+30,-516),L(s*20,T+30,-490)),5,12,cloth,gold,C(26,52,56))
	end
	local exitGate=Kit.travelGate(temple,"ExitGate",L(-46,T+0.4,-488),Vector3.new(1,0,0.7),8,stone,amber,"PASSAGEM DAS HORAS","Siga a travessia")
	exitGate:SetAttribute("RegionId","HourDesert")
	task.wait()

	-- Céu: arco de pedra flutuante, anéis de relógio e fitas do tempo.
	local sky=Kit.folder(model,"TimeSky")
	local archFrame=CFrame.new(L(-150,70,-300))*CFrame.Angles(0,0.9,0)
	for _,p in Kit.verticalRing(sky,"SkyArch",archFrame,52,14,20,16,stone:Lerp(dark,0.25),Enum.Material.Sandstone,0,math.pi) do p.CastShadow=true end
	for _,s in {-1,1} do
		Kit.deco(sky,"SkyArchRoot",Vector3.new(22,26,24),archFrame*CFrame.new(s*52,-6,0),stone:Lerp(dark,0.3),Enum.Material.Sandstone,Enum.PartType.Ball)
	end
	for i,r in {70,95} do
		local frame=CFrame.new(L(70*i-80,160+i*25,-420))*CFrame.Angles(0.4*i,0.6,0.3)
		Kit.verticalRing(sky,"SkyClockRing",frame,r,3,3,36,gold,Enum.Material.Metal,0,math.pi*1.4)
		Kit.verticalRing(sky,"SkyClockGlow",frame,r-4,0.6,0.6,30,amber,Enum.Material.Neon,0.2,math.pi*1.2,true)
	end
	for i=1,5 do
		local frame=CFrame.new(L(rng:NextNumber(-120,120),rng:NextNumber(40,90),rng:NextNumber(-500,-80)))*CFrame.Angles(rng:NextNumber(-0.4,0.4),rng:NextNumber(0,6),rng:NextNumber(1.2,1.9))
		for _,p in Kit.verticalRing(sky,"TimeRibbon",frame,rng:NextNumber(40,80),0.5,0.5,14,amber,Enum.Material.Neon,0,rng:NextNumber(1,2),true) do p.Transparency=0.4 end
	end

	-- Marcadores de jogabilidade futura.
	local slots=Kit.folder(model,"Slots")
	Kit.slot(slots,"Encounter","AqueductEncounter",L(0,3,-100),18,"Entre os aquedutos")
	Kit.slot(slots,"Objective","SundialCycle",L(sundial.X,4,sundial.Z),30,"Relógio de sol")
	Kit.slot(slots,"Encounter","ColonnadeEncounter",L(0,3,-280),18,"Colunata das ampulhetas")
	Kit.slot(slots,"BossArena","HourglassArena",L(0,T+3,-452),36,"Templo das horas")
	Kit.arrival(slots,"SafeSundial",L(-14,0.4,-170),Vector3.new(0,0,-1),amber,stone)
	Kit.arrival(slots,"SafeColonnade",L(0,0.4,-236),Vector3.new(0,0,-1),amber,stone)
	Kit.arrival(slots,"SafeTemple",L(0,T+0.7,-404),Vector3.new(0,0,-1),amber,stone)
	arrival.Parent=model
	return model
end

return Region
