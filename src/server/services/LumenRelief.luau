--!strict
-- Relevo do Vale de Lúmen pela referência 2: vale em camadas, mesa do portal com
-- escadaria, garganta com aqueduto, inscrições em colina/mesa/ilha flutuante,
-- santuário no alto e arena suspensa alcançada por pedras flutuantes.
--
-- Terreno de voxels dá a massa natural (penhascos, colinas, base das ilhas). A
-- superfície dos voxels varia ~1–4 studs com a quantização, então todo piso onde
-- se luta, pousa ou lê inscrição é uma peça com altura exata (Chapter.Relief).
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Art=require(ReplicatedStorage.Shared.Art)
local Chapter=require(ReplicatedStorage.Shared.Config.Chapter)

local Relief={}
local H=Chapter.Relief

local stone=Color3.fromRGB(146,138,122)
local darkStone=Color3.fromRGB(96,99,104)
local moss=Color3.fromRGB(86,122,74)
local cyan=Color3.fromRGB(76,201,205)

-- Pegadas das estruturas (X/Z): árvores e pedras decorativas não nascem nelas.
local DAWN_CENTER=Vector3.new(-58,0,-180)
local ROOT_CENTER=Vector3.new(66,0,-252)
local STAR_CENTER=Vector3.new(-40,0,-322)
local ARENA_CENTER=Vector3.new(0,0,-550)
local footprints: {{center: Vector3,radius: number}}={
	{center=DAWN_CENTER,radius=24},
	{center=ROOT_CENTER,radius=19},
	{center=STAR_CENTER,radius=21},
	{center=Vector3.new(-83,0,-38),radius=36},
}

local function flat(v: Vector3): Vector3 return Vector3.new(v.X,0,v.Z) end

function Relief.blocked(x: number,z: number,margin: number?): boolean
	local p=Vector3.new(x,0,z)
	for _,f in footprints do
		if (p-f.center).Magnitude<f.radius+(margin or 0) then return true end
	end
	-- Garganta, escadaria do templo, platô do templo e vazio da arena.
	if math.abs(z-H.Gorge.z)<H.Gorge.halfWidth+4 then return true end
	if z<-334 and math.abs(x)<56 then return true end
	if z<-468 then return true end
	-- Linhas de acesso: escadaria da Aurora e pilares da Raiz.
	if z<-170 and z>-188 and x<-8 and x>-40 then return true end
	if z<-236 and z>-256 and x>18 and x<54 then return true end
	return false
end

local function block(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,material: Enum.Material,solid: boolean?): Part
	return Art.part(parent,name,size,cf,color,material,nil,if solid==nil then true else solid)
end

-- Disco vertical (cilindro em pé) com topo em `top`.
local function disc(parent: Instance,name: string,center: Vector3,radius: number,thickness: number,top: number,color: Color3,material: Enum.Material): Part
	return Art.part(parent,name,Vector3.new(thickness,radius*2,radius*2),CFrame.new(center.X,top-thickness/2,center.Z)*CFrame.Angles(0,0,math.pi/2),color,material,Enum.PartType.Cylinder,true)
end

-- Escada maciça: cada degrau desce até `baseY`, sem vãos por baixo.
local function stairs(parent: Instance,name: string,start: Vector3,direction: Vector3,steps: number,topY: number,run: number,width: number,baseY: number,material: Enum.Material?)
	local dir=flat(direction).Unit
	local rise=(topY-start.Y)/steps
	for i=1,steps do
		local top=start.Y+rise*i
		local center=start+dir*(run*(i-0.5))
		local height=top-baseY
		local cf=CFrame.lookAt(Vector3.new(center.X,baseY+height/2,center.Z),Vector3.new(center.X,baseY+height/2,center.Z)+dir)
		local step=block(parent,name,Vector3.new(width,height,run+0.05),cf,stone:Lerp(darkStone,(i%3)*0.08),material or Enum.Material.Slate)
		step.CastShadow=i%2==0
	end
