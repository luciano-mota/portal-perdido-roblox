--!strict
-- Kit de construção das regiões 2–6 (Abismo, Deserto, Cidadela, Convergência, Domínio).
-- Tudo procedural e original; posições absolutas (cada região soma sua origem antes de chamar).
-- Regras herdadas do Vale: pisos jogáveis são peças com altura exata; decoração sem colisão,
-- sem consulta física e, quando pequena, sem sombra; nenhuma luz dinâmica com sombra.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Art=require(ReplicatedStorage.Shared.Art)

local Kit={}

export type Palette={stone: Color3, dark: Color3, trim: Color3, glow: Color3, accent: Color3}

local function flat(v: Vector3): Vector3 return Vector3.new(v.X,0,v.Z) end
Kit.flat=flat

function Kit.folder(parent: Instance,name: string): Folder
	local f=Instance.new("Folder") f.Name=name f.Parent=parent return f
end

-- Peça sólida (piso, parede, pilar).
function Kit.block(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,material: Enum.Material,solid: boolean?): Part
	return Art.part(parent,name,size,cf,color,material,nil,if solid==nil then true else solid)
end

-- Decoração: sem colisão, sem consulta e sem sombra se for pequena.
function Kit.deco(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,material: Enum.Material,shape: Enum.PartType?): Part
	local p=Art.part(parent,name,size,cf,color,material,shape,false)
	if size.Magnitude<14 then p.CastShadow=false end
	return p
end

function Kit.glow(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,transparency: number?): Part
	local p=Art.part(parent,name,size,cf,color,Enum.Material.Neon,nil,false)
	p.CastShadow=false
	p.Transparency=transparency or 0
	return p
end

function Kit.light(part: BasePart,color: Color3,range: number,brightness: number?)
	local light=Instance.new("PointLight") light.Color=color light.Range=range light.Brightness=brightness or 1 light.Shadows=false light.Parent=part
end

-- Disco de piso (cilindro em pé) com topo em `top`.
function Kit.disc(parent: Instance,name: string,center: Vector3,radius: number,thickness: number,top: number,color: Color3,material: Enum.Material,solid: boolean?): Part
	return Art.part(parent,name,Vector3.new(thickness,radius*2,radius*2),CFrame.new(center.X,top-thickness/2,center.Z)*CFrame.Angles(0,0,math.pi/2),color,material,Enum.PartType.Cylinder,if solid==nil then true else solid)
end

-- Anel (passarela circular) feito de segmentos, entre os ângulos a0 e a1 (radianos; 0 = +X).
function Kit.ring(parent: Instance,name: string,center: Vector3,radius: number,width: number,thickness: number,top: number,segments: number,color: Color3,material: Enum.Material,a0: number?,a1: number?,solid: boolean?): {Part}
	local from=a0 or 0
	local to=a1 or math.pi*2
	local parts={}
	local step=(to-from)/segments
	local chord=2*(radius+width/2)*math.sin(math.abs(step)/2)+0.4
	for i=0,segments-1 do
		local a=from+step*(i+0.5)
		local p=Vector3.new(center.X+math.cos(a)*radius,top-thickness/2,center.Z+math.sin(a)*radius)
		local tangent=Vector3.new(-math.sin(a),0,math.cos(a))
		table.insert(parts,Art.part(parent,name,Vector3.new(width,thickness,chord),CFrame.lookAt(p,p+tangent),color,material,nil,if solid==nil then true else solid))
	end
	return parts
end

-- Anel vertical decorativo (arco quebrado no céu, roda de relógio): plano definido por `cf`
-- (eixo X e Y do cf; o anel gira em torno do Z do cf).
function Kit.verticalRing(parent: Instance,name: string,cf: CFrame,radius: number,thickness: number,depth: number,segments: number,color: Color3,material: Enum.Material,a0: number?,a1: number?,neon: boolean?): {Part}
	local from=a0 or 0
	local to=a1 or math.pi*2
	local parts={}
	local step=(to-from)/segments
	local chord=2*radius*math.sin(math.abs(step)/2)+0.3
	for i=0,segments-1 do
		local a=from+step*(i+0.5)
		local piece=cf*CFrame.Angles(0,0,a)*CFrame.new(radius,0,0)
		local p=Art.part(parent,name,Vector3.new(thickness,chord,depth),piece,color,if neon then Enum.Material.Neon else material,nil,false)
		p.CanQuery=false
		if neon then p.CastShadow=false end
		table.insert(parts,p)
	end
	return parts
