--!strict
-- Referência principal: assets/world/references/02-vale-de-lumen.png.
-- Massas distantes simples; água nativa; nenhuma luz dinâmica adicional.
local Art=require(game:GetService("ReplicatedStorage").Shared.Art)
local Scenery={}
local stone=Color3.fromRGB(137,139,123)
local moss=Color3.fromRGB(84,114,66)
local cyan=Color3.fromRGB(93,214,216)
local function part(parent: Instance,name: string,size: Vector3,position: Vector3,color: Color3,material: Enum.Material,solid: boolean?)
	return Art.part(parent,name,size,CFrame.new(position),color,material,nil,solid)
end

local function arch(parent: Instance,center: Vector3,radius: number)
	local template=game:GetService("ServerStorage"):FindFirstChild("LumenArchTemplate")
	if Art.templateReady(template) and template and template:IsA("Model") then
		local model=template:Clone() model.Name="WeatheredArch"
		model:ScaleTo(model:GetScale()*(radius*2+4)/model:GetExtentsSize().X)
		local size=model:GetExtentsSize()
		model:PivotTo(CFrame.new(center+Vector3.new(0,size.Y*0.5,0)))
		model:SetAttribute("GeneratedLandmark",true)
		model.Parent=parent
		-- Colisão simples nos pilares e coroamento, deixando a passagem aberta.
		for _,side in {-1,1} do
			local collider=part(model,"ArchCollision",Vector3.new(size.X*0.17,size.Y*0.75,size.Z*0.75),center+Vector3.new(side*size.X*0.38,size.Y*0.375,0),stone,Enum.Material.Rock,true)
			collider.Transparency=1 collider.CastShadow=false
		end
		local top=part(model,"ArchCollision",Vector3.new(size.X*0.65,size.Y*0.12,size.Z*0.7),center+Vector3.new(0,size.Y*0.94,0),stone,Enum.Material.Rock,true)
		top.Transparency=1 top.CastShadow=false
		return model
	end
	local model=Instance.new("Model") model.Name="WeatheredArch" model.Parent=parent
	for _,side in {-1,1} do
		part(model,"Foundation",Vector3.new(4,1,5),center+Vector3.new(side*radius,0.5,0),stone,Enum.Material.Cobblestone,true)
		for level=1,4 do
			part(model,"Masonry",Vector3.new(2.8,2.1,3.4),center+Vector3.new(side*radius,level*2,0),stone:Lerp(moss,level*0.04),Enum.Material.Limestone,true)
		end
	end
	for i=0,10 do
		local a=i*math.pi/10
		local p=part(model,"Voussoir",Vector3.new(2.6,2.8,3.5),center+Vector3.new(math.cos(a)*radius,8+math.sin(a)*radius,0),stone,Enum.Material.Limestone,true)
		p.CFrame*=CFrame.Angles(0,0,a)
	end
	return model
end

local function crystal(parent: Instance,p: Vector3,scale: number)
	local stonePart=part(parent,"LumenCrystal",Vector3.new(0.7,2.5,0.7)*scale,p,cyan,Enum.Material.Glass,false)
	stonePart.CFrame*=CFrame.Angles(0.2,0,0.3)
	stonePart.Transparency=0.18
	local tip=Instance.new("WedgePart") tip.Name="CrystalTip" tip.Size=Vector3.new(0.7,0.8,0.7)*scale
	 tip.CFrame=stonePart.CFrame*CFrame.new(0,1.65*scale,0)
	tip.Color=cyan tip.Material=Enum.Material.Glass tip.Transparency=0.15 tip.Anchored=true
	tip.CanCollide=false tip.CanTouch=false tip.CanQuery=false tip.Parent=parent
end

