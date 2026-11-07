--!strict
-- Figuras procedurais originais dos vilões, usadas nas visões (só no cliente, sem colisão).
-- Regente do Vazio: referência assets/world/references/09-regente-do-vazio.png (capuz, coroa
-- dourada de pontas, rosto sombrio com olhos violeta, ombreiras douradas, gema no peito, manto
-- longo e mão em garra estendida). Arauto Partido: vilão da fase 5 (ver docs/VILLAINS.md).
local Art=require(script.Parent.Art)
local Villain={}

local C=Color3.fromRGB
local robe=C(34,22,52)
local robeDeep=C(20,12,32)
local gold=C(206,164,86)
local violet=C(186,110,255)

local function piece(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,material: Enum.Material,shape: Enum.PartType?): Part
	local p=Art.part(parent,name,size,cf,color,material,shape,false)
	p.CanQuery=false p.CastShadow=false
	return p
end

local function spike(parent: Instance,base: CFrame,width: number,height: number,color: Color3)
	local half=width/2
	for k=0,3 do
		local w=Instance.new("CornerWedgePart") w.Name="CrownSpike" w.Size=Vector3.new(half,height,half)
		w.CFrame=base*CFrame.Angles(0,k*math.pi/2,0)*CFrame.new(-half/2,height/2,half/2)
		w.Color=color w.Material=Enum.Material.Metal w.Anchored=true w.CanCollide=false w.CanQuery=false w.CanTouch=false w.CastShadow=false
		w.Parent=parent
	end
end