end

-- Escada maciça: cada degrau desce até baseY.
function Kit.stairs(parent: Instance,name: string,start: Vector3,direction: Vector3,steps: number,topY: number,run: number,width: number,baseY: number,color: Color3,material: Enum.Material)
	local dir=flat(direction).Unit
	local rise=(topY-start.Y)/steps
	for i=1,steps do
		local top=start.Y+rise*i
		local center=start+dir*(run*(i-0.5))
		local height=math.max(0.4,top-baseY)
		local p=Vector3.new(center.X,top-height/2,center.Z)
		local step=Kit.block(parent,name,Vector3.new(width,height,run+0.05),CFrame.lookAt(p,p+dir),color:Lerp(Color3.new(0,0,0),(i%3)*0.035),material)
		step.CastShadow=i%2==0
	end
end

function Kit.column(parent: Instance,base: Vector3,height: number,radius: number,color: Color3,material: Enum.Material,cap: boolean?,capColor: Color3?)
	Art.segment(parent,"Column",base,base+Vector3.new(0,height,0),radius*2,color,material,true)
	Kit.block(parent,"ColumnBase",Vector3.new(radius*2.5,0.8,radius*2.5),CFrame.new(base+Vector3.new(0,0.4,0)),capColor or color,material)
	if cap~=false then
		Kit.block(parent,"ColumnCap",Vector3.new(radius*2.6,0.9,radius*2.6),CFrame.new(base+Vector3.new(0,height+0.45,0)),capColor or color,material)
	end
end

-- Pirâmide de base quadrada com 4 CornerWedgeParts (pico no canto +X,+Y,−Z de cada uma).
function Kit.pyramid(parent: Instance,name: string,base: Vector3,width: number,height: number,color: Color3,material: Enum.Material,yaw: number?,solid: boolean?)
	local half=width/2
	for k=0,3 do
		local p=Instance.new("CornerWedgePart")
		p.Name=name p.Size=Vector3.new(half,height,half)
		p.CFrame=CFrame.new(base)*CFrame.Angles(0,(yaw or 0)+k*math.pi/2,0)*CFrame.new(-half/2,height/2,half/2)
		p.Color=color p.Material=material p.Anchored=true
		p.CanCollide=solid==true p.CanQuery=solid==true p.CanTouch=false
		if width<6 then p.CastShadow=false end
		p.Parent=parent
	end
end

-- Cristal: prisma translúcido com núcleo luminoso e ponta piramidal. `tilt` em radianos (X,Z).
function Kit.crystal(parent: Instance,base: Vector3,height: number,width: number,color: Color3,tiltX: number,tiltZ: number,yaw: number,solid: boolean?)
	local m=Instance.new("Model") m.Name="Crystal"
	local frame=CFrame.new(base)*CFrame.Angles(0,yaw,0)*CFrame.Angles(tiltX,0,tiltZ)
	local body=height*0.78
	local prism=Art.part(m,"CrystalBody",Vector3.new(width,body,width),frame*CFrame.new(0,body/2,0)*CFrame.Angles(0,math.pi/4,0),color,Enum.Material.Glass,nil,solid==true)
	prism.Transparency=0.18 prism.Reflectance=0.05
	local core=Art.part(m,"CrystalCore",Vector3.new(width*0.38,body*0.86,width*0.38),frame*CFrame.new(0,body*0.5,0)*CFrame.Angles(0,math.pi/4,0),color:Lerp(Color3.new(1,1,1),0.35),Enum.Material.Neon,nil,false)
	core.CastShadow=false
	if width<3 then prism.CastShadow=false end
	-- Ponta: pirâmide alinhada ao prisma (girada 45°), no topo do corpo.
	local half=width/2
	for k=0,3 do
		local tip=Instance.new("CornerWedgePart")
		tip.Name="CrystalTip" tip.Size=Vector3.new(half,height-body,half)
		tip.CFrame=frame*CFrame.new(0,body,0)*CFrame.Angles(0,math.pi/4+k*math.pi/2,0)*CFrame.new(-half/2,(height-body)/2,half/2)
		tip.Color=color tip.Material=Enum.Material.Glass tip.Transparency=0.18
		tip.Anchored=true tip.CanCollide=false tip.CanQuery=false tip.CanTouch=false tip.CastShadow=false
		tip.Parent=m
	end
	m.Parent=parent
