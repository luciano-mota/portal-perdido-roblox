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

local bark=Color3.fromRGB(86,66,48)
local moss=Color3.fromRGB(88,120,70)

-- Raiz retorcida: segmentos afilados que sobem do chão, ficam e afundam.
local function rootSpike(base: Vector3,height: number,lean: Vector3,hold: number)
	local m=Instance.new("Model") m.Name="RootSpike"
	local segments=4
	local parts={}
	for i=1,segments do
		local t0,t1=(i-1)/segments,i/segments
		local a=base+lean*(t0*t0)*height+Vector3.new(0,t0*height,0)
		local b=base+lean*(t1*t1)*height+Vector3.new(0,t1*height,0)
		local width=0.55*(1-t0*0.75)
		local seg=Art.segment(m,"Root",a,b,width,if i==segments then moss else bark,Enum.Material.Wood)
		seg.CastShadow=false
		table.insert(parts,seg)
	end
	-- Nasce abaixo do chão e sobe.
	m:PivotTo(m:GetPivot()-Vector3.new(0,height+0.3,0))
	m.Parent=container
	local start=m:GetPivot()
	local rise=0.12
	local t0=os.clock()
	local connection: RBXScriptConnection?=nil
	connection=RunService.RenderStepped:Connect(function()
		local t=os.clock()-t0
		local k
		if t<rise then k=t/rise elseif t<rise+hold then k=1 else k=1-math.clamp((t-rise-hold)/0.35,0,1) end
		k=1-(1-k)*(1-k)
		if m.Parent then m:PivotTo(start+Vector3.new(0,(height+0.3)*k,0)) end
		if t>rise+hold+0.35 then if connection then connection:Disconnect() end m:Destroy() end
	end)
end

local function groundY(position: Vector3): number
	local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances={workspace:FindFirstChild("PortalChapter") or workspace.Terrain,workspace.Terrain}
	local hit=workspace:Raycast(position+Vector3.new(0,6,0),Vector3.new(0,-30,0),params)
	return if hit then hit.Position.Y else position.Y-2.5
end

