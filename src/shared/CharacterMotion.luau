--!strict
-- Poses originais locais: apresentação apenas, sem mover a raiz ou conceder dano.
-- Convenções medidas nos rigs gerados (AnimationConstraint.Transform):
--   ombro X+ leva o braço para a frente/para cima; cotovelo X+ dobra o antebraço para a frente;
--   cintura X+ inclina o tronco para trás; cintura Y gira o tronco.
local Motion={}

-- Momentos usados também pelos efeitos (flecha/esfera saem quando a pose solta).
Motion.Timing={
	Guardian={duration=0.56,release=0.42},
	Explorer={duration=0.5,release=0.56},
	Artificer={duration=0.56,release=0.5},
	Skill={duration=0.95},
	Dash={duration=0.35},
}

-- Poses calibradas no Play de 03/11/2026 (ombro X,Y,Z e cotovelo X; rig gerado do Explorador),
-- buscando a posição das mãos relativa à raiz: arco estendido à frente na altura do ombro,
-- mão da corda junto à bochecha e mão aberta para trás depois de soltar.
Motion.BOW_ARM={1.89,-1.06,1.00,0.31}
Motion.DRAW_HAND={1.50,2.00,-0.93,2.44}
Motion.RELEASE_HAND={0.95,1.50,0.25,2.85}
-- Artífice (rig gerado da Artífice): mãos juntas à frente do peito e depois estendidas.
Motion.CHARGE_R={1.00,1.50,-0.50,1.50}
Motion.CHARGE_L={1.00,-1.25,1.12,2.00}
Motion.PUSH_R={1.56,0.94,-1.00,0.39}
Motion.PUSH_L={1.56,-0.54,1.00,0.29}

local function blendArm(name: string,side: string,a: {number},b: {number},k: number,scale: number): (number,number,number)
	local p={}
	for i=1,4 do p[i]=(a[i]+(b[i]-a[i])*k)*scale end
	if name==side.."shoulder" then return p[1],p[2],p[3] end
	return p[4],0,0
end

local function ease(x: number): number
	x=math.clamp(x,0,1)
	return x*x*(3-2*x)
end

local function window(t: number,a: number,b: number): number
	return ease((t-a)/math.max(b-a,0.001))
end

local function attackPose(name: string,classId: string,t: number): (number,number,number)
	local x,y,z=0,0,0
	local recover=1-window(t,0.72,1)
	if classId=="Guardian" then
		-- Preparação acima do ombro, corte diagonal com giro do tronco, acompanhamento.
		local wind=window(t,0,0.3)
		local strike=window(t,0.3,0.52)
		-- Ombro direito: Z+ afasta do corpo, Z− cruza à frente (medido por captura).
		if name=="rightshoulder" then x=(2.5*wind-1.6*strike) z=(0.2*wind-0.75*strike)
		elseif name=="rightelbow" then x=1.1*wind-0.8*strike
		elseif name=="rightwrist" then x=-0.35*wind+0.6*strike
		-- Guarda: antebraço do escudo erguido à frente do peito (no ombro esquerdo, Z+ traz o braço para dentro).
		elseif name=="leftshoulder" then x=0.3 z=0.9
		elseif name=="leftelbow" then x=1.3
		elseif name=="waist" then y=0.45*wind-0.8*strike x=0.06*wind-0.14*strike end
	elseif classId=="Explorer" then
		-- Arqueiro: arco à frente, mão direita puxa a corda até a bochecha e solta em `release`.
		-- Ângulos calibrados no Play medindo as mãos (BOW_ARM, DRAW_HAND, RELEASE_HAND).
		local raise=window(t,0,0.18)
		local draw=window(t,0.1,0.5)
		local released=window(t,Motion.Timing.Explorer.release,Motion.Timing.Explorer.release+0.08)
		if name=="leftshoulder" or name=="leftelbow" then
			local a=Motion.BOW_ARM
			if name=="leftshoulder" then x,y,z=a[1]*raise,a[2]*raise,a[3]*raise else x=a[4]*raise end
		elseif name=="rightshoulder" or name=="rightelbow" then
			local d,r=Motion.DRAW_HAND,Motion.RELEASE_HAND
			local k=math.max(raise*0.35,draw)
			local s={d[1]*k,d[2]*k,d[3]*k,d[4]*k}
			for i=1,4 do s[i]+=(r[i]-d[i])*released end
			if name=="rightshoulder" then x,y,z=s[1],s[2],s[3] else x=s[4] end
		elseif name=="waist" then y=0.2*raise end
	else
		-- Artífice: recolhe o cristal junto ao peito, empurra as duas mãos e libera a esfera.
		local charge=window(t,0,0.4)
		local push=window(t,0.42,0.56)
		if name=="rightshoulder" or name=="rightelbow" then x,y,z=blendArm(name,"right",Motion.CHARGE_R,Motion.PUSH_R,push,charge)
		elseif name=="leftshoulder" or name=="leftelbow" then x,y,z=blendArm(name,"left",Motion.CHARGE_L,Motion.PUSH_L,push,charge)
		elseif name=="waist" then x=0.07*charge-0.14*push end
	end
	return x*recover,y*recover,z*recover