function Scenery.build(world: Model)
	local scene=Instance.new("Folder") scene.Name="LumenLandscape" scene.Parent=world
	local terrain=workspace.Terrain
	terrain.WaterColor=Color3.fromRGB(54,143,155)
	terrain.WaterTransparency=0.3 terrain.WaterReflectance=0.35 terrain.WaterWaveSize=0.12 terrain.WaterWaveSpeed=5
	for _,p in {Vector3.new(-135,-18,65),Vector3.new(-130,-19,-82),Vector3.new(65,-20,93),Vector3.new(130,-19,-65)} do
		terrain:FillBall(p,31,Enum.Material.LeafyGrass)
	end
	-- Planos intermediários do vale: margens altas enquadram o rio e as ruínas,
	-- longe do eixo da missão e dos locais já habitados pela vila.
	for _,knoll in {{Vector3.new(67,-15,-27),23},{Vector3.new(65,-16,-81),26},{Vector3.new(125,-14,36),25}} do
		terrain:FillBall(knoll[1],knoll[2],Enum.Material.LeafyGrass)
	end
	-- Rio lateral: longe das inscrições e do corredor principal. Leito contido
	-- no domínio do gerador, sem apagar terreno externo ao projeto.
	for i=0,14 do
		local z=100-i*12
		local x=94+math.sin(i*0.43)*9
		terrain:FillBlock(CFrame.new(x,-4,z),Vector3.new(24,16,16),Enum.Material.Air)
		terrain:FillBlock(CFrame.new(x,-10,z),Vector3.new(24,4,16),Enum.Material.Sand)
		terrain:FillBlock(CFrame.new(x,-4,z),Vector3.new(22,8,16),Enum.Material.Water)
		for _,side in {-1,1} do
			local bank=Art.part(scene,"RiverBank",Vector3.new(6,3,8),CFrame.new(x+side*13,0,z)*CFrame.Angles(0,i,0),stone,Enum.Material.Rock,Enum.PartType.Ball,true)
			bank.CastShadow=false
		end
		if i%5==0 then task.wait() end
	end
	-- Ponte e mirante acessíveis à direita da vila.
	for i=0,11 do
		part(scene,"BridgeDeck",Vector3.new(3.2,0.8,9),Vector3.new(77+i*3,0.25,25),stone,Enum.Material.Cobblestone,true)
	end
	for _,z in {20,30} do
		for i=0,6 do part(scene,"BridgePost",Vector3.new(1,3.8,1),Vector3.new(77+i*6,1.9,z),stone,Enum.Material.Limestone,true) end
		part(scene,"BridgeParapet",Vector3.new(37,0.7,0.65),Vector3.new(95,3.1,z),stone,Enum.Material.Limestone,true)
	end
	local ground=RaycastParams.new() ground.FilterType=Enum.RaycastFilterType.Include ground.FilterDescendantsInstances={terrain}
	local function surface(x: number,z: number): Vector3
		local hit=workspace:Raycast(Vector3.new(x,80,z),Vector3.new(0,-140,0),ground)
		-- O mundo recebe +2 Y ao final de WorldBuilder; terreno não recebe esse deslocamento.
		return Vector3.new(x,if hit then hit.Position.Y-2 else 0,z)
	end
	-- Caminho lateral legível até a ponte: peças baixas e irregulares sobre o solo.
	for i=1,15 do
		local p=surface(10+i*4.3,25+math.sin(i*0.28)*2)
		local slab=part(scene,"RiverWalk",Vector3.new(4.8,0.22,5.5),p+Vector3.new(0,0.1,0),stone,Enum.Material.Cobblestone,true)
		slab.CFrame*=CFrame.Angles(0,math.sin(i)*0.08,0)
	end
	for index,point in {Vector2.new(65,-26),Vector2.new(64,-80)} do
		local base=surface(point.X,point.Y)
		-- Base desce até o ponto mais baixo da encosta sob ela: nenhum canto flutua.
		local low=base.Y
		for _,offset in {Vector2.new(-7,-3),Vector2.new(7,-3),Vector2.new(-7,3),Vector2.new(7,3)} do
			low=math.min(low,surface(point.X+offset.X,point.Y+offset.Y).Y)
		end
		local top=base.Y+0.8
		part(scene,"RuinFooting",Vector3.new(14,top-low+1.2,6),Vector3.new(base.X,(top+low-1.2)/2,base.Z),stone,Enum.Material.Limestone,true)
		local ruin=arch(scene,base+Vector3.new(0,0.8,0),5)
		ruin.Name="RiversideRuin" ruin:SetAttribute("ReferenceImage","02-vale-de-lumen.png")
		for j=1,3 do
			local p=surface(point.X-10+j*5,point.Y+9)
			local block=part(scene,"FallenMasonry",Vector3.new(3.2,1.6,2.2),p+Vector3.new(0,0.8,0),stone,Enum.Material.Limestone,true)
			block.CFrame*=CFrame.Angles(0,j*0.7,0.12)
		end
		Art.tree(scene,surface(76,point.Y+11),630+index,false)
	end
	-- Cascata contínua do rio para fora da borda da ilha.
	for i=1,7 do
		local fall=part(scene,"Waterfall",Vector3.new(2.9,60,0.18),Vector3.new(85+i*2.7,-29,111),Color3.fromRGB(165,226,231),Enum.Material.Glass,false)
		fall.Transparency=0.35+(i%3)*0.1 fall.CastShadow=false
	end
	for i=1,5 do
		local mist=Art.part(scene,"WaterfallMist",Vector3.new(12,6,9),CFrame.new(87+i*4,-57,112),Color3.fromRGB(216,236,238),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
		mist.Transparency=0.88 mist.CastShadow=false
	end
	-- Montanhas de fundo, afastadas da área de jogo.
	for i=1,7 do
		local x=-320+(i-1)*105
		local peak=Vector3.new(x,55+(i%3)*28,-780-(i%2)*45)
		terrain:FillBall(peak-Vector3.new(0,80,0),95,Enum.Material.Rock)
		terrain:FillBall(peak-Vector3.new(0,25,0),47,Enum.Material.Rock)
		terrain:FillBall(peak+Vector3.new(0,9,0),23,Enum.Material.Snow)
		task.wait()
	end
	-- Portal marco do vale: patamar próprio, fora da passagem do jogador.
	local old=world.Village:FindFirstChild("PortalPrimordial") if old then old:Destroy() end
	part(scene,"PortalTerrace",Vector3.new(58,3,44),Vector3.new(-80,0,-35),stone,Enum.Material.Cobblestone,true)
	local portal=Art.portal(scene,Vector3.new(-80,2,-40),22)
	portal:SetAttribute("ReferenceImage","02-vale-de-lumen.png")
	for i=1,6 do part(scene,"TerraceStep",Vector3.new(20,0.45*i,3),Vector3.new(-80,0.225*i,-8-i*3),stone,Enum.Material.Limestone,true) end
	arch(scene,Vector3.new(-80,0,17),7)
	for _,side in {-1,1} do
		part(scene,"PortalButtress",Vector3.new(4,25,5),Vector3.new(-80+side*27,12,-40),stone,Enum.Material.Limestone,true)
		crystal(scene,Vector3.new(-80+side*27,27,-40),2.2)
	end
	-- Cristal suspenso e anel: silhueta marcante da referência.
	crystal(scene,Vector3.new(-80,55,-40),4)
	for i=1,24 do
		local a=i*math.pi*2/24 local b=(i+1)*math.pi*2/24
		Art.segment(scene,"CrownRing",Vector3.new(-80+math.cos(a)*10,55,-40+math.sin(a)*10),Vector3.new(-80+math.cos(b)*10,55,-40+math.sin(b)*10),0.3,Color3.fromRGB(182,166,109),Enum.Material.Metal)
	end
	-- Ruínas enquadram a chegada sem bloquear Ilyra nem os controles.
	arch(scene,Vector3.new(0,0,68),10)
	for _,x in {-12,12} do
		local banner=part(scene,"LumenBanner",Vector3.new(2,6,0.12),Vector3.new(x,8,68),Color3.fromRGB(38,102,108),Enum.Material.Fabric)
		part(scene,"BannerRune",Vector3.new(0.12,3,0.14),banner.Position+Vector3.new(0,0,-0.12),cyan,Enum.Material.Neon)
	end
	-- Flores nas margens, com quantidade limitada e posições determinísticas.
	local rng=Random.new(72831)
	for i=1,32 do
		local x=if i<=16 then rng:NextNumber(64,77) else rng:NextNumber(-109,-102)
		local z=rng:NextNumber(-55,65)
		local p=Vector3.new(x,0.5,z)
		Art.segment(scene,"FlowerStem",p,p+Vector3.new(0,0.9,0),0.07,moss,Enum.Material.Grass)
		for j=1,3 do
			local a=j*math.pi*2/3
			local petal=Art.part(scene,"LumenPetal",Vector3.new(0.7,0.12,0.4),CFrame.new(p+Vector3.new(math.cos(a)*0.3,1,math.sin(a)*0.3))*CFrame.Angles(0,-a,0.3),if i%3==0 then Color3.fromRGB(157,124,189) else cyan,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
			petal.CastShadow=false
		end
	end
	for i=1,4 do
		local pos=Vector3.new(-210-i*43,65+i*12,-30-i*70)
		local island=Art.part(scene,"FloatingIsland",Vector3.new(40+i*3,23,34),CFrame.new(pos),stone,Enum.Material.Rock,Enum.PartType.Ball)
		island.CanCollide=false island.CanQuery=false
		Art.part(scene,"IslandMeadow",Vector3.new(34+i*3,3,29),CFrame.new(pos+Vector3.new(0,10,0)),moss,Enum.Material.Grass,Enum.PartType.Ball)
		arch(scene,pos+Vector3.new(0,11,0),4)
	end
	-- Vegetação baixa perto do caminho dá escala e variação sem bloquear o percurso.
	-- 120 lâminas estáticas, sem sombra, toque, consulta física ou atualização por frame.
	for i=1,24 do
		local side=if i%2==0 then -1 else 1
		local center=Vector3.new(side*rng:NextNumber(11,21),0,70-i*6)
		for blade=1,5 do
			local angle=rng:NextNumber(0,math.pi*2)
			local height=rng:NextNumber(0.55,1.25)
			local leaf=Instance.new("WedgePart") leaf.Name="MeadowGrass"
			leaf.Size=Vector3.new(0.04,height,rng:NextNumber(0.18,0.35))
			leaf.CFrame=CFrame.new(center+Vector3.new(math.cos(angle)*0.35,height*0.5,math.sin(angle)*0.35))*CFrame.Angles(0,angle,rng:NextNumber(-0.3,0.3))
			leaf.Color=moss:Lerp(Color3.fromRGB(153,158,84),rng:NextNumber(0.1,0.55))
			leaf.Material=Enum.Material.Grass leaf.Anchored=true leaf.CastShadow=false
			leaf.CanCollide=false leaf.CanTouch=false leaf.CanQuery=false leaf.Parent=scene
		end
	end
	scene:SetAttribute("ReferenceImage","02-vale-de-lumen.png")
end

return Scenery