local function rootField(center: Vector3,radius: number,count: number)
	local y=groundY(center)
	for i=1,count do
		local angle=i*2.399+math.random()*0.4
		local r=radius*math.sqrt((i-0.5)/count)
		local p=Vector3.new(center.X+math.cos(angle)*r,y,center.Z+math.sin(angle)*r)
		local lean=Vector3.new(math.cos(angle+1.2),0,math.sin(angle+1.2))*0.35
		rootSpike(p,2.2+math.random()*1.8,lean,0.45)
	end
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
	if typeof(data.position)~="Vector3" and typeof(data.from)=="Vector3" then data.position=data.from end
	if not root or not root:IsA("BasePart") or not data.position or (root.Position-data.position).Magnitude>180 then return end
	if data.kind=="telegraph" then
		if data.small then
			-- Golpe rápido (mordida/garras): marca curta sem texto.
			local p=part(data.position,Color3.fromRGB(233,109,73),Vector3.new(0.08,data.radius*2,data.radius*2),Enum.PartType.Cylinder,data.duration+0.1)
			p.CFrame=CFrame.new(data.position)*CFrame.Angles(0,0,math.pi/2) p.Transparency=0.55
			return
		end
		ring(data.position,data.radius,if data.style=="roots" then Color3.fromRGB(176,112,62) else Color3.fromRGB(233,109,73),data.duration,true)
		if data.style=="roots" then
			-- Brotos tremem no chão antes da erupção.
			task.delay(math.max(0,data.duration-0.35),function()
				if container.Parent then
					local y=groundY(data.position)
					for i=1,6 do
						local a=i*1.047
						local p=Vector3.new(data.position.X+math.cos(a)*data.radius*0.5,y,data.position.Z+math.sin(a)*data.radius*0.5)
						rootSpike(p,0.6,Vector3.zero,0.2)
					end
				end
			end)
		end
		return
	elseif data.kind=="vineTelegraph" then
		-- Linha no chão mostrando o alcance da vinha: sair dela ou esquivar evita o agarrão.
		local y=groundY(data.from)+0.08
		local a=Vector3.new(data.from.X,y,data.from.Z) local b=Vector3.new(data.to.X,y,data.to.Z)
		local strip=Art.part(container,"VineWarning",Vector3.new(data.width,0.06,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),Color3.fromRGB(176,112,62),Enum.Material.Neon)
		strip.CastShadow=false strip.Transparency=0.75
		TweenService:Create(strip,TweenInfo.new(data.duration),{Transparency=0.45}):Play()
		Debris:AddItem(strip,data.duration+0.05)
		return
	elseif data.kind=="vine" then
		-- Raiz sai da mão, estica até o alvo (ou o limite) e recolhe; se pegou, recolhe junto.
		local caughtPlayer=typeof(data.caught)=="number" and Players:GetPlayerByUserId(data.caught)
		local vine=Art.part(container,"Vine",Vector3.new(0.35,0.35,0.1),CFrame.lookAt(data.from,data.to),bark,Enum.Material.Wood)
		vine.CastShadow=false
		local tip=Art.part(container,"VineTip",Vector3.new(0.9,0.9,0.9),CFrame.new(data.from),moss,Enum.Material.Grass,Enum.PartType.Ball)
		tip.CastShadow=false
		local total=(data.to-data.from).Magnitude
		local started=os.clock()
		local hold=if caughtPlayer then 0.32 else 0.12
		local connection: RBXScriptConnection?=nil
		connection=RunService.RenderStepped:Connect(function()
			local t=os.clock()-started
			local from=data.from
			local length
			if t<data.travel then length=total*(t/data.travel)
			elseif t<data.travel+hold then length=total
			else length=total*(1-math.clamp((t-data.travel-hold)/0.3,0,1)) end
			-- Ao puxar, a ponta acompanha o personagem preso.
			local target=data.to
			if caughtPlayer and t>=data.travel and caughtPlayer.Character then
				local r=caughtPlayer.Character:FindFirstChild("HumanoidRootPart")
				if r and r:IsA("BasePart") then target=r.Position total=(target-from).Magnitude length=total end
			end
			local dir=(target-from)
			if dir.Magnitude<0.05 then dir=Vector3.new(0,0,-1) end
			local endPoint=from+dir.Unit*math.max(length,0.1)
			local wave=math.sin(t*30)*0.12
			vine.Size=Vector3.new(0.32,0.32,math.max(length,0.1))
			vine.CFrame=CFrame.lookAt((from+endPoint)/2,endPoint)*CFrame.new(wave,0,0)
			tip.CFrame=CFrame.new(endPoint)
			if t>data.travel+hold+0.32 then
				if connection then connection:Disconnect() end
				vine:Destroy() tip:Destroy()
			end
		end)
		return
	elseif data.kind=="snare" then
		-- Raízes enroladas nos pés do alvo enquanto estiver preso.
		local actor=typeof(data.userId)=="number" and Players:GetPlayerByUserId(data.userId)
		local character=actor and actor.Character
		local r=character and character:FindFirstChild("HumanoidRootPart")
		local center=if r and r:IsA("BasePart") then r.Position else data.position
		local y=groundY(center)
		for i=1,5 do
			local a=i*1.256
			local p=Vector3.new(center.X+math.cos(a)*0.9,y,center.Z+math.sin(a)*0.9)
			rootSpike(p,1.5,Vector3.new(-math.cos(a),0,-math.sin(a))*0.7,data.duration)
		end
		return
	elseif data.kind=="bite" then
		-- Duas fileiras de presas fechando.
		for _,s in {-1,1} do
			local jaw=Art.part(container,"Jaw",Vector3.new(1.6,0.12,0.5),CFrame.new(data.position+Vector3.new(0,s*0.55,0)),Color3.fromRGB(240,236,220),Enum.Material.Neon)
			jaw.CastShadow=false jaw.Transparency=0.2
			TweenService:Create(jaw,TweenInfo.new(0.12),{CFrame=CFrame.new(data.position),Transparency=1}):Play()
			Debris:AddItem(jaw,0.2)
		end
		return
	elseif data.kind=="claw" then
		-- Três riscos de garra em diagonal.
		local look=if typeof(data.look)=="Vector3" then data.look else Vector3.new(0,0,-1)
		local basis=CFrame.lookAt(data.position,data.position+look)
		for i=-1,1 do
			local a=basis*CFrame.new(i*0.45,0.9,0)*CFrame.Angles(0,0,0.6)
			local slash=Art.part(container,"ClawSlash",Vector3.new(0.08,2.2,0.08),a,Color3.fromRGB(255,232,214),Enum.Material.Neon)
			slash.CastShadow=false
			TweenService:Create(slash,TweenInfo.new(0.18),{CFrame=a*CFrame.new(0,-1.4,0),Transparency=1}):Play()
			Debris:AddItem(slash,0.25)
		end
		return
	elseif data.kind=="blink" then
		burst(data.from,data.color,1.8,0.35)
		burst(data.to,data.color,1.2,0.3)
		local trail=Art.segment(container,"BlinkTrail",data.from,data.to,0.25,data.color,Enum.Material.Neon)
		trail.CastShadow=false trail.Transparency=0.4
		TweenService:Create(trail,TweenInfo.new(0.3),{Transparency=1}):Play()
		Debris:AddItem(trail,0.35)
		return
	elseif data.kind=="evade" then
		burst(data.position,Color3.fromRGB(200,230,255),0.9,0.25)
		return
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
	elseif data.kind=="impact" then
		ring(data.position,data.radius,if data.style=="roots" then Color3.fromRGB(150,110,70) else Color3.fromRGB(239,159,95),0.32)
		if data.style=="roots" then rootField(data.position,data.radius,math.clamp(math.floor(data.radius*1.4),6,14)) end
	elseif data.kind=="pulse" or data.kind=="shield" then ring(data.position-Vector3.new(0,2.5,0),data.radius,data.color,0.5)
	elseif data.kind=="defeat" or data.kind=="seal" or data.kind=="dash" then
		if data.kind=="dash" and typeof(data.userId)=="number" then
			local actor=Players:GetPlayerByUserId(data.userId)
			if actor and actor.Character then
				actor.Character:SetAttribute("PortalDashStarted",os.clock())
				if typeof(data.dir)=="Vector3" then actor.Character:SetAttribute("PortalDashDir",data.dir) end
			end
		end
		local orb=part(data.position,data.color,Vector3.new(2,2,2),Enum.PartType.Ball,0.6)
		TweenService:Create(orb,TweenInfo.new(0.5),{Size=Vector3.new(7,7,7),Transparency=1}):Play()
	end
end

return FX
