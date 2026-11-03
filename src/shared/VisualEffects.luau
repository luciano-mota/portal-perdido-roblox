--!strict
-- Apresentação local limitada; dano e áreas de impacto pertencem ao servidor.
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Art=require(script.Parent.Art)
local Motion=require(script.Parent.CharacterMotion)
local FX={}
local container: Folder

-- Projétil local que segue um arco simples e se orienta pela tangente.
local function fly(p: BasePart,origin: Vector3,target: Vector3,duration: number,arc: number,onArrive: (() -> ())?)
	local started=os.clock()
	local connection: RBXScriptConnection?=nil
	connection=RunService.RenderStepped:Connect(function()
		local t=math.clamp((os.clock()-started)/duration,0,1)
		local pos=origin:Lerp(target,t)+Vector3.new(0,math.sin(t*math.pi)*arc,0)
		local nextPos=origin:Lerp(target,math.min(t+0.02,1))+Vector3.new(0,math.sin(math.min(t+0.02,1)*math.pi)*arc,0)
		if (nextPos-pos).Magnitude>0.001 then p.CFrame=CFrame.lookAt(pos,nextPos) else p.CFrame=CFrame.new(pos) end
		if t>=1 or not p.Parent then
			if connection then connection:Disconnect() end
			if p.Parent then p:Destroy() end
			if onArrive then onArrive() end
		end
	end)
end

local function arrow(origin: Vector3,target: Vector3,duration: number,arc: number,onArrive: (() -> ())?)
	-- Haste com ponta e penas (ao longo de −Z, que o CFrame.lookAt aponta para o alvo) e rastro claro.
	local shaft=Art.part(container,"ArrowFlight",Vector3.new(0.07,0.07,1.9),CFrame.lookAt(origin,target),Color3.fromRGB(171,137,87),Enum.Material.Wood)
	shaft.CastShadow=false
	local head=Art.part(shaft,"ArrowHead",Vector3.new(0.14,0.14,0.32),shaft.CFrame*CFrame.new(0,0,-1.05),Color3.fromRGB(196,206,216),Enum.Material.Metal,Enum.PartType.Ball)
	local feather=Art.part(shaft,"Fletching",Vector3.new(0.26,0.03,0.42),shaft.CFrame*CFrame.new(0,0,0.8),Color3.fromRGB(231,224,206),Enum.Material.Fabric,Enum.PartType.Ball)
	for _,piece in {head,feather} do piece.Anchored=false piece.CastShadow=false local w=Instance.new("WeldConstraint") w.Part0=shaft w.Part1=piece w.Parent=piece end
	local a0=Instance.new("Attachment") a0.Position=Vector3.new(0,0.04,0.9) a0.Parent=shaft
	local a1=Instance.new("Attachment") a1.Position=Vector3.new(0,-0.04,0.9) a1.Parent=shaft
	local trail=Instance.new("Trail") trail.Attachment0=a0 trail.Attachment1=a1 trail.Lifetime=0.12 trail.LightEmission=0.6
	trail.Transparency=NumberSequence.new(0.35,1) trail.Parent=shaft
	fly(shaft,origin,target,duration,arc,onArrive)
end

local function burst(position: Vector3,color: Color3,size: number,duration: number)
	local orb=Art.part(container,"Effect",Vector3.new(size,size,size),CFrame.new(position),color,Enum.Material.Neon,Enum.PartType.Ball)
	orb.CastShadow=false
	Debris:AddItem(orb,duration+0.1)
	TweenService:Create(orb,TweenInfo.new(duration),{Size=Vector3.new(size*3,size*3,size*3),Transparency=1}):Play()
end