end

-- Aglomerado de cristais em leque.
function Kit.crystalCluster(parent: Instance,base: Vector3,scale: number,rng: Random,colors: {Color3},solidCenter: boolean?)
	local count=rng:NextInteger(3,6)
	for i=1,count do
		local center=i==1
		local h=scale*(if center then rng:NextNumber(0.9,1.1) else rng:NextNumber(0.35,0.75))
		local w=h*rng:NextNumber(0.16,0.24)
		local a=rng:NextNumber(0,math.pi*2)
		local offset=if center then Vector3.zero else Vector3.new(math.cos(a),0,math.sin(a))*scale*rng:NextNumber(0.08,0.22)
		local tilt=if center then rng:NextNumber(-0.08,0.08) else rng:NextNumber(0.25,0.6)
		Kit.crystal(parent,base+offset-Vector3.new(0,h*0.05,0),h,w,colors[rng:NextInteger(1,#colors)],tilt*math.sin(a),-tilt*math.cos(a),rng:NextNumber(0,math.pi),center and solidCenter==true)
	end
end

-- Ponte em arcos de pedra com parapeito. Deck plano em deckY; pilares descem até floorY.
-- `hanging`: pilares terminam em rocha pendente (ponte sobre o vazio), sem chegar ao chão.
function Kit.bridge(parent: Instance,name: string,a: Vector3,b: Vector3,deckY: number,floorY: number,width: number,bays: number,color: Color3,material: Enum.Material,trim: Color3?,hanging: boolean?)
	local dir=flat(b-a).Unit
	local length=flat(b-a).Magnitude
	local side=Vector3.new(-dir.Z,0,dir.X)
	local mid=(a+b)/2
	local m=Kit.folder(parent,name)
	local deck=Vector3.new(mid.X,deckY-0.6,mid.Z)
	Kit.block(m,"Deck",Vector3.new(width,1.2,length),CFrame.lookAt(deck,deck+dir),color,material)
	local bay=length/bays
	for i=0,bays do
		local p=a+dir*(bay*i)
		local h=deckY-1.2-floorY
		if hanging then h=math.min(h,bay*0.9) end
		local center=Vector3.new(p.X,deckY-1.2-h/2,p.Z)
		Kit.block(m,"Pier",Vector3.new(width,h,2.6),CFrame.lookAt(center,center+dir),color:Lerp(Color3.new(0,0,0),0.12),material)
		if hanging then
			local tip=Kit.deco(m,"PierRock",Vector3.new(width*0.9,h*0.5,3.2),CFrame.new(center-Vector3.new(0,h*0.6,0))*CFrame.Angles(0,i,0),color:Lerp(Color3.new(0,0,0),0.3),Enum.Material.Rock,Enum.PartType.Ball)
			tip.CastShadow=false
		end
	end
	for i=0,bays-1 do
		local c=a+dir*(bay*(i+0.5))
		local r=bay*0.5-1.3
		local springY=deckY-1.2-r-0.6
		local segments=9
		for k=0,segments-1 do
			local t=(k+0.5)*math.pi/segments
			local radial=dir*(-math.cos(t))+Vector3.new(0,math.sin(t),0)
			local p=Vector3.new(c.X,springY,c.Z)+radial*r
			local v=Kit.block(m,"Voussoir",Vector3.new(width-0.2,1.3,math.pi*r/segments+0.25),CFrame.fromMatrix(p,side,radial),color,material,false)
			v.CastShadow=false v.CanQuery=false
		end
	end
	for _,s in {-1,1} do
		local edge=mid+side*s*(width/2-0.3)
		local rail=Vector3.new(edge.X,deckY+0.55,edge.Z)
		Kit.block(m,"Parapet",Vector3.new(0.6,1.1,length),CFrame.lookAt(rail,rail+dir),trim or color,material)
		for i=0,bays do
			local post=a+dir*(bay*i)+side*s*(width/2-0.3)
			Kit.block(m,"ParapetPost",Vector3.new(1,1.9,1),CFrame.new(post.X,deckY+0.95,post.Z),trim or color,material)
		end
	end
	return m
end

-- Arco de passagem (portal arquitetônico) virado para `facing`.
function Kit.archway(parent: Instance,name: string,base: Vector3,facing: Vector3,span: number,height: number,depth: number,color: Color3,material: Enum.Material,glow: Color3?)
	local m=Kit.folder(parent,name)
	local dir=flat(facing).Unit
	local side=Vector3.new(-dir.Z,0,dir.X)
	local pier=math.max(2,span*0.18)
	local rise=height-span/2
	for _,s in {-1,1} do
		local p=base+side*s*(span/2+pier/2)+Vector3.new(0,rise/2,0)
		Kit.block(m,"ArchPier",Vector3.new(pier,rise,depth),CFrame.lookAt(p,p+dir),color,material)
		if glow then
			local g=Kit.glow(m,"ArchRune",Vector3.new(pier*0.22,rise*0.55,0.12),CFrame.lookAt(p-dir*(depth/2+0.07),p-dir*(depth/2+0.07)-dir),glow)
			g.Transparency=0.1
		end
	end
	local r=span/2+pier/2
	local segments=11
	for k=0,segments-1 do
		local t=(k+0.5)*math.pi/segments
		local radial=side*math.cos(t)+Vector3.new(0,math.sin(t),0)
		local p=base+Vector3.new(0,rise,0)+radial*r
		local tangent=side*(-math.sin(t))+Vector3.new(0,math.cos(t),0)
		Kit.block(m,"ArchStone",Vector3.new(pier,math.pi*r/segments+0.3,depth),CFrame.fromMatrix(p,radial,tangent),color,material,false).CanQuery=false
	end
	return m
end

-- Cascata de "líquido" (água, areia, energia) caindo de `top`.
function Kit.fall(parent: Instance,name: string,top: Vector3,height: number,width: number,facing: Vector3,color: Color3,neon: boolean?)
	local dir=flat(facing).Unit
	local side=Vector3.new(-dir.Z,0,dir.X)
	for i=1,3 do
		local offset=side*((i-2)*width/3)
		local center=top+offset-Vector3.new(0,height/2,0)+dir*(i%2)*0.3
		local f=Art.part(parent,name,Vector3.new(width/3,height,0.25),CFrame.lookAt(center,center+dir),color,if neon then Enum.Material.Neon else Enum.Material.Glass,nil,false)
		f.Transparency=(if neon then 0.45 else 0.3)+i*0.08 f.CastShadow=false f.CanQuery=false
	end
	local mist=Art.part(parent,name.."Mist",Vector3.new(width*1.8,5,width*1.3),CFrame.new(top-Vector3.new(0,height,0)),color:Lerp(Color3.new(1,1,1),0.6),Enum.Material.SmoothPlastic,Enum.PartType.Ball,false)
	mist.Transparency=0.82 mist.CastShadow=false mist.CanQuery=false
end

-- Ilha flutuante: piso jogável plano e massa de rocha pendente sem colisão.
function Kit.island(parent: Instance,name: string,center: Vector3,top: number,radius: number,floor: Color3,floorMaterial: Enum.Material,rock: Color3,rng: Random,depth: number?)
	local m=Kit.folder(parent,name)
	Kit.disc(m,"IslandFloor",center,radius,2,top,floor,floorMaterial)
	local d=depth or radius*1.4
	-- Borda de penhasco logo abaixo do piso e massa em cone invertido (camadas que afunilam
	-- com deslocamentos), terminando em pontas pendentes: lê como rocha arrancada do chão.
	local rim=Kit.deco(m,"IslandRim",Vector3.new(radius*0.16+3,radius*2.06,radius*2.06),CFrame.new(center.X,top-2-(radius*0.16+3)/2,center.Z)*CFrame.Angles(0,0,math.pi/2),rock:Lerp(floor,0.25),Enum.Material.Rock,Enum.PartType.Cylinder)
	rim.CastShadow=true
	local layers=5
	local t=d/layers
	for k=0,layers-1 do
		local f=1-k/layers
		local r=radius*(0.18+0.84*f)
		local jitter=Vector3.new(rng:NextNumber(-1,1),0,rng:NextNumber(-1,1))*radius*0.08*k/layers
		local layer=Kit.deco(m,"IslandRock",Vector3.new(r*2,t*1.9,r*2*rng:NextNumber(0.9,1.05)),CFrame.new(Vector3.new(center.X,top-3-t*(k+0.5),center.Z)+jitter)*CFrame.Angles(0,rng:NextNumber(0,6),0),rock:Lerp(Color3.new(0,0,0),k*0.04),Enum.Material.Rock,Enum.PartType.Ball)
		layer.CastShadow=k<2
	end
	for i=1,4 do
		local a=i*math.pi/2+rng:NextNumber(-0.5,0.5)
		local off=radius*rng:NextNumber(0.1,0.35)
		local h=d*rng:NextNumber(0.35,0.6)
		local w=radius*rng:NextNumber(0.14,0.26)
		Kit.deco(m,"IslandSpike",Vector3.new(w,h,w),CFrame.new(center.X+math.cos(a)*off,top-3-d*0.7-h*0.3,center.Z+math.sin(a)*off)*CFrame.Angles(rng:NextNumber(-0.15,0.15),a,rng:NextNumber(-0.15,0.15)),rock:Lerp(Color3.new(0,0,0),0.18),Enum.Material.Rock,Enum.PartType.Ball)
	end
	return m
end

-- Laje de salto flutuante.
function Kit.stepStone(parent: Instance,center: Vector3,top: number,radius: number,color: Color3,rock: Color3,index: number)
	Kit.disc(parent,"FloatingStep",center,radius,1,top,color,Enum.Material.Slate)
	local under=Kit.deco(parent,"FloatingRock",Vector3.new(radius*1.9,radius*1.6,radius*1.9),CFrame.new(center.X,top-1-radius*0.55,center.Z)*CFrame.Angles(0,index,0),rock,Enum.Material.Rock,Enum.PartType.Ball)
	under.CastShadow=false
end

-- Estandarte de tecido com emblema (anel luminoso + disco escuro: sol/eclipse).
function Kit.banner(parent: Instance,cf: CFrame,width: number,height: number,cloth: Color3,emblem: Color3,dark: Color3?)
	Kit.deco(parent,"BannerRod",Vector3.new(width+0.8,0.25,0.25),cf*CFrame.new(0,height/2+0.2,0),Color3.fromRGB(150,118,64),Enum.Material.Metal)
	Kit.deco(parent,"BannerCloth",Vector3.new(width,height,0.12),cf,cloth,Enum.Material.Fabric)
	local r=width*0.32
	local ring=Art.part(parent,"BannerEmblem",Vector3.new(0.06,r*2,r*2),cf*CFrame.new(0,height*0.12,-0.1)*CFrame.Angles(0,math.pi/2,0),emblem,Enum.Material.Neon,Enum.PartType.Cylinder,false)
	ring.CastShadow=false
	local core=Art.part(parent,"BannerEmblemCore",Vector3.new(0.08,r*1.55,r*1.55),cf*CFrame.new(0,height*0.12,-0.12)*CFrame.Angles(0,math.pi/2,0),dark or cloth:Lerp(Color3.new(0,0,0),0.5),Enum.Material.Fabric,Enum.PartType.Cylinder,false)
	core.CastShadow=false
	-- Barra dourada na base do tecido.
	Kit.deco(parent,"BannerFringe",Vector3.new(width,0.35,0.16),cf*CFrame.new(0,-height/2+0.3,-0.02),Color3.fromRGB(176,138,70),Enum.Material.Metal)
end

-- Torre com telhado em pirâmide pontuda (agulha gótica).
function Kit.spire(parent: Instance,base: Vector3,width: number,height: number,roof: number,wall: Color3,roofColor: Color3,material: Enum.Material,windows: Color3?,solid: boolean?)
	local m=Kit.folder(parent,"Spire")
	local body=Kit.block(m,"TowerBody",Vector3.new(width,height,width),CFrame.new(base+Vector3.new(0,height/2,0)),wall,material,solid)
	if solid==false then body.CanQuery=false end
	Kit.deco(m,"TowerCornice",Vector3.new(width*1.18,width*0.14+0.4,width*1.18),CFrame.new(base+Vector3.new(0,height,0)),wall:Lerp(Color3.new(0,0,0),0.15),material)
	Kit.pyramid(m,"TowerRoof",base+Vector3.new(0,height+width*0.07,0),width*1.05,roof,roofColor,Enum.Material.Slate)
	Kit.deco(m,"Finial",Vector3.new(0.35,roof*0.12+1,0.35),CFrame.new(base+Vector3.new(0,height+roof+roof*0.06,0)),Color3.fromRGB(150,118,64),Enum.Material.Metal)
	if windows then
		local rows=math.max(1,math.floor(height/9))
		for r=1,rows do
			for k=0,3 do
				local a=k*math.pi/2
				local normal=Vector3.new(math.sin(a),0,math.cos(a))
				local p=base+Vector3.new(0,r*height/(rows+1),0)+normal*(width/2+0.06)
				Kit.glow(m,"TowerWindow",Vector3.new(math.min(1.6,width*0.18),2.4,0.12),CFrame.lookAt(p,p+normal),windows)
			end
		end
	end
	return m
end

-- Marcadores para a jogabilidade futura (encontros, objetivos, arena de chefe, ponto seguro).
-- Invisíveis, sem colisão; a fase de jogabilidade lê Kind/Radius/Label.
function Kit.slot(parent: Instance,kind: string,name: string,position: Vector3,radius: number,label: string?): Part
	local p=Instance.new("Part") p.Name=name p.Size=Vector3.new(1,1,1) p.CFrame=CFrame.new(position)
	p.Transparency=1 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
	p:SetAttribute("Kind",kind) p:SetAttribute("Radius",radius)
	if label then p:SetAttribute("Label",label) end
	p.Parent=parent
	return p
end

-- Ponto de chegada: círculo rúnico no chão + marcador "Arrival" (CFrame onde o jogador aparece).
function Kit.arrival(parent: Instance,name: string,position: Vector3,facing: Vector3,glow: Color3,stone: Color3): Part
	local ring=Kit.ring(parent,"ArrivalRing",position,5.5,0.35,0.1,position.Y+0.06,24,glow,Enum.Material.Neon,nil,nil,false)
	for _,p in ring do p.CastShadow=false p.CanQuery=false end
	Kit.ring(parent,"ArrivalRingInner",position,3.2,0.2,0.1,position.Y+0.06,16,glow,Enum.Material.Neon,nil,nil,false)
	for i=0,3 do
		local a=i*math.pi/2+math.pi/4
		local p=position+Vector3.new(math.cos(a)*4.3,0.06,math.sin(a)*4.3)
		Kit.glow(parent,"ArrivalSpoke",Vector3.new(0.18,0.1,2.2),CFrame.lookAt(p,position+Vector3.new(0,0.06,0)),glow)
	end
	local marker=Kit.slot(parent,"SafePoint",name,position+Vector3.new(0,3,0),8)
	marker.CFrame=CFrame.lookAt(position+Vector3.new(0,3,0),position+Vector3.new(0,3,0)+flat(facing).Unit)
	return marker
end

-- Portal de travessia entre regiões: anel de pedra com runas, véu luminoso e "Rift" para o prompt.
function Kit.travelGate(parent: Instance,name: string,base: Vector3,facing: Vector3,radius: number,ringColor: Color3,glow: Color3,title: string,subtitle: string?): Model
	local m=Instance.new("Model") m.Name=name
	local dir=flat(facing).Unit
	local frame=CFrame.lookAt(base+Vector3.new(0,radius+1,0),base+Vector3.new(0,radius+1,0)+dir)
	for i=1,18 do
		local a=(i/18)*math.pi*2
		local cf=frame*CFrame.new(math.cos(a)*radius,math.sin(a)*radius,0)*CFrame.Angles(0,0,a+math.pi/2)
		Kit.block(m,"GateStone",Vector3.new(radius*0.38,2.6,3),cf,ringColor,Enum.Material.Slate)
		if i%2==0 then Kit.glow(m,"GateRune",Vector3.new(0.25,1.4,0.12),cf*CFrame.new(-0.7,0,-1.56),glow) end
	end
	Kit.block(m,"GatePlinth",Vector3.new(radius*2.6,1,6),frame*CFrame.new(0,-radius-0.5,0),ringColor:Lerp(Color3.new(0,0,0),0.15),Enum.Material.Slate)
	local rift=Art.part(m,"Rift",Vector3.new(radius*1.62,radius*1.8,0.3),frame,glow,Enum.Material.Neon,Enum.PartType.Ball,false)
	rift.Transparency=0.55 rift.CastShadow=false
	Kit.light(rift,glow,radius*2.4,1.2)
	for arm=1,2 do
		for step=1,14 do
			local function point(t: number): Vector3
				local angle=t*math.pi*3+arm*math.pi
				local reach=radius*(0.08+t*0.7)
				return (frame*CFrame.new(math.cos(angle)*reach,math.sin(angle)*reach,-0.3)).Position
			end
			local line=Art.segment(m,"GateSpiral",point((step-1)/14),point(step/14),radius*0.03,glow:Lerp(Color3.new(1,1,1),if arm==1 then 0.4 else 0),Enum.Material.Neon)
			line.Transparency=0.2+step/14*0.4 line.CastShadow=false
		end
	end
	Art.label(rift,title,subtitle,nil,radius+2)
	m.Parent=parent
	return m
end

-- Flores luminosas baixas (sem colisão, sem sombra).
function Kit.flowers(parent: Instance,center: Vector3,radius: number,count: number,colors: {Color3},rng: Random,groundY: number)
	for _=1,count do
		local a=rng:NextNumber(0,math.pi*2)
		local r=radius*math.sqrt(rng:NextNumber())
		local p=Vector3.new(center.X+math.cos(a)*r,groundY,center.Z+math.sin(a)*r)
		local stem=Kit.deco(parent,"FlowerStem",Vector3.new(0.12,0.9,0.12),CFrame.new(p+Vector3.new(0,0.45,0)),Color3.fromRGB(62,96,64),Enum.Material.Grass)
		stem.CastShadow=false
		local bloom=Kit.deco(parent,"FlowerBloom",Vector3.new(0.7,0.25,0.7),CFrame.new(p+Vector3.new(0,0.95,0))*CFrame.Angles(0,a,0),colors[rng:NextInteger(1,#colors)],Enum.Material.Neon,Enum.PartType.Ball)
		bloom.Transparency=0.05
	end
end

-- Pedra decorativa elipsoidal.
function Kit.rock(parent: Instance,position: Vector3,size: Vector3,color: Color3,material: Enum.Material,yaw: number,solid: boolean?)
	return Art.part(parent,"Boulder",size,CFrame.new(position)*CFrame.Angles(0,yaw,yaw*0.1),color,material,Enum.PartType.Ball,solid==true)
end

-- Balaustrada ao longo de a→b (corrimão com balaústres).
function Kit.balustrade(parent: Instance,a: Vector3,b: Vector3,color: Color3,material: Enum.Material,height: number?)
	local h=height or 2.2
	local dir=(b-a)
	local length=dir.Magnitude
	local mid=(a+b)/2
	Kit.block(parent,"Handrail",Vector3.new(0.9,0.5,length),CFrame.lookAt(mid+Vector3.new(0,h,0),b+Vector3.new(0,h,0)),color,material)
	local posts=math.max(2,math.floor(length/2.2))
	for i=0,posts do
		local p=a:Lerp(b,i/posts)
		Kit.deco(parent,"Baluster",Vector3.new(0.45,h,0.45),CFrame.new(p+Vector3.new(0,h/2,0)),color,material)
	end
	Kit.block(parent,"RailBase",Vector3.new(1,0.4,length),CFrame.lookAt(mid+Vector3.new(0,0.2,0),b+Vector3.new(0,0.2,0)),color,material)
end

return Kit