-- Regente do Vazio com ~`scale`×7 studs de altura, de frente para −Z do `cf`.
-- Devolve o modelo e o CFrame da cabeça (para enquadrar a câmera).
function Villain.regent(parent: Instance,cf: CFrame,scale: number): (Model,CFrame)
	local m=Instance.new("Model") m.Name="RegenteDoVazio"
	local s=scale
	local function at(x: number,y: number,z: number): CFrame return cf*CFrame.new(x*s,y*s,z*s) end
	-- Manto longo em camadas (afunila para cima), barra rasgada flutuando.
	for i,layer in {{2.6,0.4,1.6},{2.3,1.6,1.5},{2.0,2.8,1.35},{1.8,3.9,1.2}} do
		piece(m,"RobeLayer",Vector3.new(layer[1],1.4,layer[3])*s,at(0,layer[2],0.05*i),if i%2==0 then robe else robeDeep,Enum.Material.Fabric,Enum.PartType.Ball)
	end
	for k=0,6 do
		local a=k/6*math.pi*2
		piece(m,"RobeTatter",Vector3.new(0.5,1.4,0.18)*s,at(math.cos(a)*1.05,-0.15,math.sin(a)*0.7)*CFrame.Angles(0.15*math.sin(a),a,0.15*math.cos(a)),robeDeep,Enum.Material.Fabric)
	end
	-- Peito com placas escuras de bordas douradas e gema violeta.
	piece(m,"Breastplate",Vector3.new(1.7,1.5,0.9)*s,at(0,4.7,-0.1),C(28,24,36),Enum.Material.Metal,Enum.PartType.Ball)
	for _,y in {4.2,4.9} do piece(m,"PlateTrim",Vector3.new(1.5,0.08,0.95)*s,at(0,y,-0.12),gold,Enum.Material.Metal) end
	local gem=piece(m,"ChestGem",Vector3.new(0.42,0.6,0.2)*s,at(0,4.75,-0.58),violet,Enum.Material.Neon,Enum.PartType.Ball)
	local light=Instance.new("PointLight") light.Color=violet light.Range=10*s light.Brightness=2 light.Shadows=false light.Parent=gem
	-- Ombreiras em lâmina, curvadas para cima.
	for _,side in {-1,1} do
		local shoulder=at(side*1.15,5.35,0)
		piece(m,"Pauldron",Vector3.new(1.3,0.6,1.2)*s,shoulder*CFrame.Angles(0,0,side*-0.35),C(30,26,40),Enum.Material.Metal,Enum.PartType.Ball)
		piece(m,"PauldronBlade",Vector3.new(0.25,1.5,0.5)*s,shoulder*CFrame.new(side*0.45*s,0.55*s,0)*CFrame.Angles(0,0,side*-0.55),gold,Enum.Material.Metal,Enum.PartType.Ball)
		piece(m,"PauldronTrim",Vector3.new(1.32,0.1,1.22)*s,shoulder*CFrame.new(0,-0.2*s,0)*CFrame.Angles(0,0,side*-0.35),gold,Enum.Material.Metal,Enum.PartType.Ball)
	end
	-- Capuz profundo e rosto sombrio com olhos violeta e barba escura.
	local headCF=at(0,6.3,-0.05)
	piece(m,"Hood",Vector3.new(1.35,1.6,1.4)*s,headCF*CFrame.new(0,0.1*s,0.12*s),robe,Enum.Material.Fabric,Enum.PartType.Ball)
	piece(m,"HoodRim",Vector3.new(1.05,1.3,0.2)*s,headCF*CFrame.new(0,0,-0.52*s),robeDeep,Enum.Material.Fabric,Enum.PartType.Ball)
	piece(m,"Face",Vector3.new(0.72,0.95,0.4)*s,headCF*CFrame.new(0,-0.05*s,-0.45*s),C(46,34,58),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
	piece(m,"Beard",Vector3.new(0.5,0.5,0.25)*s,headCF*CFrame.new(0,-0.45*s,-0.52*s),C(22,16,28),Enum.Material.Fabric,Enum.PartType.Ball)
	for _,side in {-1,1} do
		local eye=piece(m,"Eye",Vector3.new(0.17,0.08,0.06)*s,headCF*CFrame.new(side*0.16*s,0.08*s,-0.66*s)*CFrame.Angles(0,0,side*-0.25),C(230,190,255),Enum.Material.Neon)
		eye.Name="RegentEye"
	end
	-- Coroa: aro dourado sobre o capuz com cinco pontas de alturas diferentes.
	piece(m,"CrownBand",Vector3.new(0.26,1.25,1.25)*s,headCF*CFrame.new(0,0.62*s,0.05*s)*CFrame.Angles(0,0,math.pi/2),gold,Enum.Material.Metal,Enum.PartType.Cylinder)
	for k=-2,2 do
		local a=k*0.42
		local base=headCF*CFrame.new(math.sin(a)*0.55*s,0.72*s,-math.cos(a)*0.55*s+0.05*s)*CFrame.Angles(-0.15,a,0)
		spike(m,base,0.32*s,(0.75-math.abs(k)*0.14)*s,gold)
		if k==0 then piece(m,"CrownGem",Vector3.new(0.14,0.2,0.08)*s,base*CFrame.new(0,0.2*s,-0.1*s),violet,Enum.Material.Neon,Enum.PartType.Ball) end
	end
	-- Braço direito estendido com mão em garra violeta; o esquerdo some sob o manto.
	local shoulder=at(1.2,5.0,-0.1)
	local hand=shoulder*CFrame.new(0.6*s,-0.2*s,-2.0*s)
	Art.segment(m,"Arm",shoulder.Position,hand.Position,0.55*s,robe,Enum.Material.Fabric).CanQuery=false
	piece(m,"Bracer",Vector3.new(0.62,0.62,0.9)*s,CFrame.lookAt(shoulder.Position:Lerp(hand.Position,0.7),hand.Position),gold,Enum.Material.Metal,Enum.PartType.Ball)
	piece(m,"Palm",Vector3.new(0.6,0.7,0.3)*s,hand,C(120,70,170),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
	for k=-2,2 do
		local finger=hand*CFrame.Angles(0,0,k*0.28)*CFrame.new(0,0.55*s,-0.1*s)*CFrame.Angles(-0.5,0,0)
		piece(m,"Claw",Vector3.new(0.13,0.55,0.13)*s,finger,C(140,80,200),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
	end
	local glow=piece(m,"PalmGlow",Vector3.new(1.1,1.1,1.1)*s,hand*CFrame.new(0,0.2*s,-0.3*s),violet,Enum.Material.Neon,Enum.PartType.Ball)
	glow.Transparency=0.55
	-- Névoa do vazio na barra do manto.
	local mist=Instance.new("ParticleEmitter") mist.Name="VoidMist" mist.Color=ColorSequence.new(C(120,60,200),C(30,10,50))
	mist.LightEmission=0.6 mist.Rate=18 mist.Lifetime=NumberRange.new(1.2,2) mist.Speed=NumberRange.new(0.5,1.5)
	mist.Size=NumberSequence.new(1.2*s,2.4*s) mist.Transparency=NumberSequence.new(0.5,1) mist.SpreadAngle=Vector2.new(60,60)
	mist.Parent=m:FindFirstChild("RobeLayer")
	m.Parent=parent
	return m,headCF
end

return Villain