-- Clarão de luz no foco arcano: núcleo branco, halo colorido, raios e luz forte que se apaga.
local function flash(position: Vector3,color: Color3,scale: number)
	local core=Art.part(container,"ArcaneFlash",Vector3.new(0.4,0.4,0.4)*scale,CFrame.new(position),Color3.fromRGB(255,252,245),Enum.Material.Neon,Enum.PartType.Ball)
	core.CastShadow=false
	local halo=Art.part(container,"ArcaneHalo",Vector3.new(0.8,0.8,0.8)*scale,CFrame.new(position),color,Enum.Material.Neon,Enum.PartType.Ball)
	halo.CastShadow=false halo.Transparency=0.35
	local light=Instance.new("PointLight") light.Color=color light.Range=14*scale light.Brightness=5 light.Shadows=false light.Parent=core
	TweenService:Create(core,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(1.6,1.6,1.6)*scale,Transparency=1}):Play()
	TweenService:Create(halo,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(3.4,3.4,3.4)*scale,Transparency=1}):Play()
	TweenService:Create(light,TweenInfo.new(0.32),{Brightness=0,Range=4}):Play()
	for i=1,8 do
		local direction=CFrame.Angles(0,i*math.pi/4,(i%2)*0.6-0.3)
		local ray=Art.part(container,"ArcaneRay",Vector3.new(0.06,0.06,1.2*scale),CFrame.new(position)*direction*CFrame.new(0,0,-0.6*scale),Color3.fromRGB(255,245,255),Enum.Material.Neon)
		ray.CastShadow=false ray.Transparency=0.15
		TweenService:Create(ray,TweenInfo.new(0.22),{Size=Vector3.new(0.02,0.02,2.6*scale),CFrame=CFrame.new(position)*direction*CFrame.new(0,0,-1.5*scale),Transparency=1}):Play()
		Debris:AddItem(ray,0.3)
	end
	Debris:AddItem(core,0.4) Debris:AddItem(halo,0.4)
end

local function equipmentPart(character: Model?,name: string): BasePart?
	local equipment=character and character:FindFirstChild("ClassEquipment")
	local piece=equipment and equipment:FindFirstChild(name)
	return if piece and piece:IsA("BasePart") then piece else nil
end

local function part(position: Vector3,color: Color3,size: Vector3,shape: Enum.PartType?,duration: number)
	local p=Art.part(container,"Effect",size,CFrame.new(position),color,Enum.Material.Neon,shape)
	p.CastShadow=false
	Debris:AddItem(p,duration)
	return p
end

local function ring(position: Vector3,radius: number,color: Color3,duration: number,warning: boolean?,alpha: number?)
	local p=part(position,color,Vector3.new(0.08,radius*2,radius*2),Enum.PartType.Cylinder,duration+0.2)
	p.CFrame=CFrame.new(position)*CFrame.Angles(0,0,math.pi/2)
	p.Transparency=if warning then 0.7 else (alpha or 0.4)
	if warning then
		local label=Instance.new("BillboardGui") label.Size=UDim2.fromOffset(140,30) label.StudsOffset=Vector3.new(0,2,0) label.AlwaysOnTop=true label.MaxDistance=100 label.Parent=p
		local text=Instance.new("TextLabel") text.Size=UDim2.fromScale(1,1) text.BackgroundTransparency=1 text.Text="SAIA DA ÁREA" text.TextColor3=Color3.new(1,1,1) text.TextStrokeTransparency=0.15 text.Font=Enum.Font.GothamBold text.TextSize=14 text.Parent=label
		TweenService:Create(p,TweenInfo.new(duration),{Transparency=0.25}):Play()
	else TweenService:Create(p,TweenInfo.new(duration),{Size=Vector3.new(0.05,radius*2.5,radius*2.5),Transparency=1}):Play() end
end

function FX.init()
	container=Instance.new("Folder") container.Name="PortalClientEffects" container.Parent=workspace
end