end

local function column(parent: Instance,base: Vector3,height: number,radius: number,broken: boolean)
	Art.segment(parent,"RuinColumn",base,base+Vector3.new(0,height,0),radius*2,stone,Enum.Material.Limestone,true)
	if not broken then
		block(parent,"ColumnCap",Vector3.new(radius*2.6,0.8,radius*2.6),CFrame.new(base+Vector3.new(0,height+0.4,0)),stone,Enum.Material.Slate)
	end
end

local function crystal(parent: Instance,p: Vector3,scale: number,tilt: number)
	local c=Art.part(parent,"ReliefCrystal",Vector3.new(0.8,2.6,0.8)*scale,CFrame.new(p)*CFrame.Angles(tilt,tilt*1.7,tilt*0.6),cyan,Enum.Material.Glass)
	c.Transparency=0.2 c.CastShadow=false
end

-- Pedra flutuante de salto: piso plano com rocha pendurada embaixo.
local function floatingStone(parent: Instance,center: Vector3,top: number,radius: number,index: number)
	disc(parent,"FloatingStep",center,radius,1,top,stone:Lerp(moss,0.15),Enum.Material.Slate)
	local under=Art.part(parent,"FloatingRock",Vector3.new(radius*1.9,radius*1.6,radius*1.9),CFrame.new(center.X,top-1-radius*0.55,center.Z)*CFrame.Angles(0,index,0),darkStone,Enum.Material.Rock,Enum.PartType.Ball)
	under.CanCollide=false under.CanQuery=false under.CastShadow=false
	if index%3==0 then crystal(parent,Vector3.new(center.X+radius*0.6,top-radius*1.4,center.Z),0.6,0.5) end
end

local function arches(parent: Instance,a: Vector3,b: Vector3,deckY: number,floorY: number,width: number,bays: number,name: string)
	local dir=flat(b-a).Unit
	local length=flat(b-a).Magnitude
	local side=Vector3.new(-dir.Z,0,dir.X)
	local mid=(a+b)/2
	block(parent,name.."Deck",Vector3.new(width,1.2,length),CFrame.lookAt(Vector3.new(mid.X,deckY-0.6,mid.Z),Vector3.new(mid.X,deckY-0.6,mid.Z)+dir),stone,Enum.Material.Cobblestone)
	local bay=length/bays
	for i=0,bays do
		local p=a+dir*(bay*i)
		local h=deckY-1.2-floorY
		block(parent,name.."Pier",Vector3.new(width,h,2.4),CFrame.lookAt(Vector3.new(p.X,floorY+h/2,p.Z),Vector3.new(p.X,floorY+h/2,p.Z)+dir),stone:Lerp(darkStone,0.15),Enum.Material.Slate)
	end
	-- Arcos semicirculares entre pilares.
	for i=0,bays-1 do
		local c=a+dir*(bay*(i+0.5))
		local r=bay*0.5-1.2
		local springY=deckY-1.2-r-0.6
		-- Aduelas tangentes ao arco: X atravessa a ponte, Y aponta para fora do centro do arco.
		local segments=9
		for k=0,segments-1 do
			local t=(k+0.5)*math.pi/segments
			local radial=dir*(-math.cos(t))+Vector3.new(0,math.sin(t),0)
			local p=Vector3.new(c.X,springY,c.Z)+radial*r
			local v=block(parent,name.."Voussoir",Vector3.new(width-0.2,1.3,math.pi*r/segments+0.25),CFrame.fromMatrix(p,side,radial),stone,Enum.Material.Slate,false)
			v.CastShadow=false
		end
	end
	for _,s in {-1,1} do
		local edge=mid+side*(width/2-0.3)
		block(parent,name.."Parapet",Vector3.new(0.6,1.1,length),CFrame.lookAt(Vector3.new(edge.X,deckY+0.55,edge.Z),Vector3.new(edge.X,deckY+0.55,edge.Z)+dir),stone,Enum.Material.Slate)
	end