end

local function skillPose(name: string,classId: string,t: number): (number,number,number)
	local x,y,z=0,0,0
	local rise=window(t,0,0.28)
	local recover=1-window(t,0.78,1)
	if classId=="Guardian" then
		-- Égide: escudo empurrado à frente e espada erguida.
		if name=="leftshoulder" then x=1.5*rise z=-0.1*rise
		elseif name=="leftelbow" then x=0.5*rise
		elseif name=="rightshoulder" then x=2.6*rise z=0.15*rise
		elseif name=="rightelbow" then x=0.3*rise
		elseif name=="waist" then x=-0.1*rise end
	elseif classId=="Explorer" then
		-- Rajada: a mesma puxada do ataque, com o tronco inclinado para trás (arco mira o céu).
		local ax,ay,az=attackPose(name,classId,math.clamp(t*1.05,0,0.9))
		if name=="waist" then return 0.5*rise*recover,0,0 end
		return ax,ay,az
	else
		-- Pulso: braços sobem e descem num golpe ao chão.
		local slam=window(t,0.42,0.55)
		if name=="leftshoulder" or name=="rightshoulder" then x=2.7*rise-2.3*slam z=(if name=="leftshoulder" then 0.2 else -0.2)*rise
		elseif name=="leftelbow" or name=="rightelbow" then x=0.25*rise
		elseif name=="waist" then x=0.18*rise-0.5*slam end
	end
	return x*recover,y*recover,z*recover
end

function Motion.pose(name: string, phase: number, stride: number, airborne: boolean, classId: string, attack: number?, time: number, skill: number?, dash: number?): CFrame
	local left=name:find("left")~=nil
	local side=if left then -1 else 1
	local swing=math.sin(phase)*stride
	local lift=math.max(0,math.sin(phase+side*math.pi/2))*stride
	local x,y,z=0,0,0
	local offset=Vector3.zero
	if name:find("shoulder") then
		x=-swing*side*0.6-0.06 z=side*0.06
		if airborne then x=0.6 z=side*0.2 end
	elseif name:find("hip") then
		x=swing*side*0.68 y=side*0.025*stride
		if airborne then x=if left then -0.38 else 0.22 end
	elseif name:find("knee") then x=-lift*0.95-(if airborne then 0.55 else 0.05)
	elseif name:find("ankle") then x=lift*0.35
	elseif name:find("elbow") then x=0.18+math.abs(swing)*0.18
	elseif name=="waist" then y=-swing*0.08 x=-stride*0.05
	elseif name=="root" or name=="rootjoint" then
		offset=Vector3.new(0,math.cos(phase*2)*stride*0.045+math.sin(time*2)*0.012,0)
		z=math.sin(phase)*stride*0.025
	elseif name=="neck" then y=swing*0.025 end
	-- Gestos de combate substituem a parte superior do corpo (habilidade tem prioridade).
	local upper=name:find("shoulder") or name:find("elbow") or name:find("wrist") or name=="waist"
	if upper and (skill or attack) then
		local ax,ay,az
		if skill then ax,ay,az=skillPose(name,classId,skill) else ax,ay,az=attackPose(name,classId,attack :: number) end
		if name=="waist" then x,y,z=x*0.3+ax,y*0.3+ay,az else x,y,z=ax,ay,az end
	end
	if dash and name=="waist" then
		-- Esquiva: inclina o tronco para a frente e recupera.
		x+=-0.38*math.sin(math.clamp(dash,0,1)*math.pi)
	end
	return CFrame.new(offset)*CFrame.Angles(x,y,z)
end

return Motion