function FX.play(data: any)
	local character=Players.LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or not data.position or (root.Position-data.position).Magnitude>180 then return end
	if data.kind=="telegraph" then
		ring(data.position,data.radius,Color3.fromRGB(233,109,73),data.duration,true) return
	end
	-- Gestos não dependem do orçamento de partículas decorativas.
	if data.kind=="strike" then
		local actor=typeof(data.userId)=="number" and Players:GetPlayerByUserId(data.userId)
		local timing=Motion.Timing[data.classId] or Motion.Timing.Guardian
		if actor and actor.Character then
			-- Combo do Guardião: golpes seguidos (até 1,3 s) alternam diagonal, horizontal e estocada.
			local last=actor.Character:GetAttribute("PortalAttackStarted")
			local combo=actor.Character:GetAttribute("PortalCombo") or 1
			combo=if typeof(last)=="number" and os.clock()-last<1.3 then combo%3+1 else 1
			actor.Character:SetAttribute("PortalCombo",combo)
			actor.Character:SetAttribute("PortalAimPosition",data.position)
			actor.Character:SetAttribute("PortalAttackStarted",os.clock())
			actor.Character:SetAttribute("PortalAttackClass",data.classId)
			actor.Character:SetAttribute("PortalAttackDuration",timing.duration)
		end
		if #container:GetChildren()>60 then return end
		-- O efeito sai no instante em que a pose solta (corte, corda ou empurrão).
		task.delay(timing.duration*timing.release,function()
			if not container.Parent or #container:GetChildren()>60 then return end
			local model=actor and actor.Character
			if data.classId=="Guardian" then
				ring(data.position-Vector3.new(0,2.5,0),3,data.color,0.22)
				burst(data.position,Color3.fromRGB(235,245,255),0.8,0.18)
			elseif data.classId=="Explorer" then
				local grip=equipmentPart(model,"BowGrip")
				local origin=if grip then grip.Position else data.origin
				local distance=(data.position-origin).Magnitude
				if distance<0.5 then return end
				arrow(origin,data.position,math.clamp(distance/120,0.08,0.5),math.min(distance*0.04,2.2),function() burst(data.position,Color3.fromRGB(255,230,170),0.4,0.15) end)
			else
				local focus=equipmentPart(model,"ArcaneFocus")
				local origin=if focus then focus.Position else data.origin
				flash(origin,data.color,1)
				local distance=(data.position-origin).Magnitude
				if distance<0.5 then return end
				local orb=Art.part(container,"ArcaneBolt",Vector3.new(0.75,0.75,0.75),CFrame.new(origin),data.color,Enum.Material.Neon,Enum.PartType.Ball)
				orb.CastShadow=false
				local light=Instance.new("PointLight") light.Color=data.color light.Range=10 light.Brightness=2 light.Parent=orb
				local a0=Instance.new("Attachment") a0.Position=Vector3.new(0,0.3,0) a0.Parent=orb
				local a1=Instance.new("Attachment") a1.Position=Vector3.new(0,-0.3,0) a1.Parent=orb
				local trail=Instance.new("Trail") trail.Attachment0=a0 trail.Attachment1=a1 trail.Lifetime=0.2 trail.LightEmission=1 trail.Color=ColorSequence.new(data.color) trail.Transparency=NumberSequence.new(0.2,1) trail.FaceCamera=true trail.Parent=orb
				fly(orb,origin,data.position,math.clamp(distance/90,0.1,0.5),0.4,function()
					burst(data.position,data.color,1.2,0.3)
					ring(data.position-Vector3.new(0,2.5,0),3.5,data.color,0.3)
				end)
			end
		end)
	elseif data.kind=="skillCast" then
		local actor=typeof(data.userId)=="number" and Players:GetPlayerByUserId(data.userId)
		local model=actor and actor.Character
		local duration=Motion.Timing.Skill.duration
		if model then
			model:SetAttribute("PortalSkillStarted",os.clock())
			model:SetAttribute("PortalSkillClass",data.classId)
			local first=data.targets and data.targets[1]
			if typeof(first)=="Vector3" then model:SetAttribute("PortalAimPosition",first) end
		end
		if #container:GetChildren()>60 then return end
		if data.classId=="Guardian" then
			task.delay(duration*0.25,function()
				if not container.Parent then return end
				-- Cúpula translúcida da Égide no alcance real (22 studs).
				local dome=Art.part(container,"AegisDome",Vector3.new(4,4,4),CFrame.new(data.position),data.color,Enum.Material.ForceField,Enum.PartType.Ball)
				dome.CastShadow=false dome.Transparency=0.2
				Debris:AddItem(dome,1.1)
				TweenService:Create(dome,TweenInfo.new(0.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(data.radius*2,data.radius*1.2,data.radius*2)}):Play()
				task.delay(0.6,function() if dome.Parent then TweenService:Create(dome,TweenInfo.new(0.45),{Transparency=1}):Play() end end)
				ring(data.position-Vector3.new(0,2.5,0),data.radius,data.color,0.6)
			end)
		elseif data.classId=="Explorer" then
			task.delay(duration*0.48,function()
				if not container.Parent then return end
				local grip=equipmentPart(model,"BowGrip")
				local origin=if grip then grip.Position else data.position
				-- Três flechas sobem; depois chovem sobre cada alvo.
				for i=1,3 do arrow(origin,origin+Vector3.new((i-2)*1.5,26,(i-2)*0.8),0.32,0) end
				task.delay(0.42,function()
					if not container.Parent then return end
					for _,target in data.targets or {} do
						if typeof(target)~="Vector3" then continue end
						for i=1,4 do
							local offset=Vector3.new(math.cos(i*1.7)*1.6,0,math.sin(i*1.7)*1.6)
							task.delay(i*0.05,function()
								if container.Parent and #container:GetChildren()<=60 then
									arrow(target+offset*0.4+Vector3.new(0,24,0),target+offset-Vector3.new(0,1.5,0),0.28,0,if i==4 then function() ring(target-Vector3.new(0,2.5,0),4,data.color,0.3) end else nil)
								end
							end)
						end
					end
				end)
			end)
		else
			task.delay(duration*0.5,function()
				if not container.Parent then return end
				local focus=equipmentPart(model,"ArcaneFocus")
				flash(if focus then focus.Position else data.position,data.color,1.6)
				-- Pulso: onda de choque no alcance real (26 studs), coluna de luz e clarão.
				-- Translúcidos: a área fica legível sem cobrir o combate.
				ring(data.position-Vector3.new(0,2.5,0),data.radius,data.color,0.55,nil,0.78)
				ring(data.position-Vector3.new(0,2.5,0),data.radius*0.5,Color3.fromRGB(255,240,255),0.35,nil,0.7)
				local pillar=Art.part(container,"PulsePillar",Vector3.new(12,1.2,1.2),CFrame.new(data.position+Vector3.new(0,4,0))*CFrame.Angles(0,0,math.pi/2),data.color,Enum.Material.Neon,Enum.PartType.Cylinder)
				pillar.CastShadow=false pillar.Transparency=0.55
				Debris:AddItem(pillar,0.6)
				TweenService:Create(pillar,TweenInfo.new(0.45),{Size=Vector3.new(16,0.1,0.1),Transparency=1}):Play()
				burst(data.position,data.color,1.6,0.35)
			end)
		end
	elseif data.kind=="block" then
		-- Golpe aparado: faíscas douradas na face do escudo.
		local actor=typeof(data.userId)=="number" and Players:GetPlayerByUserId(data.userId)
		local shield=equipmentPart(actor and actor.Character,"AstralShield")
		local at=if shield then shield.Position else data.position
		local normal=if shield then shield.CFrame.RightVector else Vector3.new(0,0,-1)
		for i=1,7 do
			local dir=(normal+Vector3.new(math.cos(i*0.9)*0.7,math.sin(i*1.3)*0.7,math.sin(i*0.9)*0.7)).Unit
			local spark=Art.part(container,"BlockSpark",Vector3.new(0.06,0.06,0.5),CFrame.lookAt(at,at+dir),Color3.fromRGB(255,214,120),Enum.Material.Neon)
			spark.CastShadow=false
			TweenService:Create(spark,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=CFrame.lookAt(at+dir*1.6,at+dir*3),Transparency=1}):Play()
			Debris:AddItem(spark,0.3)
		end
		burst(at,Color3.fromRGB(255,236,180),0.7,0.2)
	elseif #container:GetChildren()>60 then return
	elseif data.kind=="damage" then
		local anchor=part(data.position,Color3.new(1,1,1),Vector3.new(0.1,0.1,0.1),nil,0.8) anchor.Transparency=1
		local gui=Instance.new("BillboardGui") gui.Size=UDim2.fromOffset(95,35) gui.AlwaysOnTop=true gui.MaxDistance=100 gui.Parent=anchor
		local text=Instance.new("TextLabel") text.Size=UDim2.fromScale(1,1) text.BackgroundTransparency=1 text.Text=tostring(data.amount) text.Font=Enum.Font.GothamBold text.TextSize=22 text.TextColor3=Color3.fromRGB(255,225,166) text.TextStrokeTransparency=0.3 text.Parent=gui
		TweenService:Create(anchor,TweenInfo.new(0.75),{Position=data.position+Vector3.new(0,3,0)}):Play()
		TweenService:Create(text,TweenInfo.new(0.75),{TextTransparency=1,TextStrokeTransparency=1}):Play()
	elseif data.kind=="impact" then ring(data.position,data.radius,Color3.fromRGB(239,159,95),0.32)
	elseif data.kind=="pulse" or data.kind=="shield" then ring(data.position-Vector3.new(0,2.5,0),data.radius,data.color,0.5)
	elseif data.kind=="defeat" or data.kind=="seal" or data.kind=="dash" then
		if data.kind=="dash" and typeof(data.userId)=="number" then
			local actor=Players:GetPlayerByUserId(data.userId)
			if actor and actor.Character then actor.Character:SetAttribute("PortalDashStarted",os.clock()) end
		end
		local orb=part(data.position,data.color,Vector3.new(2,2,2),Enum.PartType.Ball,0.6)
		TweenService:Create(orb,TweenInfo.new(0.5),{Size=Vector3.new(7,7,7),Transparency=1}):Play()
	end
end

return FX