end

local function waterfall(parent: Instance,top: Vector3,height: number,width: number,facing: Vector3)
	for i=1,3 do
		local offset=Vector3.new(-facing.Z,0,facing.X)*((i-2)*width/3)
		local fall=block(parent,"ReliefWaterfall",Vector3.new(width/3,height,0.2),CFrame.lookAt(top+offset-Vector3.new(0,height/2,0),top+offset-Vector3.new(0,height/2,0)+facing),Color3.fromRGB(170,228,233),Enum.Material.Glass,false)
		fall.Transparency=0.3+i*0.08 fall.CastShadow=false fall.CanQuery=false
	end
	local mist=Art.part(parent,"ReliefMist",Vector3.new(width*1.6,4,width*1.2),CFrame.new(top-Vector3.new(0,height,0)),Color3.fromRGB(222,238,240),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
	mist.Transparency=0.85 mist.CastShadow=false mist.CanQuery=false
end

-- Terreno: chamado logo após o chão base, antes de árvores e pedras serem enraizadas.
function Relief.sculpt(terrain: Terrain)
	terrain:SetMaterialColor(Enum.Material.Slate,Color3.fromRGB(120,112,98))
	local rng=Random.new(31337)
	local function cliffRing(center: Vector3,radius: number,y: number,size: number,count: number,material: Enum.Material)
		for i=1,count do
			local a=i*math.pi*2/count+rng:NextNumber(-0.15,0.15)
			terrain:FillBall(center+Vector3.new(math.cos(a)*radius,y,math.sin(a)*radius),size*rng:NextNumber(0.8,1.15),material)
		end
	end
	-- Mesa do Portal: penhasco de calcário com topo gramado.
	terrain:FillBlock(CFrame.new(-83,6,-38),Vector3.new(64,16,62),Enum.Material.Slate)
	terrain:FillBlock(CFrame.new(-83,15,-38),Vector3.new(58,2,56),Enum.Material.LeafyGrass)
	cliffRing(Vector3.new(-83,0,-38),31,6,9,16,Enum.Material.Slate)
	task.wait()
	-- Garganta atravessando o vale entre a vila e a floresta, com riacho no fundo.
	local g=H.Gorge
	terrain:FillBlock(CFrame.new(0,(4+g.bottom)/2,g.z),Vector3.new(340,4-g.bottom,g.halfWidth*2),Enum.Material.Air)
	terrain:FillBlock(CFrame.new(0,g.bottom-1,g.z),Vector3.new(340,4,g.halfWidth*2),Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(0,g.bottom+3,g.z),Vector3.new(340,4,g.halfWidth*2-2),Enum.Material.Water)
	-- Paredes de ardósia íngremes e irregulares, em duas camadas de altura.
	for i=1,22 do
		local x=-160+i*14.5
		for _,s in {-1,1} do
			for _,y in {g.bottom+6,-4} do
				terrain:FillBall(Vector3.new(x+rng:NextNumber(-4,4),y+rng:NextNumber(-2,2),g.z+s*(g.halfWidth+2)),rng:NextNumber(3.5,5),Enum.Material.Slate)
			end
		end
	end
	task.wait()
	-- Colina da Aurora: subida pela escadaria a leste.
	terrain:FillBall(Vector3.new(-60,-14,-182),28,Enum.Material.LeafyGrass)
	terrain:FillBall(Vector3.new(-70,-12,-190),22,Enum.Material.Slate)
	-- Topo da colina encosta na praça (até 4 studs abaixo do piso, sem atravessá-lo).
	terrain:FillCylinder(CFrame.new(DAWN_CENTER.X,H.DawnHill-7,DAWN_CENTER.Z),6,21,Enum.Material.LeafyGrass)
	-- Mesa da Raiz: coluna de rocha alcançada por pilares de salto.
	terrain:FillCylinder(CFrame.new(ROOT_CENTER.X,7,ROOT_CENTER.Z),22,15,Enum.Material.Slate)
	cliffRing(Vector3.new(ROOT_CENTER.X,0,ROOT_CENTER.Z),14,8,6,10,Enum.Material.Slate)
	-- Ilha da Estrela: rocha suspensa sobre a floresta.
	terrain:FillCylinder(CFrame.new(STAR_CENTER.X,24,STAR_CENTER.Z),4,14,Enum.Material.Slate)
	terrain:FillBall(Vector3.new(STAR_CENTER.X,17,STAR_CENTER.Z),9,Enum.Material.Slate)
	terrain:FillBall(Vector3.new(STAR_CENTER.X+3,11,STAR_CENTER.Z+2),5,Enum.Material.Rock)
	task.wait()
	-- Platô do Santuário.
	terrain:FillBlock(CFrame.new(0,9,-421),Vector3.new(100,22,98),Enum.Material.Slate)
	terrain:FillBlock(CFrame.new(0,19,-421),Vector3.new(96,2,94),Enum.Material.LeafyGrass)
	for i=1,7 do
		for _,s in {-1,1} do terrain:FillBall(Vector3.new(s*50,8,-378-i*13),rng:NextNumber(8,11),Enum.Material.Slate) end
	end
	-- Face frontal irregular dos dois lados da escadaria.
	for _,x in {-46,-34,-22,22,34,46} do
		terrain:FillBall(Vector3.new(x,rng:NextNumber(6,12),-372),rng:NextNumber(6,8),Enum.Material.Slate)
	end
	task.wait()
	-- Vazio além do santuário e ilha suspensa da arena.
	terrain:FillBlock(CFrame.new(0,-14,-576),Vector3.new(340,56,208),Enum.Material.Air)
	-- Cone invertido em camadas, com blocos irregulares na borda de cada camada.
	local layers={{30,46},{24,40},{18,32},{12,24},{6,16},{0,9}}
	for index,layer in layers do
		local y,r=layer[1],layer[2]
		terrain:FillCylinder(CFrame.new(ARENA_CENTER.X,y,ARENA_CENTER.Z),6,r,if index%2==0 then Enum.Material.Rock else Enum.Material.Slate)
		for i=1,8 do
			local a=i*math.pi/4+index*0.4+rng:NextNumber(-0.2,0.2)
			terrain:FillBall(ARENA_CENTER+Vector3.new(math.cos(a)*r*0.92,y-2,math.sin(a)*r*0.92),rng:NextNumber(3,6),Enum.Material.Slate)
		end
	end
	terrain:FillBall(Vector3.new(4,-8,-548),6,Enum.Material.Rock)
	task.wait()
end

-- Estruturas jogáveis em coordenadas absolutas: chamado após o ajuste final de Y do mundo.
function Relief.build(world: Model)
	local root=Instance.new("Folder") root.Name="Relief" root.Parent=world
	-- Escadaria monumental até o portal, emoldurada pelo arco de entrada.
	local portal=Instance.new("Folder") portal.Name="PortalMesa" portal.Parent=root
	stairs(portal,"PortalStair",Vector3.new(-80,2,24),Vector3.new(0,0,-1),26,H.PortalMesa,1.42,10,0)
	for i=0,4 do
		for _,s in {-1,1} do
			local z=20-i*8
			local y=2+math.max(0,(24-z)/1.42)*(H.PortalMesa-2)/26
			column(portal,Vector3.new(-80+s*6,y,z),2.2,0.45,false)
			if i%2==0 then
				local lamp=Art.part(portal,"StairLantern",Vector3.new(0.5,0.7,0.5),CFrame.new(-80+s*6,y+3,z),Color3.fromRGB(230,185,110),Enum.Material.Neon)
				lamp.CastShadow=false
			end
		end
	end
	task.wait()
	-- Garganta: ponte em arcos no caminho principal, aqueduto antigo a leste e escadas de saída.
	local gorge=Instance.new("Folder") gorge.Name="Gorge" gorge.Parent=root
	local g=H.Gorge
	arches(gorge,Vector3.new(5,0,g.z+g.halfWidth+4),Vector3.new(5,0,g.z-g.halfWidth-4),2.3,g.bottom,9,2,"GorgeBridge")
	arches(gorge,Vector3.new(58,0,g.z+g.halfWidth+8),Vector3.new(58,0,g.z-g.halfWidth-8),13,g.bottom,5,3,"Aqueduct")
	for _,s in {-1,1} do
		local z=g.z+s*(g.halfWidth-2.5)
		stairs(gorge,"GorgeExit",Vector3.new(s*-20,g.bottom+4,z),Vector3.new(-s,0,0),24,2,1,4.6,g.bottom)
	end
	waterfall(gorge,Vector3.new(100,1,g.z+g.halfWidth),1-(g.bottom+4),6,Vector3.new(0,0,-1))
	for i=1,8 do
		local mist=Art.part(gorge,"GorgeMist",Vector3.new(30,5,g.halfWidth*1.6),CFrame.new(-140+i*35,g.bottom+6,g.z),Color3.fromRGB(226,234,236),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
		mist.Transparency=0.9 mist.CastShadow=false mist.CanQuery=false mist.CanCollide=false
	end
	task.wait()
	-- Colina da Aurora: praça de ruína no topo e escadaria talhada.
	local dawn=Instance.new("Folder") dawn.Name="DawnHill" dawn.Parent=root
	disc(dawn,"DawnPlaza",DAWN_CENTER,20,3,H.DawnHill,stone,Enum.Material.Cobblestone)
	stairs(dawn,"DawnStair",Vector3.new(-12,2,-179),Vector3.new(-1,0,0),20,H.DawnHill,1.3,6,0)
	for i=1,7 do
		local a=i*math.pi*2/7+0.4
		local p=DAWN_CENTER+Vector3.new(math.cos(a)*18,H.DawnHill,math.sin(a)*18)
		if math.cos(a)<0.8 then column(dawn,p,if i%2==0 then 7 else 3.5,0.9,i%2==1) end
	end
	-- Mesa da Raiz: seis pilares crescentes; um erro só devolve ao chão da floresta.
	local rootMesa=Instance.new("Folder") rootMesa.Name="RootMesa" rootMesa.Parent=root
	disc(rootMesa,"RootPlaza",ROOT_CENTER,14,4,H.RootMesa,stone:Lerp(moss,0.1),Enum.Material.Slate)
	local pillars={Vector3.new(24,4.5,-243),Vector3.new(29.5,7.5,-247.5),Vector3.new(35,10.5,-243),Vector3.new(40.5,13.5,-248),Vector3.new(45.5,16.5,-244),Vector3.new(50,19.5,-249)}
	for i,p in pillars do
		Art.segment(rootMesa,"JumpPillar",Vector3.new(p.X,0,p.Z),Vector3.new(p.X,p.Y-0.6,p.Z),3.6,stone:Lerp(darkStone,0.2+i*0.03),Enum.Material.Limestone,true)
		disc(rootMesa,"PillarTop",p,2.1,0.6,p.Y,stone,Enum.Material.Slate)
	end
	-- Ilha da Estrela: pedras flutuantes em espiral ao redor da ilha.
	local star=Instance.new("Folder") star.Name="StarIsland" star.Parent=root
	disc(star,"StarPlaza",STAR_CENTER,14,3,H.StarIsland,stone,Enum.Material.Cobblestone)
	for k=0,8 do
		local a=0.7-k*0.36
		floatingStone(star,STAR_CENTER+Vector3.new(math.cos(a)*18,0,math.sin(a)*18),4.5+k*3,2.2,k)
	end
	waterfall(star,Vector3.new(STAR_CENTER.X-6,H.StarIsland-2,STAR_CENTER.Z-13.5),H.StarIsland-4,4,Vector3.new(0,0,-1))
	for i=1,4 do
		local a=i*math.pi/2+0.3
		column(star,STAR_CENTER+Vector3.new(math.cos(a)*12,H.StarIsland,math.sin(a)*12),if i%2==0 then 6 else 3,0.8,i%2==1)
	end
	task.wait()
	-- Santuário: escadaria frontal larga e muro com o limiar como única passagem.
	local temple=Instance.new("Folder") temple.Name="TempleHeights" temple.Parent=root
	stairs(temple,"TempleStair",Vector3.new(0,2,-340),Vector3.new(0,0,-1),32,H.Temple,1.125,22,0)
	for i=0,3 do
		for _,s in {-1,1} do
			local z=-344-i*9
			local y=2+(-340-z)/1.125*(H.Temple-2)/32
			column(temple,Vector3.new(s*13,y,z),5,0.9,i==3)
		end
	end
	for _,s in {-1,1} do
		block(temple,"ThresholdWall",Vector3.new(34.5,10,2),CFrame.new(s*24.75,H.Temple+5,H.GateZ),stone:Lerp(darkStone,0.2),Enum.Material.Slate)
		block(temple,"ThresholdTower",Vector3.new(4,14,4),CFrame.new(s*9.5,H.Temple+7,H.GateZ),stone,Enum.Material.Slate)
	end
	-- Caminho suspenso até a arena: pedras de tamanho e distância variados.
	local sky=Instance.new("Folder") sky.Name="SkyPath" sky.Parent=root
	local stones={Vector3.new(0,27.5,-474.5),Vector3.new(5.5,29.5,-480),Vector3.new(0.5,31.5,-486.5),Vector3.new(-5,33.5,-491.5),Vector3.new(-0.5,35.5,-497),Vector3.new(4,37.5,-501.5)}
	for i,p in stones do floatingStone(sky,Vector3.new(p.X,0,p.Z),p.Y,if i%2==0 then 1.9 else 2.3,i) end
	-- Rocha sob a borda da arena e ilhas decorativas próximas (referência 2/5).
	disc(sky,"ArenaRim",ARENA_CENTER,47,6,H.Arena-1.2,darkStone,Enum.Material.Slate)
	for i=1,3 do
		local p=Vector3.new(({-70,75,-40})[i],H.Arena+({6,14,-8})[i],({-520,-575,-615})[i])
		local isle=Art.part(sky,"DriftingIsle",Vector3.new(16,10,14),CFrame.new(p)*CFrame.Angles(0,i,0),darkStone,Enum.Material.Rock,Enum.PartType.Ball)
		isle.CanCollide=false isle.CanQuery=false
		Art.part(sky,"DriftingMeadow",Vector3.new(14,2,12),CFrame.new(p+Vector3.new(0,4.2,0)),moss,Enum.Material.Grass,Enum.PartType.Ball).CanCollide=false
		crystal(sky,p+Vector3.new(0,6,0),1.4,0.2*i)
	end
	-- Ilha flutuante com cascata visível da vila, como na referência.
	local vista=Art.part(root,"ValleyFloatingIsle",Vector3.new(34,22,30),CFrame.new(118,62,-150),darkStone,Enum.Material.Rock,Enum.PartType.Ball)
	vista.CanCollide=false vista.CanQuery=false
	Art.part(root,"ValleyIsleMeadow",Vector3.new(30,4,26),CFrame.new(118,72,-150),moss,Enum.Material.Grass,Enum.PartType.Ball).CanCollide=false
	waterfall(root,Vector3.new(118,62,-136),40,5,Vector3.new(0,0,1))
end

return Relief
