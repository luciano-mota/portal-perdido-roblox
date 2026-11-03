--!strict
-- Poses originais locais: apresentação apenas, sem mover a raiz lógica nem conceder dano.
-- Os rigs gerados partem de uma pose em A e somam a animação nativa, então os ângulos não são
-- intuitivos: as poses-chave abaixo foram calibradas no Play medindo mãos, ponta da espada e
-- face do escudo (atributos PoseOverride_<articulação> do AvatarFallback, só no Studio).
-- Cada pose: articulação → {x,y,z} (Euler XYZ, multiplicada sobre a animação nativa);
-- "root" aceita também {x,y,z,ox,oy,oz} com deslocamento (avanço/agachamento).
local Motion={}

Motion.Timing={
	Guardian={duration=0.62,release=0.5},
	Explorer={duration=0.7,release=0.74},
	Artificer={duration=0.56,release=0.5},
	Skill={duration=0.95},
	Dash={duration=0.35},
}
-- Arqueiro gira o corpo de lado para o alvo (ombro esquerdo à frente) enquanto atira.
Motion.StanceYaw={Explorer=-1.0}

type Pose={[string]: {number}}
local P: {[string]: Pose}={}
Motion.Poses=P

-- Guardião (calibrado em 03/11/2026 pelo centro/normal do escudo, mão e direção da lâmina, com
-- penalidade para lâmina dentro do escudo). Guarda: escudo à frente do tronco, olhos acima da
-- borda, espada pronta ao lado sem cruzar o escudo.
P.Guard={leftshoulder={1.55,-1.29,1.38},leftelbow={2.18,0,0},rightshoulder={-0.45,0.82,0.49},rightelbow={2.37,0,0},rightwrist={-0.94,0,-1.83},waist={0,0.15,0},root={0,0,0,0,-0.12,0},leftknee={-0.25,0,0},rightknee={-0.25,0,0}}
-- Durante os golpes o escudo fica pronto, um pouco aberto, para o braço da espada passar livre.
P.ShieldReady={leftshoulder={1.55,-2.49,1.45},leftelbow={2.78,0,0}}
-- Mão do escudo fechada na alça (alinhada ao antebraço) e mão da espada em repouso apontando
-- a lâmina para baixo e para fora, sem tocar o chão.
P.ShieldWrist={0.11,-0.90,1.24}
P.IdleSwordWrist={-0.40,-0.40,0.05}
-- Combo A: corte diagonal de cima para baixo (giro do tronco e passo à frente).
P.A_Wind={rightshoulder={2.62,0.10,-0.55},rightelbow={1.41,0,0},rightwrist={-1.70,0,-0.89},waist={0.06,-0.4,0}}
P.A_Strike={rightshoulder={0.81,0.99,0.42},rightelbow={-0.09,0,0},rightwrist={-0.82,0,-2.78},waist={-0.12,0.45,0},root={0,0,0,0,-0.18,-0.55},leftknee={-0.35,0,0},rightknee={-0.15,0,0}}
-- Combo B: corte horizontal de volta (da direita para a esquerda).
P.B_Wind={rightshoulder={3.13,-1.40,-0.12},rightelbow={1.79,0,0},rightwrist={-2.31,0,-1.69},waist={0,-0.45,0}}
P.B_Strike={rightshoulder={1.64,0.67,-0.57},rightelbow={0.91,0,0},rightwrist={-2.17,0,-0.45},waist={0,0.5,0},root={0,0,0,0,-0.12,-0.45},leftknee={-0.25,0,0}}
-- Combo C: estocada (recolhe ao quadril e projeta à frente com avanço).
P.C_Wind={rightshoulder={-1.23,-0.58,0.98},rightelbow={2.36,0,0},rightwrist={-0.52,0,-1.46},waist={0,-0.3,0},root={0,0,0,0,-0.1,0.15}}
P.C_Strike={rightshoulder={1.13,1.14,0.35},rightelbow={0.23,0,0},rightwrist={-1.38,0,-1.41},waist={-0.05,0.25,0},root={0,0,0,0,-0.2,-0.8},leftknee={-0.45,0,0},rightknee={-0.1,0,0}}
-- Égide: escudo em guarda e espada erguida ao céu.
P.Aegis={leftshoulder={1.55,-1.29,1.38},leftelbow={2.18,0,0},rightshoulder={3.05,-1.06,-0.48},rightelbow={0.04,0,0},rightwrist={-1.67,0,-0.52},waist={-0.08,0,0}}

