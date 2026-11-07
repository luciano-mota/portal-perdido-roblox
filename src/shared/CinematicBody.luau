--!strict
-- Pose por articulação para clones ESTÁTICOS (ancorados) dos rigs R15 usados nas cenas do prólogo.
-- Não usa Humanoid nem animações: guarda a pose de descanso de cada peça no espaço do quadril
-- (LowerTorso; -Z = frente, +X = direita do personagem) e recompõe a cadeia de articulações
-- pelos RigAttachments. A cada pose o corpo é apoiado no chão pelo ponto visível mais baixo.
--
-- Ângulos em graus, no espaço do corpo:
--   X+ em membro pendente leva-o para a frente; X+ no tronco/cabeça inclina para trás (olhar para cima).
--   Z+ leva membro pendente para a direita (+X); Y+ gira para a esquerda (cabeça olhando à esquerda).
--   "Root" gira o corpo inteiro pelo quadril (Root X=90: deitado de costas).
local Body={}
Body.__index=Body

export type Pose={[string]: Vector3}

local JOINTS={
	{"UpperTorso","LowerTorso","WaistRigAttachment"},
	{"Head","UpperTorso","NeckRigAttachment"},
	{"LeftUpperArm","UpperTorso","LeftShoulderRigAttachment"},
	{"LeftLowerArm","LeftUpperArm","LeftElbowRigAttachment"},
	{"LeftHand","LeftLowerArm","LeftWristRigAttachment"},
	{"RightUpperArm","UpperTorso","RightShoulderRigAttachment"},
	{"RightLowerArm","RightUpperArm","RightElbowRigAttachment"},
	{"RightHand","RightLowerArm","RightWristRigAttachment"},
	{"LeftUpperLeg","LowerTorso","LeftHipRigAttachment"},
	{"LeftLowerLeg","LeftUpperLeg","LeftKneeRigAttachment"},
	{"LeftFoot","LeftLowerLeg","LeftAnkleRigAttachment"},
	{"RightUpperLeg","LowerTorso","RightHipRigAttachment"},
	{"RightLowerLeg","RightUpperLeg","RightKneeRigAttachment"},
	{"RightFoot","RightLowerLeg","RightAnkleRigAttachment"},
}
local ZERO=Vector3.zero

export type Body=typeof(setmetatable({}::{
	parts: {BasePart}, rest: {CFrame}, owner: {string}, support: {boolean},
	pivots: {[string]: Vector3}, cframes: {CFrame},
},Body))

local HAND_CHAIN={LeftLowerArm=true,LeftHand=true,RightLowerArm=true,RightHand=true}

-- handsFree: peças soldadas a antebraço/mão (arma, escudo, foco) passam a seguir o quadril,
-- penduradas ao lado do corpo, e as mãos ficam livres para gestos.
function Body.new(model: Model, handsFree: boolean?): Body?
	local hips=model:FindFirstChild("LowerTorso")
	if not hips or not hips:IsA("BasePart") then return nil end
	local ref=hips.CFrame
	local jointParts: {[string]: BasePart}={LowerTorso=hips}
	local pivots: {[string]: Vector3}={}
	for _,joint in JOINTS do
		local part=model:FindFirstChild(joint[1])
		if not part or not part:IsA("BasePart") then return nil end
		jointParts[joint[1]]=part
		local attachment=part:FindFirstChild(joint[3])
		pivots[joint[1]]=ref:PointToObjectSpace(if attachment and attachment:IsA("Attachment") then attachment.WorldPosition else part.Position)
	end
	local byPart: {[BasePart]: string}={}
	for name,part in jointParts do byPart[part]=name end
	local welded: {[BasePart]: string}={}
	for _,weld in model:GetDescendants() do
		if weld:IsA("WeldConstraint") and weld.Part0 and weld.Part1 then
			local name=byPart[weld.Part0]
			if name and handsFree and HAND_CHAIN[name] then name="LowerTorso" end
			if name then welded[weld.Part1]=name end
		end
	end
	local self=setmetatable({parts={},rest={},owner={},support={},pivots=pivots,cframes={}},Body)
	for _,part in model:GetDescendants() do
		if part:IsA("BasePart") then
			-- Gola/capuz/rosto rígidos do avatar acompanham a cabeça.
			local owner=byPart[part] or welded[part] or (if part.Name:sub(1,9)=="RBX_RIGID" then "Head" else nil)
			if not owner then
				-- Peças sem solda (gola/rosto rígidos, raiz): seguem a articulação mais próxima.
				local best=math.huge
				for name,joint in jointParts do
					local distance=(joint.Position-part.Position).Magnitude
					if distance<best then best=distance owner=name end
				end
			end
			table.insert(self.parts,part)
			table.insert(self.rest,ref:ToObjectSpace(part.CFrame))
			table.insert(self.owner,owner or "LowerTorso")
			-- Equipamento e peças invisíveis não definem o apoio no chão.
			table.insert(self.support,part.Transparency<1 and not part:FindFirstAncestor("ClassEquipment"))
		end
	end
	return self
