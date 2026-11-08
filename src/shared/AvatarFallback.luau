--!strict
-- Contingência local somente para conteúdo que o ContentProvider confirmou como falho.
-- Não substitui controles, rig, colisões, identidade ou assets que carregaram.
local Players=game:GetService("Players")
local ContentProvider=game:GetService("ContentProvider")
local RunService=game:GetService("RunService")
local Art=require(script.Parent.Art)
local Classes=require(script.Parent.Config.Classes)
local Motion=require(script.Parent.CharacterMotion)
local Face=require(script.Parent.FacePresentation)
local Fallback={}
local actors: {[Model]: any}={}
local IS_STUDIO=RunService:IsStudio()

local function failed(id: string): boolean
	local ok,status=pcall(function() return ContentProvider:GetAssetFetchStatus(id) end)
	return ok and (status==Enum.AssetFetchStatus.Failure or status==Enum.AssetFetchStatus.TimedOut)
end

local function weldPart(parent: Instance,body: BasePart,name: string,size: Vector3,offset: CFrame,color: Color3,shape: Enum.PartType?)
	local p=Art.part(parent,name,size,body.CFrame*offset,color,Enum.Material.SmoothPlastic,shape)
	p.Anchored=false p.Massless=true
	local weld=Instance.new("WeldConstraint") weld.Part0=body weld.Part1=p weld.Parent=p
	return p
end

local function shell(body: MeshPart,player: Player,connections: {RBXScriptConnection})
	local existing=body:FindFirstChild("PortalFallbackSurface")
	if existing then
		local surface=existing:FindFirstChild("Surface")
		if body.Name=="Head" and surface and surface:IsA("BasePart") and Face.apply(surface,player:GetAttribute("ClassId") or "Guardian") then
			for _,item in existing:GetChildren() do if item:IsA("BasePart") and (item.Name=="Eye" or item.Name=="Glint" or item.Name=="Mouth") then item.Transparency=1 end end
		end
		return
	end
	local m=Instance.new("Model") m.Name="PortalFallbackSurface" m.Parent=body
	local class=Classes[player:GetAttribute("ClassId") or "Guardian"] or Classes.Guardian
	local tint=body.Color
	if tint.R>0.85 and tint.G>0.7 and tint.B<0.3 then tint=Color3.fromRGB(209,176,143) end
	if string.find(body.Name,"Torso") then tint=Color3.fromRGB(43,65,82)
	elseif string.find(body.Name,"Leg") or string.find(body.Name,"Foot") then tint=Color3.fromRGB(52,62,70)
	elseif string.find(body.Name,"Arm") then tint=class.color:Lerp(Color3.fromRGB(40,57,67),0.55) end
	local surface=weldPart(m,body,"Surface",body.Size*Vector3.new(0.9,1,0.9),CFrame.identity,tint,Enum.PartType.Ball)
	if body.Name=="Head" then
		local size=body.Size
		local textured=Face.apply(surface,player:GetAttribute("ClassId") or "Guardian")
		if not textured then
		for _, side in {-1,1} do
			weldPart(m,body,"Eye",Vector3.new(0.09,0.12,0.055),CFrame.new(side*size.X*0.19,size.Y*0.05,-size.Z*0.46),Color3.fromRGB(43,53,61),Enum.PartType.Ball)
			weldPart(m,body,"Glint",Vector3.new(0.035,0.035,0.025),CFrame.new(side*size.X*0.19+0.02,size.Y*0.08,-size.Z*0.49),Color3.new(1,1,1),Enum.PartType.Ball)
		end
		weldPart(m,body,"Mouth",Vector3.new(0.16,0.035,0.04),CFrame.new(0,-size.Y*0.23,-size.Z*0.43),Color3.fromRGB(127,85,73),Enum.PartType.Ball)
		end
		weldPart(m,body,"Hair",size*Vector3.new(0.95,0.65,0.95),CFrame.new(0,size.Y*0.3,size.Z*0.1),Color3.fromRGB(73,58,48),Enum.PartType.Ball)
	end
	local connection: RBXScriptConnection?=nil
	connection=ContentProvider:GetAssetFetchStatusChangedSignal(body.MeshId):Connect(function(status)
		if status==Enum.AssetFetchStatus.Success and m.Parent then m:Destroy() end
		if status==Enum.AssetFetchStatus.Success and connection then connection:Disconnect() end
	end)
	table.insert(connections,connection :: RBXScriptConnection)