-- Explorador (de lado): mão à aljava (calibrada no topo da aljava), encaixa a flecha atrás da
-- empunhadura do arco, puxa até a bochecha e solta.
P.E_Reach={rightshoulder={0.52,1.48,1.36},rightelbow={2.79,0,0},waist={0,0.1,0}}
P.E_Nock={leftshoulder={1.89,-1.06,1.00},leftelbow={0.31,0,0},rightshoulder={1.06,1.64,-0.69},rightelbow={1.92,0,0}}
P.E_Draw={leftshoulder={1.89,-1.06,1.00},leftelbow={0.31,0,0},rightshoulder={1.50,2.00,-0.93},rightelbow={2.44,0,0}}
P.E_Release={leftshoulder={1.89,-1.06,1.00},leftelbow={0.31,0,0},rightshoulder={0.95,1.50,0.25},rightelbow={2.85,0,0}}

-- Artífice: concentra o cristal junto ao peito e empurra com as duas mãos.
P.F_Charge={rightshoulder={1.00,1.50,-0.50},rightelbow={1.50,0,0},leftshoulder={1.00,-1.25,1.12},leftelbow={2.00,0,0},waist={0.07,0,0}}
P.F_Push={rightshoulder={1.56,0.94,-1.00},rightelbow={0.39,0,0},leftshoulder={1.56,-0.54,1.00},leftelbow={0.29,0,0},waist={-0.14,0,0}}
P.F_Raise={rightshoulder={2.7,0,-0.2},rightelbow={0.25,0,0},leftshoulder={2.7,0,0.2},leftelbow={0.25,0,0},waist={0.18,0,0}}
P.F_Slam={rightshoulder={0.6,0,-0.2},rightelbow={0.3,0,0},leftshoulder={0.6,0,0.2},leftelbow={0.3,0,0},waist={-0.35,0,0},root={0,0,0,0,-0.35,0},leftknee={-0.5,0,0},rightknee={-0.5,0,0}}

local function merged(base: string,extra: Pose): Pose
	local out: Pose={}
	for k,v in P[base] do out[k]=v end
	for k,v in extra do out[k]=v end
	return out
end
-- Durante os golpes o escudo fica pronto (ShieldReady) e as pernas/tronco da guarda servem de base.
for _,name in {"A_Wind","A_Strike","B_Wind","B_Strike","C_Wind","C_Strike"} do
	local own=P[name]
	P[name]=merged("Guard",P.ShieldReady)
	for k,v in own do P[name][k]=v end
end
-- Acompanhamento: segura a pose do golpe um instante antes de recuperar.
P.A_Follow=merged("A_Strike",{waist={-0.1,0.55,0}})
P.B_Follow=merged("B_Strike",{waist={0,0.6,0}})
P.C_Follow=merged("C_Strike",{})

-- Sequências: {instante normalizado, pose}. "Rest" = sem sobreposição.
Motion.Clips={
	Guardian={
		{{0,"Rest"},{0.3,"A_Wind"},{0.5,"A_Strike"},{0.72,"A_Follow"},{1,"Rest"}},
		{{0,"Rest"},{0.3,"B_Wind"},{0.5,"B_Strike"},{0.72,"B_Follow"},{1,"Rest"}},
		{{0,"Rest"},{0.36,"C_Wind"},{0.5,"C_Strike"},{0.72,"C_Follow"},{1,"Rest"}},
	},
	Explorer={{{0,"Rest"},{0.2,"E_Reach"},{0.36,"E_Nock"},{0.7,"E_Draw"},{0.78,"E_Release"},{0.9,"E_Release"},{1,"Rest"}}},
	Artificer={{{0,"Rest"},{0.4,"F_Charge"},{0.52,"F_Push"},{0.75,"F_Push"},{1,"Rest"}}},
	GuardianSkill={{0,"Rest"},{0.25,"Aegis"},{0.78,"Aegis"},{1,"Rest"}},
	ExplorerSkill={{0,"Rest"},{0.15,"E_Reach"},{0.3,"E_Nock"},{0.45,"E_Draw"},{0.5,"E_Release"},{0.8,"E_Release"},{1,"Rest"}},
	ArtificerSkill={{0,"Rest"},{0.35,"F_Raise"},{0.52,"F_Slam"},{0.8,"F_Slam"},{1,"Rest"}},
}

local function ease(x: number): number
	x=math.clamp(x,0,1)
	return x*x*(3-2*x)
end

local zero={0,0,0,0,0,0}
local function jointValues(pose: string,joint: string): {number}
	if pose=="Rest" then return zero end
	local p=P[pose]
	return (p and p[joint]) or zero
end

