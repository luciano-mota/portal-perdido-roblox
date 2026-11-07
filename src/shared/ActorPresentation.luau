--!strict
-- Movimento visual local dos atores originais. Não modifica hitboxes, HP ou IA.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Presentation={}
local actors: {[Model]: any}={}

local function register(model: Model)
	if actors[model] or not model.PrimaryPart then return end
	local kind=model:GetAttribute("EnemyKind") or model:GetAttribute("PresentationKind")
	if typeof(kind)~="string" then return end
	local joints={}
	local eyes={}
	for _,item in model:GetDescendants() do
		if item:IsA("Motor6D") or item:IsA("AnimationConstraint") then table.insert(joints,item) end
		if kind=="Ilyra" and item:IsA("BasePart") and (item.Name=="Eye" or item.Name=="Iris" or item.Name=="Pupil") then table.insert(eyes,item) end
	end
	local height=math.max(model:GetExtentsSize().Y,2)
	actors[model]={root=model.PrimaryPart,kind=kind,joints=joints,eyes=eyes,last=model.PrimaryPart.Position,phase=0,stride=0,
		height=height,hp=model:GetAttribute("Health"),hitAt=-math.huge,deadAt=nil,seed=(#joints*0.37+height)%6.28}
end

local function ease(x: number): number
	x=math.clamp(x,0,1)
	return x*x*(3-2*x)
end

-- Pose de criatura. Convenções (Motor6D com C0 alinhado ao mundo, frente −Z):
-- X+ no ombro leva o braço à frente/para cima; X+ na cintura inclina o tronco para trás.
local function creaturePose(actor: any,name: string,now: number,ctx: any): CFrame
	local kind=actor.kind
	local side=if name:find("Left") then -1 else 1
	local h=actor.height
	local phase,stride=actor.phase,actor.stride
	local wind,impact,flinch,death,yaw=ctx.wind,ctx.impact,ctx.flinch,ctx.death,ctx.yaw
	local breathe=math.sin(now*1.6+actor.seed)
	if death>0 then
		-- Queda: tronco tomba para a frente e afunda; membros relaxam.
		if name=="Waist" or name=="SpiritCore" then
			return CFrame.new(0,-0.22*h*death,0.05*h*death)*CFrame.Angles(-0.9*death,0,0.25*death*side)
		elseif name:find("Shoulder") then return CFrame.Angles(-0.4*death,0,side*0.5*death)
		elseif name:find("Hip") then return CFrame.Angles(0.5*death*side,0,0)
		elseif name=="Neck" then return CFrame.Angles(-0.5*death,0,0) end
		return CFrame.identity
	end
	if name=="Waist" then
		-- Andar: sobe e desce a cada passo, rola e gira levemente; parado, respira.
		local bob=-math.abs(math.sin(phase))*0.035*h*stride+breathe*0.008*h*(1-stride)
		local x=breathe*0.02*(1-stride)-0.06*stride
		local ry=math.sin(phase)*0.07*stride
		local rz=math.sin(phase)*0.05*stride
		if kind=="Thorn" then
			-- Agacha na preparação e dá o bote no impacto.
			bob+=-0.12*h*wind+0.06*h*impact
			x+=-0.12*wind+0.25*impact
			return CFrame.new(0,bob,-0.18*h*impact)*CFrame.Angles(x-0.1*flinch,ry,rz)
		end
		-- Moss/Boss: inclina para trás ao erguer os braços e golpeia para a frente.
		if ctx.castKind=="VineGrab" then
			-- Projeta o tronco para a frente acompanhando o braço.
			local extend=math.max(wind,if ctx.reaching then 1 else 0)
			return CFrame.new(0,bob,0)*CFrame.Angles(x-0.12*extend,ry-0.2*extend,rz)
		end
		-- Raízes: ergue os braços e golpeia o chão, curvando o tronco.
		x+=0.22*wind-0.45*impact+0.18*flinch
		bob+=-0.05*h*impact
		return CFrame.new(0,bob,0)*CFrame.Angles(x,ry,rz)
	elseif name=="SpiritCore" then
		-- Eco: flutua, oscila e sobe ao conjurar; recua ao ser atingido.
		local lift=math.sin(now*2+actor.seed)*0.04*h+0.08*h*wind
		return CFrame.new(0,lift,0.06*h*flinch)*CFrame.Angles(0.25*wind-0.2*impact+0.25*flinch,math.sin(now*0.8)*0.15,math.sin(now*1.3)*0.05)
	elseif name:find("Hip") then
		local rear=if name:find("Rear") then -1 else 1
		local swing=math.sin(phase)*stride*side*rear*0.5
		-- Predador: patas dianteiras avançam e traseiras recolhem ao se preparar para o bote.
		if kind=="Thorn" then
			if ctx.castKind=="Claw" and side>0 and rear>0 then
				-- Garras: ergue a pata dianteira direita e desfere o golpe para baixo.
				return CFrame.Angles(swing-1.1*wind+1.6*impact,0,-0.25*wind)
			end
			swing+=(if rear<0 then -0.25 else 0.2)*wind
		end
		return CFrame.Angles(swing,0,0)
	elseif name:find("Shoulder") then
		local walk=-math.sin(phase)*stride*side*0.35
		local x=walk-0.04+breathe*0.03
		if kind=="Wisp" then x=0.15+1.35*wind-0.6*impact+breathe*0.06
		elseif ctx.castKind=="VineGrab" then
			-- Vinha: o braço direito aponta para o alvo e fica estendido enquanto a raiz voa; o esquerdo recua.
			local extend=math.max(wind,if ctx.reaching then 1 else 0)
			if side>0 then return CFrame.Angles(x*(1-extend)+1.55*extend,0,0.05) end
			x=x*(1-extend)-0.35*extend
		else x=x*(1-wind)+2.4*wind-1.7*impact end
		return CFrame.Angles(x,0,side*(0.04+0.18*wind))
	elseif name=="Neck" then
		-- Olha para o jogador próximo; abaixa a cabeça no golpe.
		local nod=breathe*0.03
		if kind=="Thorn" then nod+=-0.15*wind-0.3*impact end
		return CFrame.Angles(nod-0.1*wind+0.2*flinch,yaw,0)
	end
	return CFrame.identity
end

function Presentation.init()
	local elapsed=1
	RunService.PreSimulation:Connect(function(dt)
		elapsed+=dt
		if elapsed>=1 then
			elapsed=0
			local folder=workspace:FindFirstChild("PortalEnemies")
			if folder then for _,model in folder:GetChildren() do if model:IsA("Model") then register(model) end end end
			local world=workspace:FindFirstChild("PortalChapter")
			local village=world and world:FindFirstChild("Village")
			local npc=village and village:FindFirstChild("Ilyra")
			if npc and npc:IsA("Model") then register(npc) end
		end
		local character=Players.LocalPlayer.Character
		local playerRoot=character and character:FindFirstChild("HumanoidRootPart")
		local now=workspace:GetServerTimeNow()
		for model,actor in actors do
			local root=actor.root :: BasePart
			if not model.Parent or not root.Parent then actors[model]=nil continue end
			local distance=(root.Position-actor.last).Magnitude
			actor.last=root.Position
			if not playerRoot or not playerRoot:IsA("BasePart") or (root.Position-playerRoot.Position).Magnitude>150 then continue end
			local dead=(model:GetAttribute("Health") or 1)<=0
			local stride=if dead then 0 else math.clamp(distance/math.max(dt,0.001)/7,0,1)
			actor.stride+=(stride-actor.stride)*(1-math.exp(-dt*10))
			if distance<10 then actor.phase+=distance*(if actor.kind=="Boss" then 0.38 elseif actor.kind=="Thorn" then 1.25 else 0.85) end
			local castEnd=model:GetAttribute("CastEndsAt") or 0
			local castStart=model:GetAttribute("CastStartedAt") or 0
			local casting=not dead and castEnd>now
			local wind=if casting then math.clamp((now-castStart)/math.max(castEnd-castStart,0.1),0,1) else 0
			local impact=not dead and (model:GetAttribute("ImpactUntil") or 0)>now
			local talking=(model:GetAttribute("TalkingUntil") or 0)>now
			-- Estado extra para criaturas: impacto suavizado, recuo ao levar dano, queda e mira da cabeça.
			local hp=model:GetAttribute("Health")
			if typeof(hp)=="number" and typeof(actor.hp)=="number" and hp<actor.hp then actor.hitAt=os.clock() end
			actor.hp=hp
			if dead and not actor.deadAt then actor.deadAt=os.clock() elseif not dead then actor.deadAt=nil end
			actor.impactBlend=(actor.impactBlend or 0)+((if impact then 1 else 0)-(actor.impactBlend or 0))*(1-math.exp(-dt*(if impact then 30 else 6)))
			local relative=root.CFrame:VectorToObjectSpace(playerRoot.Position-root.Position)
			local yawTarget=if relative.Magnitude<45 and relative.Z<0 then math.clamp(math.atan2(-relative.X,-relative.Z),-0.6,0.6) else 0
			local ctx={wind=ease(wind),impact=actor.impactBlend,flinch=1-ease((os.clock()-actor.hitAt)/0.28),
				death=if actor.deadAt then ease((os.clock()-actor.deadAt)/0.55) else 0,yaw=yawTarget,
				castKind=model:GetAttribute("CastKind"),reaching=(model:GetAttribute("ReachUntil") or 0)>now}
			for _,joint in actor.joints do
				if not joint.Parent then continue end
				local name=joint.Name
				local pose=CFrame.identity
				if actor.kind~="Ilyra" then
					pose=creaturePose(actor,name,now,ctx)
				else
					do
						if name=="Neck" then
							local relative=root.CFrame:VectorToObjectSpace(playerRoot.Position-root.Position)
							local yaw=if relative.Z<0 and relative.Magnitude<24 then math.clamp(math.atan2(-relative.X,-relative.Z),-0.32,0.32) else 0
							pose=CFrame.Angles(math.sin(now*(if talking then 2.1 else 1.1))*0.035,yaw,0)
						elseif name=="LeftShoulder" then pose=CFrame.Angles(-0.06-(if talking then 0.22+math.sin(now*1.8)*0.11 else math.sin(now*1.3)*0.025),0,-0.04)
						elseif name=="RightShoulder" then pose=CFrame.Angles(math.sin(now*1.3)*0.015,0,0) end
						if model:GetAttribute("GeneratedNPC") then
							-- Rig gerado vem em A-pose: Z positivo no ombro esquerdo (negativo no direito) baixa o braço.
							-- Validado no Play de 03/11/2026: 1,12 rad deixa os braços ao lado do corpo.
							local breathe=math.sin(now*1.3)*0.02
							if name=="LeftShoulder" then pose=CFrame.Angles(if talking then 0.3+math.sin(now*1.8)*0.08 else 0.04+breathe,0,1.12)
							elseif name=="RightShoulder" then pose=CFrame.Angles(if talking then 0.12 else 0.03-breathe,0,-1.12)
							elseif name=="LeftElbow" then pose=CFrame.Angles(if talking then 0.75+math.sin(now*1.8)*0.15 else 0.22,0,0)
							elseif name=="RightElbow" then pose=CFrame.Angles(if talking then 0.4 else 0.18,0,0) end
						end
					end
				end
				joint.Transform=joint.Transform:Lerp(pose,1-math.exp(-dt*16))
			end
			if actor.kind=="Ilyra" then
				local blink=now%5.3<0.12
				for _,eye in actor.eyes do if eye.Parent then eye.LocalTransparencyModifier=if blink then 1 else 0 end end
			end
		end
	end)
end

return Presentation