end

local function bind(player: Player,character: Model)
	task.spawn(function()
		local humanoid=character:WaitForChild("Humanoid",10)
		if not humanoid or not humanoid:IsA("Humanoid") or not character.Parent then return end
		local actor={player=player,humanoid=humanoid,joints={},animate=false,connections={},phase=0,stride=0,poses={},combat=false}
		actors[character]=actor
		-- O estado de download pode mudar depois do primeiro prazo. Reavaliar também
		-- restaura a apresentação nativa se os assets voltarem a carregar.
		task.wait(if character:GetAttribute("PortalGeneratedRig") then 0.1 else 5)
		local warned=false
		while character.Parent and actors[character]==actor do
			local failedMeshes=0
			-- Avatar padrão escondido aguardando a classe: não criar cascas visíveis por cima.
			local awaiting=character:GetAttribute("AwaitingClass")==true
			for _,item in character:GetChildren() do
				if item:IsA("MeshPart") and failed(item.MeshId) and not awaiting then shell(item,player,actor.connections) failedMeshes+=1 end
			end
			local failedAnimations=0
			local joints={}
			for _,item in character:GetDescendants() do
				if item:IsA("Animation") and failed(item.AnimationId) then failedAnimations+=1 end
				if (item:IsA("Motor6D") or item:IsA("AnimationConstraint")) and item.Name~="BowOrientation" then table.insert(joints,item) end
			end
			actor.joints=joints
			local loaded=false
			local animator=humanoid:FindFirstChildOfClass("Animator")
			if animator then for _,track in animator:GetPlayingAnimationTracks() do if track.Length>0 then loaded=true end end end
			local needsMotion=(failedAnimations>0 or character:GetAttribute("PortalGeneratedRig")==true) and not loaded
			local animate=character:FindFirstChild("Animate")
			if player==Players.LocalPlayer and animate and animate:IsA("LocalScript") then
				if needsMotion and animate.Enabled then actor.disabledAnimate=animate animate.Enabled=false
				elseif not needsMotion and actor.disabledAnimate==animate then animate.Enabled=true actor.disabledAnimate=nil end
			end
			actor.animate=needsMotion
			character:SetAttribute("PortalFallbackActive",failedMeshes>0 or needsMotion)
			if (failedMeshes>0 or needsMotion) and not warned then
				warned=true
				warn("[PortalPerdido][AssetFallback]",player.Name,"malhas indisponíveis="..failedMeshes,"animação de contingência="..tostring(needsMotion))
			end
			task.wait(3)
		end
	end)
end