local function sample(clip: {any},t: number,joint: string): ({number},boolean)
	t=math.clamp(t,0,1)
	local used=false
	for _,key in clip do if key[2]~="Rest" and P[key[2]] and P[key[2]][joint] then used=true break end end
	if not used then return zero,false end
	for i=1,#clip-1 do
		local a,b=clip[i],clip[i+1]
		if t<=b[1] then
			local u=ease((t-a[1])/math.max(b[1]-a[1],0.001))
			local va,vb=jointValues(a[2],joint),jointValues(b[2],joint)
			local out={}
			for k=1,6 do out[k]=(va[k] or 0)+((vb[k] or 0)-(va[k] or 0))*u end
			return out,true
		end
	end
	return jointValues(clip[#clip][2],joint),true
end

local function toCFrame(v: {number}): CFrame
	return CFrame.new(v[4] or 0,v[5] or 0,v[6] or 0)*CFrame.Angles(v[1] or 0,v[2] or 0,v[3] or 0)
end

export type Context={classId: string,attack: number?,combo: number?,skill: number?,dash: number?,dashDir: Vector3?,blocking: number?}

-- Sobreposição de combate para uma articulação, ou nil se nada a mover.
function Motion.overlay(name: string,ctx: Context): CFrame?
	local result: {number}?=nil
	if ctx.skill then
		local clip=Motion.Clips[ctx.classId.."Skill"]
		if clip then local v,ok=sample(clip,ctx.skill,name) if ok then result=v end end
		if ctx.classId=="Explorer" and name=="waist" then
			-- Rajada: inclina o tronco para trás, o arco mira o céu.
			local lean=0.5*ease(ctx.skill/0.2)*(1-ease((ctx.skill-0.8)/0.2))
			result={lean,0,0,0,0,0}
		end
	elseif ctx.attack then
		local clips=Motion.Clips[ctx.classId]
		local clip=clips and clips[((ctx.combo or 1)-1)%#clips+1]
		if clip then local v,ok=sample(clip,ctx.attack,name) if ok then result=v end end
		-- Defesa segurada: depois do golpe volta à guarda, não ao repouso.
		if ctx.blocking and ctx.blocking>0 and ctx.attack>0.72 then
			local g=P.Guard[name]
			if g then
				local back=ease((ctx.attack-0.72)/0.28)
				local base=result or zero
				local out={}
				for k=1,6 do out[k]=(base[k] or 0)+((g[k] or 0)-(base[k] or 0))*back end
				result=out
			end
		end
	elseif ctx.blocking and ctx.blocking>0 then
		local g=P.Guard[name]
		if g then
			local out={}
			for k=1,6 do out[k]=(g[k] or 0)*ctx.blocking end
			result=out
		end
	end
	-- Guardião: a mão do escudo fica sempre alinhada ao antebraço, fechada na alça (sem entrar no escudo).
	if ctx.classId=="Guardian" and name=="leftwrist" and not result then result=P.ShieldWrist end
	if ctx.classId=="Guardian" and name=="rightwrist" and not result then result=P.IdleSwordWrist end
	if ctx.dash then
		-- Esquiva: agacha, inclina o tronco na direção do salto (frente/trás) ou rola para o lado.
		local k=math.sin(math.clamp(ctx.dash,0,1)*math.pi)
		local dir=ctx.dashDir or Vector3.new(0,0,-1)
		local forward=-dir.Z -- +1 frente, −1 trás
		local side=dir.X     -- +1 direita
		local add: {number}?=nil
		if name=="waist" then add={(-0.45*forward)*k,0,(-0.45*side)*k}
		elseif name=="root" then add={0,0,(-0.25*side)*k,0,-0.45*k,0}
		elseif name=="leftknee" or name=="rightknee" then add={-0.7*k,0,0}
		elseif name=="lefthip" or name=="righthip" then add={0.45*k,0,0}
		elseif name=="leftshoulder" then add={0.5*k,0,0.35*k}
		elseif name=="rightshoulder" then add={0.5*k,0,-0.35*k} end
		if add then
			local base=result or {0,0,0,0,0,0}
			local out={}
			for i=1,6 do out[i]=(base[i] or 0)+(add[i] or 0) end
			result=out
		end
	end
	return if result then toCFrame(result) else nil
end

-- Caminhada de contingência (só quando a animação nativa falhou).
function Motion.walk(name: string,phase: number,stride: number,airborne: boolean,time: number): CFrame
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
	return CFrame.new(offset)*CFrame.Angles(x,y,z)
end

-- Compatibilidade com chamadas antigas.
function Motion.pose(name: string,phase: number,stride: number,airborne: boolean,classId: string,attack: number?,time: number,skill: number?,dash: number?): CFrame
	local base=Motion.walk(name,phase,stride,airborne,time)
	local o=Motion.overlay(name,{classId=classId,attack=attack,skill=skill,dash=dash})
	return if o then o else base
end

return Motion