end

-- Gira as peças indicadas (e o que estiver soldado a elas) por uma rotação em torno de um ponto.
local function turn(model: Model, names: {string}, pivot: Vector3, rotation: CFrame)
	local moving: {[BasePart]: boolean}={}
	for _,name in names do
		local part=model:FindFirstChild(name)
		if part and part:IsA("BasePart") then moving[part]=true end
	end
	for _,weld in model:GetDescendants() do
		if weld:IsA("WeldConstraint") and weld.Part0 and moving[weld.Part0] and weld.Part1 then moving[weld.Part1]=true end
	end
	local around=CFrame.new(pivot)*rotation*CFrame.new(-pivot)
	for part in moving do part.CFrame=around*part.CFrame end
end

-- Rotação mínima que leva a direção a até a direção b.
local function arc(a: Vector3, b: Vector3): CFrame
	local axis=a:Cross(b)
	if axis.Magnitude<1e-4 then return CFrame.identity end
	return CFrame.fromAxisAngle(axis.Unit,math.acos(math.clamp(a.Unit:Dot(b.Unit),-1,1)))
end

-- O rig de retrato fica em pose A, e cada rig tem o antebraço inclinado de um jeito. Deixa os dois
-- braços retos, pendentes ~10° para fora, iguais nos três rigs, para que os mesmos ângulos de pose
-- sirvam a todos. Leva junto peças soldadas (arma, escudo). Chamar antes de Body.new.
function Body.relaxArms(model: Model)
	local torso=model:FindFirstChild("UpperTorso")
	if not torso or not torso:IsA("BasePart") then return end
	for _,side in {"Left","Right"} do
		local upper=model:FindFirstChild(side.."UpperArm")
		local lower=model:FindFirstChild(side.."LowerArm")
		local shoulder=upper and upper:FindFirstChild(side.."ShoulderRigAttachment")
		local elbow=upper and upper:FindFirstChild(side.."ElbowRigAttachment")
		local wrist=lower and lower:FindFirstChild(side.."WristRigAttachment")
		if not (shoulder and elbow and wrist and shoulder:IsA("Attachment") and elbow:IsA("Attachment") and wrist:IsA("Attachment")) then continue end
		local sign=if side=="Left" then -1 else 1
		local hang=torso.CFrame:VectorToWorldSpace(Vector3.new(sign*math.sin(math.rad(10)),-math.cos(math.rad(10)),0))
		turn(model,{side.."UpperArm",side.."LowerArm",side.."Hand"},shoulder.WorldPosition,arc(elbow.WorldPosition-shoulder.WorldPosition,hang))
		turn(model,{side.."LowerArm",side.."Hand"},elbow.WorldPosition,arc(wrist.WorldPosition-elbow.WorldPosition,hang))
	end
end

local function rotation(degrees: Vector3): CFrame
	return CFrame.fromEulerAnglesXYZ(math.rad(degrees.X),math.rad(degrees.Y),math.rad(degrees.Z))
end

-- place: posição do quadril em XZ + rumo (só rotação em Y). ground: Y do chão sob o corpo.
function Body.apply(self: Body, pose: Pose, place: CFrame, ground: number)
	local transforms: {[string]: CFrame}={LowerTorso=rotation(pose.Root or ZERO)}
	for _,joint in JOINTS do
		local pivot=self.pivots[joint[1]]
		transforms[joint[1]]=transforms[joint[2]]*CFrame.new(pivot)*rotation(pose[joint[1]] or ZERO)*CFrame.new(-pivot)
	end
	local lowest=math.huge
	for i,part in self.parts do
		local cf=place*transforms[self.owner[i]]*self.rest[i]
		self.cframes[i]=cf
		if self.support[i] then
			local half=part.Size*0.5
			local bottom=cf.Y-(math.abs(cf.XVector.Y)*half.X+math.abs(cf.YVector.Y)*half.Y+math.abs(cf.ZVector.Y)*half.Z)
			if bottom<lowest then lowest=bottom end
		end
	end
	local shift=CFrame.new(0,ground-lowest,0)
	for i,cf in self.cframes do self.cframes[i]=shift*cf end
	workspace:BulkMoveTo(self.parts,self.cframes,Enum.BulkMoveMode.FireCFrameChanged)
end

-- Mistura duas poses (t entre 0 e 1); articulações ausentes valem zero.
function Body.blend(a: Pose, b: Pose, t: number): Pose
	local result: Pose={}
	for key,value in a do result[key]=value:Lerp(b[key] or ZERO,t) end
	for key,value in b do if a[key]==nil then result[key]=ZERO:Lerp(value,t) end end
	return result
end

-- Soma deslocamentos a uma pose (gestos e respiração por cima da pose base).
function Body.add(base: Pose, extra: Pose): Pose
	local result: Pose=table.clone(base)
	for key,value in extra do result[key]=(result[key] or ZERO)+value end
	return result
end

return Body
