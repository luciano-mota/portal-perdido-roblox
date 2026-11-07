--!strict
-- Fase 5 — Limiar da Convergência. Cenário NOVO, sem arte aprovada (docs/CAMPAIGN_SIX_PHASES.md):
-- proposta original desta implementação, para revisão do proprietário.
--
-- Um nexo flutuante sobre um mar de nuvens ao crepúsculo, com aurora. Quatro terraços de chegada,
-- um por região de origem (Vale, Abismo, Deserto, Cidadela), cada um com um arco no estilo da sua
-- região: na Rota B os sobreviventes de cada ramo chegam pelo seu terraço e se reencontram.
-- Pontes levam à arena circular da prova (quatro pilares temáticos na borda). Ao norte, uma
-- escadaria monumental sobe ao Portão do Vazio (saída para a fase 6).
local Kit=require(script.Parent.Parent.RegionKit)
local Region={}

local C=Color3.fromRGB
local stone=C(176,174,190)
local dark=C(124,118,142)
local gold=C(206,170,100)
local white=C(238,236,250)
local themes={
	{id="Lumen", angle=0, glow=C(76,201,205), stone=C(150,150,132), accent=C(104,132,86), title="DO VALE"},
	{id="CrystalAbyss", angle=0, glow=C(186,140,255), stone=C(170,160,168), accent=C(110,232,236), title="DO ABISMO"},
	{id="HourDesert", angle=0, glow=C(255,176,70), stone=C(204,170,122), accent=C(110,236,226), title="DO DESERTO"},
	{id="EclipseCitadel", angle=0, glow=C(255,136,58), stone=C(70,66,88), accent=C(84,22,34), title="DA CIDADELA"},
}
local TERRACES={Vector3.new(-150,0,70),Vector3.new(-72,0,150),Vector3.new(72,0,150),Vector3.new(150,0,70)}