function Fallback.init()
	local function register(player: Player)
		player.CharacterAdded:Connect(function(character) bind(player,character) end)
		if player.Character then bind(player,player.Character) end
	end
	Players.PlayerAdded:Connect(register)
	for _, player in Players:GetPlayers() do register(player) end
	RunService.PreSimulation:Connect(function(dt)
		local time=os.clock()
		for character,actor in actors do
			if not character.Parent then
				for _, connection in actor.connections do connection:Disconnect() end
				actors[character]=nil continue
			end
			local started=character:GetAttribute("PortalAttackStarted")
			local duration=character:GetAttribute("PortalAttackDuration") or 0.5
			local progress=if typeof(started)=="number" then (time-started)/duration else 2
			local skillStarted=character:GetAttribute("PortalSkillStarted")
			local skillProgress=if typeof(skillStarted)=="number" then (time-skillStarted)/Motion.Timing.Skill.duration else 2
			local skilling=skillProgress>=0 and skillProgress<=1
			local dashStarted=character:GetAttribute("PortalDashStarted")
			local dashProgress=if typeof(dashStarted)=="number" then (time-dashStarted)/Motion.Timing.Dash.duration else 2
			local dashing=dashProgress>=0 and dashProgress<=1
			local kickStarted=character:GetAttribute("PortalKickStarted")
			local kickDuration=character:GetAttribute("PortalKickDuration") or Motion.Timing.Kick.duration
			local kickProgress=if typeof(kickStarted)=="number" then (time-kickStarted)/kickDuration else 2
			local kicking=kickProgress>=0 and kickProgress<=1
			-- Defesa (atributo do jogador, replicado): entra rápido e sai suave.
			local blockingNow=actor.player:GetAttribute("Blocking")==true
			actor.block=(actor.block or 0)+((if blockingNow then 1 else 0)-(actor.block or 0))*(1-math.exp(-dt*(if blockingNow then 16 else 8)))
			-- Agachado (atributo do jogador, replicado): desce rápido e sobe suave.
			local crouchNow=actor.player:GetAttribute("Crouching")==true
			actor.crouch=(actor.crouch or 0)+((if crouchNow then 1 else 0)-(actor.crouch or 0))*(1-math.exp(-dt*(if crouchNow then 14 else 9)))
			local striking=progress>=0 and progress<=1
			-- A habilidade usa o mesmo caminho de "ataque" para travar a mira e sobrepor a parte superior.
			-- Exausto depois de um chefão (prelúdio da visão): entra devagar.
			local exhaustedNow=character:GetAttribute("PortalExhausted")==true
			actor.exhausted=(actor.exhausted or 0)+((if exhaustedNow then 1 else 0)-(actor.exhausted or 0))*(1-math.exp(-dt*(if exhaustedNow then 4 else 6)))
			local attacking=striking or skilling or dashing or kicking or actor.block>0.02 or actor.crouch>0.02 or actor.exhausted>0.02
			local root=character:FindFirstChild("HumanoidRootPart")
			if actor.player==Players.LocalPlayer then
				local aim=character:GetAttribute("PortalAimPosition")
				if (striking or skilling) and root and root:IsA("BasePart") and typeof(aim)=="Vector3" then
					if actor.autoRotateBefore==nil then actor.autoRotateBefore=actor.humanoid.AutoRotate end
					actor.humanoid.AutoRotate=false
					local delta=Vector3.new(aim.X-root.Position.X,0,aim.Z-root.Position.Z)
					if delta.Magnitude>0.1 then
						-- Postura da classe (o arqueiro fica de lado, ombro esquerdo para o alvo).
						local stanceClass=if skilling then character:GetAttribute("PortalSkillClass") else character:GetAttribute("PortalAttackClass")
						local yaw=Motion.StanceYaw[stanceClass or ""] or 0
						local rotation=root.CFrame.Rotation:Lerp(CFrame.lookAt(Vector3.zero,delta)*CFrame.Angles(0,yaw,0),1-math.exp(-dt*20))
						root.CFrame=CFrame.new(root.Position)*rotation
					end
				elseif blockingNow and root and root:IsA("BasePart") then
					-- Defendendo: o escudo acompanha a ameaça mais próxima (o servidor só bloqueia golpes de frente).
					local nearest,best=nil,26
					local enemies=workspace:FindFirstChild("PortalEnemies")
					if enemies then
						for _,enemy in enemies:GetChildren() do
							if enemy:IsA("Model") and (enemy:GetAttribute("Health") or 0)>0 and enemy.PrimaryPart then
								local d=(enemy.PrimaryPart.Position-root.Position).Magnitude
								if d<best then best=d nearest=enemy.PrimaryPart.Position end
							end
						end
					end
					if nearest then
						if actor.autoRotateBefore==nil then actor.autoRotateBefore=actor.humanoid.AutoRotate end
						actor.humanoid.AutoRotate=false
						local delta=Vector3.new(nearest.X-root.Position.X,0,nearest.Z-root.Position.Z)
						if delta.Magnitude>0.1 then
							root.CFrame=CFrame.new(root.Position)*root.CFrame.Rotation:Lerp(CFrame.lookAt(Vector3.zero,delta),1-math.exp(-dt*14))
						end
					elseif actor.autoRotateBefore~=nil then actor.humanoid.AutoRotate=actor.autoRotateBefore actor.autoRotateBefore=nil end
				elseif actor.autoRotateBefore~=nil then actor.humanoid.AutoRotate=actor.autoRotateBefore actor.autoRotateBefore=nil end
			end
			local equipment=character:FindFirstChild("ClassEquipment")
			local mount=equipment and equipment:FindFirstChild("BowGrip")
			local bowJoint=mount and mount:FindFirstChild("BowOrientation")
			if bowJoint and bowJoint:IsA("Motor6D") and bowJoint.Part0 and root and root:IsA("BasePart") then
				bowJoint.Transform=bowJoint.Part0.CFrame.Rotation:Inverse()*root.CFrame.Rotation*CFrame.Angles(0,-math.pi/2,0)
			end
			-- Flecha na mão do arqueiro: aparece ao tirá-la da aljava e some ao soltar.
			local attackClassNow=character:GetAttribute("PortalAttackClass")
			local skillClassNow=character:GetAttribute("PortalSkillClass")
			local holdingArrow=(striking and attackClassNow=="Explorer" and progress>0.18 and progress<Motion.Timing.Explorer.release)
				or (skilling and skillClassNow=="Explorer" and skillProgress>0.13 and skillProgress<0.48)
			local nocked=(striking and progress>0.36 and progress<Motion.Timing.Explorer.release) or (skilling and skillProgress>0.3 and skillProgress<0.48)
			local hand=character:FindFirstChild("RightHand")
			local grip=equipment and equipment:FindFirstChild("BowGrip")
			if holdingArrow and hand and hand:IsA("BasePart") then
				local arrow=actor.handArrow
				if not arrow or not arrow.Parent then
					local folder=workspace:FindFirstChild("PortalClientEffects")
					if folder then
						arrow=Instance.new("Model") arrow.Name="HandArrow"
						local shaft=Art.part(arrow,"Shaft",Vector3.new(0.06,0.06,1.8),CFrame.identity,Color3.fromRGB(171,137,87),Enum.Material.Wood)
						local head=Art.part(arrow,"Head",Vector3.new(0.13,0.13,0.3),CFrame.new(0,0,-1.0),Color3.fromRGB(196,206,216),Enum.Material.Metal,Enum.PartType.Ball)
						local feather=Art.part(arrow,"Fletching",Vector3.new(0.24,0.03,0.4),CFrame.new(0,0,0.75),Color3.fromRGB(231,224,206),Enum.Material.Fabric,Enum.PartType.Ball)
						for _,piece in {shaft,head,feather} do piece.CastShadow=false end
						arrow.PrimaryPart=shaft
						arrow.Parent=folder
						actor.handArrow=arrow
					end
				end
				if arrow and arrow.PrimaryPart then
					-- Encaixada: da mão da corda em direção ao arco. Antes disso: segura pela ponta das penas.
					local nockPoint=hand.Position
					local towards=if nocked and grip and grip:IsA("BasePart") then grip.Position else hand.Position-hand.CFrame.UpVector
					if (towards-nockPoint).Magnitude>0.05 then
						arrow:PivotTo(CFrame.lookAt(nockPoint,towards)*CFrame.new(0,0,-0.75))
					end
				end
			elseif actor.handArrow and actor.handArrow.Parent then
				actor.handArrow:Destroy() actor.handArrow=nil
			end
			if equipment and (attacking or actor.combat) then
				local attackClass=attackClassNow
				local drawing=nocked
				-- Brilho do cristal: cresce enquanto carrega e diminui depois de lançar.
				local charge=if striking and attackClass=="Artificer" then math.clamp(progress/Motion.Timing.Artificer.release,0,1)*(if progress<Motion.Timing.Artificer.release then 1 else math.max(0,1-(progress-Motion.Timing.Artificer.release)*4)) else 0
				if skilling and character:GetAttribute("PortalSkillClass")=="Artificer" then charge=math.max(charge,math.clamp(skillProgress/0.45,0,1)*(if skillProgress<0.55 then 1 else 0)) end
				for _,piece in equipment:GetChildren() do
					if piece:IsA("Beam") and piece.Name=="DrawnString" then piece.Enabled=drawing
					elseif piece:IsA("BasePart") and piece.Name=="BowString" then piece.Transparency=if drawing then 1 else 0
					elseif piece:IsA("BasePart") and piece.Name=="SwordBlade" then
						local trail=piece:FindFirstChildOfClass("Trail")
						if trail then trail.Enabled=striking and attackClass=="Guardian" and progress>0.32 and progress<0.7 end
					elseif piece:IsA("BasePart") and (piece.Name=="RightFistRune" or piece.Name=="LeftFistRune" or piece.Name=="RightDaggerBlade" or piece.Name=="LeftDaggerBlade") then
						-- Rastro dos punhos (Lutador) e das adagas (Véu) só na fase do golpe ou da habilidade.
						local trail=piece:FindFirstChildOfClass("Trail")
						local owner=if piece.Name:find("Fist") then "Brawler" else "Shade"
						if trail then trail.Enabled=(striking and attackClass==owner and progress>0.25 and progress<0.8) or (skilling and character:GetAttribute("PortalSkillClass")==owner and skillProgress>0.15 and skillProgress<0.8) end
					elseif piece:IsA("BasePart") and piece.Name=="FocusShell" then
						local base=piece:GetAttribute("BaseSize")
						if typeof(base)~="Vector3" then base=piece.Size piece:SetAttribute("BaseSize",base) end
						piece.Size=(base :: Vector3)*(1+0.45*charge)
					elseif piece:IsA("BasePart") and piece.Name=="ArcaneFocus" then
						local light=piece:FindFirstChildOfClass("PointLight")
						if light then light.Brightness=1.1+3*charge light.Range=6+6*charge end
					end
				end
			end
			-- Véu velado (Passo do Véu): o corpo fica translúcido enquanto os inimigos o perdem de vista.
			local veiled=(actor.player:GetAttribute("VeiledUntil") or 0)>workspace:GetServerTimeNow() or actor.player:GetAttribute("Eliminated")==true
			if veiled~=(actor.veiled==true) then
				actor.veiled=veiled
				for _,piece in character:GetDescendants() do
					if piece:IsA("BasePart") and piece.Name~="HumanoidRootPart" then piece.LocalTransparencyModifier=if veiled then 0.65 else 0 end
				end
			end
			-- Guardião mantém o laço ativo: a mão do escudo é corrigida também fora do combate.
			local persistent=actor.player:GetAttribute("ClassId")=="Guardian" and character:FindFirstChild("ClassEquipment")~=nil
			if not actor.animate and not attacking and not actor.combat and not persistent then continue end
			local speed=if root and root:IsA("BasePart") then Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude else 0
			local targetStride=math.clamp(speed/16,0,1)
			actor.stride+=(targetStride-actor.stride)*(1-math.exp(-dt*12))
			-- Phase advances with distance travelled rather than wall time: no foot cycling at rest.
			actor.phase+=speed*dt*0.67
			local state=actor.humanoid:GetState()
			local airborne=state==Enum.HumanoidStateType.Freefall or state==Enum.HumanoidStateType.Jumping
			local classId=character:GetAttribute("PortalAttackClass") or actor.player:GetAttribute("ClassId") or "Guardian"
			local skillClass=character:GetAttribute("PortalSkillClass") or classId
			local ctx={
				classId=if skilling then skillClass else classId,
				attack=if striking then progress else nil,
				combo=character:GetAttribute("PortalCombo") or 1,
				skill=if skilling then skillProgress else nil,
				dash=if dashing then dashProgress else nil,
				kick=if kicking then kickProgress else nil,
				kickVariant=character:GetAttribute("PortalKickVariant"),
				crouch=if actor.crouch>0.02 then actor.crouch else nil,
				exhausted=if actor.exhausted>0.02 then actor.exhausted else nil,
				dashDir=character:GetAttribute("PortalDashDir"),
				blocking=if actor.block>0.02 then actor.block else nil,
			}
			for _,joint in actor.joints do
				if not joint.Parent then continue end
				local name=joint.Name:gsub(" ",""):lower()
				local overlay=Motion.overlay(name,ctx)
				-- Calibração no Studio: atributo "PoseOverride_<articulação>" (CFrame) substitui a pose.
				if IS_STUDIO then
					local override=character:GetAttribute("PoseOverride_"..name)
					if typeof(override)=="CFrame" then overlay=override end
				end
				local previous=actor.poses[joint] or CFrame.identity
				local pose=previous:Lerp(overlay or CFrame.identity,1-math.exp(-dt*22))
				actor.poses[joint]=pose
				if actor.animate then
					-- Sem animação nativa: caminhada própria; o combate substitui braços e tronco.
					local upper=name:find("shoulder") or name:find("elbow") or name:find("wrist") or name=="waist"
					local walk=Motion.walk(name,actor.phase,actor.stride,airborne,time)
					joint.Transform=if overlay and upper then pose else walk*pose
				else
					-- Com animação nativa: o combate é somado sobre ela (inclui avanço e joelhos).
					joint.Transform=joint.Transform*pose
				end
			end
			if attacking then actor.lastActive=time end
			actor.combat=attacking or (time-(actor.lastActive or 0)<0.45)

		end
	end)
end

return Fallback