function Region.build(world: Instance,O: Vector3): Model
	local function L(x: number,y: number,z: number): Vector3 return O+Vector3.new(x,y,z) end
	local rng=Random.new(50505)
	local model=Instance.new("Model") model.Name="Convergence" model:SetAttribute("RegionId","Convergence") model.Parent=world

	-- Arena central da prova.
	local nexus=Kit.folder(model,"Nexus")
	Kit.island(nexus,"NexusIsland",L(0,0,0),O.Y,52,stone,Enum.Material.Slate,dark,rng,64)
	Kit.disc(nexus,"NexusInlay",L(0,0,0),50,0.4,O.Y+0.2,stone:Lerp(white,0.2),Enum.Material.Marble)
	for i,t in themes do
		for _,p in Kit.ring(nexus,"ConvergenceRing",L(0,0,0),12+i*8,0.7,0.1,O.Y+0.26,40,t.glow,Enum.Material.Neon,nil,nil,false) do p.CanQuery=false end
	end
	local heart=Kit.folder(nexus,"ConvergenceHeart")
	for i,t in themes do
		local a=i*math.pi/2
		Kit.crystal(heart,L(math.cos(a)*1.6,26,math.sin(a)*1.6),12,2.6,t.glow,math.cos(a)*0.35,-math.sin(a)*0.35,a,false)
		Kit.crystal(heart,L(math.cos(a)*1.6,26,math.sin(a)*1.6),10,2.2,t.glow,math.pi-math.cos(a)*0.35,math.sin(a)*0.35,a,false)
	end
	local core=Kit.deco(heart,"HeartCore",Vector3.new(4,4,4),CFrame.new(L(0,26,0)),white,Enum.Material.Neon,Enum.PartType.Ball)
	Kit.light(core,white,40,1.2)
	Kit.verticalRing(heart,"HeartOrbit",CFrame.new(L(0,26,0))*CFrame.Angles(0.5,0,0.2),11,0.5,0.5,30,gold,Enum.Material.Metal)
	Kit.verticalRing(heart,"HeartOrbit",CFrame.new(L(0,26,0))*CFrame.Angles(-0.4,1.2,0.3),13,0.4,0.4,30,white,Enum.Material.Neon,nil,nil,true)
	-- Quatro pilares temáticos na borda, entre as pontes.
	for i,t in themes do
		local a=math.rad(({-110,-45,45,110})[i])
		local p=L(math.sin(a)*45,0,math.cos(a)*45)
		local base=CFrame.new(p)
		Kit.block(nexus,"PylonBase",Vector3.new(7,2,7),base*CFrame.new(0,1,0),t.stone,Enum.Material.Slate)
		if t.id=="CrystalAbyss" then
			Kit.crystalCluster(nexus,p+Vector3.new(0,2,0),20,rng,{t.glow,t.accent},true)
		elseif t.id=="EclipseCitadel" then
			Kit.spire(nexus,p+Vector3.new(0,2,0),5,16,9,t.stone,C(46,42,70),Enum.Material.Slate,t.glow)
		else
			Kit.block(nexus,"Obelisk",Vector3.new(3.6,18,3.6),base*CFrame.new(0,11,0),t.stone,if t.id=="HourDesert" then Enum.Material.Sandstone else Enum.Material.Limestone)
			Kit.pyramid(nexus,"ObeliskTip",p+Vector3.new(0,20,0),3.6,3,gold,Enum.Material.Metal)
			for _,face in {Vector3.new(0,0,1),Vector3.new(0,0,-1),Vector3.new(1,0,0),Vector3.new(-1,0,0)} do
				local q=p+Vector3.new(0,11,0)+face*1.86
				Kit.glow(nexus,"ObeliskRune",Vector3.new(0.5,12,0.1),CFrame.lookAt(q,q+face),t.glow)
			end
		end
	end
	task.wait()

	-- Terraços de chegada, um por região de origem, e pontes até a arena.
	local gathering=Kit.folder(model,"Terraces")
	for i,t in themes do
		local c=TERRACES[i]
		local center=L(c.X,0,c.Z)
		local toCenter=(-c).Unit
		local side=Vector3.new(-toCenter.Z,0,toCenter.X)
		Kit.island(gathering,t.id.."Terrace",center,O.Y,18,t.stone,Enum.Material.Slate,dark,rng,30)
		Kit.archway(gathering,t.id.."Arch",center-toCenter*13,toCenter,10,17,3,t.stone,Enum.Material.Slate,t.glow)
		local marker=Kit.arrival(gathering,if t.id=="Lumen" then "Arrival" else "Arrival_"..t.id,center+toCenter*2+Vector3.new(0,0.3,0),toCenter,t.glow,t.stone)
		marker:SetAttribute("Label","Chegada "..t.title)
		Kit.slot(gathering,"Gathering",t.id.."Gathering",center+Vector3.new(0,3,0),16,"Reencontro "..t.title)
		if t.id=="Lumen" then
			Kit.flowers(gathering,center-toCenter*6+side*8,5,16,{C(167,145,190),C(230,185,110)},rng,O.Y)
			Kit.flowers(gathering,center-toCenter*6-side*8,5,16,{C(167,145,190),C(230,185,110)},rng,O.Y)
		elseif t.id=="CrystalAbyss" then
			Kit.crystalCluster(gathering,center-toCenter*9+side*10,10,rng,{t.glow,t.accent},true)
			Kit.crystalCluster(gathering,center-toCenter*9-side*10,8,rng,{t.glow,t.accent},true)
		elseif t.id=="HourDesert" then
			Kit.banner(gathering,CFrame.lookAt(center-toCenter*11.4+Vector3.new(0,12,0),center+Vector3.new(0,12,0)),4,8,C(40,92,96),gold,C(26,52,56))
			Kit.disc(gathering,"SandDrift",center-toCenter*6+side*9,4,0.6,O.Y+0.4,C(222,182,116),Enum.Material.Sand,false)
		else
			Kit.banner(gathering,CFrame.lookAt(center-toCenter*11.4+Vector3.new(0,12,0),center+Vector3.new(0,12,0)),4,8,t.accent,t.glow,C(24,10,14))
		end
		local from=center+toCenter*16
		local to=L(0,0,0)-toCenter*49
		Kit.bridge(gathering,t.id.."Bridge",from,to,O.Y,O.Y-40,7,math.max(2,math.floor((to-from).Magnitude/22)),stone,Enum.Material.Slate,t.glow,true)
		task.wait()
	end

	-- Escadaria do norte até o Portão do Vazio.
	local ascent=Kit.folder(model,"Ascent")
	Kit.bridge(ascent,"NorthBridge",L(0,0,-48),L(0,0,-112),O.Y,O.Y-40,10,3,stone,Enum.Material.Slate,gold,true)
	Kit.island(ascent,"Landing",L(0,0,-126),O.Y,15,stone,Enum.Material.Slate,dark,rng,26)
	Kit.stairs(ascent,"VoidStair",L(0,0,-140),Vector3.new(0,0,-1),30,O.Y+40,1.15,12,O.Y-8,stone,Enum.Material.Slate)
	for k=0,4 do
		for _,s in {-1,1} do
			local z=-142-k*8
			local y=math.min(40,(k*8+2)/1.15*40/30)
			Kit.deco(ascent,"StairBrazier",Vector3.new(1.4,1.4,1.4),CFrame.new(L(s*6.6,y+1.4,z)),C(180,140,255),Enum.Material.Neon,Enum.PartType.Ball)
		end
	end
	Kit.island(ascent,"VoidThreshold",L(0,0,-196),O.Y+40,24,dark,Enum.Material.Slate,C(64,52,88),rng,40)
	for _,s in {-1,1} do
		Kit.block(ascent,"VoidObelisk",Vector3.new(4,24,4),CFrame.new(L(s*16,52,-200)),C(52,42,70),Enum.Material.Slate)
		Kit.crystal(ascent,L(s*16,64,-200),7,2,C(170,110,255),0,0,0.4,false)
	end
	local exitGate=Kit.travelGate(ascent,"ExitGate",L(0,40,-206),Vector3.new(0,0,1),10,C(52,42,70),C(170,110,255),"PORTÃO DO VAZIO","Rumo ao Domínio")
	exitGate:SetAttribute("RegionId","Convergence")
	task.wait()

	-- Mar de nuvens, rochas flutuantes e ilhas de cristal.
	local sky=Kit.folder(model,"CloudSea")
	for i=1,18 do
		local a=i*2.4
		local r=rng:NextNumber(40,320)
		local cloud=Kit.deco(sky,"CloudBank",Vector3.new(rng:NextNumber(120,220),rng:NextNumber(16,30),rng:NextNumber(120,220)),CFrame.new(L(math.cos(a)*r,rng:NextNumber(-95,-70),math.sin(a)*r-40)),C(236,226,250),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
		cloud.Transparency=0.35 cloud.CastShadow=false
	end
	for i=1,22 do
		local a=rng:NextNumber(0,math.pi*2)
		local r=rng:NextNumber(90,260)
		local size=rng:NextNumber(6,20)
		Kit.rock(sky,L(math.cos(a)*r,rng:NextNumber(-30,60),math.sin(a)*r),Vector3.new(size,size*0.8,size*1.1),dark,Enum.Material.Rock,i,false).CanQuery=false
	end
	for i,t in themes do
		local a=math.rad(-160+i*70)
		local p=Vector3.new(math.sin(a)*230,30+i*12,-math.cos(a)*120-60)
		Kit.island(sky,"DriftIsle",L(p.X,0,p.Z),O.Y+p.Y,12,t.stone,Enum.Material.Slate,dark,rng,20)
		Kit.crystalCluster(sky,L(p.X,p.Y,p.Z),14,rng,{t.glow},false)
		Kit.fall(sky,"EnergyFall",L(p.X,p.Y-6,p.Z+11),40,3,Vector3.new(0,0,1),t.glow,true)
	end

	-- Marcadores de jogabilidade futura.
	local slots=Kit.folder(model,"Slots")
	Kit.slot(slots,"BossArena","ConvergenceTrial",L(0,3,0),46,"Prova da Convergência")
	Kit.arrival(slots,"SafeLanding",L(0,0.4,-126),Vector3.new(0,0,-1),C(170,110,255),stone)
	Kit.arrival(slots,"SafeThreshold",L(0,40.4,-180),Vector3.new(0,0,-1),C(170,110,255),stone)
	return model
end

return Region
