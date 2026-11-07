--!strict
-- Visões do Regente do Vazio (cliente, só apresentação):
--   flashback(region): ao vencer o chefe final de uma região, a tela escurece e o jogador vê
--     o Regente num espaço do vazio, sussurrando uma frase ligada àquela região.
--   rift(center): na fase 5, depois do Arauto Partido, uma fenda se abre sobre a arena e
--     mostra o Regente encapuzado flutuando lá dentro — a revelação do verdadeiro vilão.
-- Cria tudo localmente, controla a câmera durante a visão e devolve o controle no fim.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Lighting=game:GetService("Lighting")
local Art=require(script.Parent.Art)
local Villain=require(script.Parent.VillainArt)
local Body=require(script.Parent.CinematicBody)
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Vision={}
Vision.active=false

local C=Color3.fromRGB
local violet=C(186,110,255)

-- Frases (originais) de cada flashback e da fenda.
Vision.Lines={
	Lumen={"Um fragmento... tão pequeno, e já brilha nas suas mãos.","Continuem juntando os pedaços. Por mim."},
	CrystalAbyss={"Os cristais lembram de mim.","Eu os ensinei a refletir só o que eu quero que vocês vejam."},
	HourDesert={"Aqui o tempo me obedece.","Vocês já se perguntaram quanto tempo passou na escola?"},
	EclipseCitadel={"O sol se apagou para que eu visse vocês chegando.","Cada selo que vocês rompem abre uma porta... para mim."},
	Convergence={"O Arauto era só uma porta.","E vocês acabaram de abri-la para mim. Venham. O Domínio do Vazio espera."},
}

-- Regente: modelo gerado (VillainPreviews.Regent) posado com braços baixos e a garra estendida;
-- sem ele, a figura procedural do VillainArt. `cf` aponta o rosto para −Z.
local function regentFigure(parent: Instance,cf: CFrame,scale: number): (Model,BasePart?)
	local folder=ReplicatedStorage:FindFirstChild("VillainPreviews")
	local template=folder and folder:FindFirstChild("Regent")
	if template and template:IsA("Model") then
		local m=template:Clone()
		for _,item in m:GetDescendants() do if item:IsA("BasePart") then item.Anchored=true item.CanCollide=false item.CanQuery=false item.CastShadow=false end end
		m:PivotTo(CFrame.identity)
		m:ScaleTo(scale*1.15)
		m.Parent=parent
		Body.relaxArms(m)
		local body=Body.new(m,false)
		if body then
			body:apply({RightUpperArm=Vector3.new(78,0,10),RightLowerArm=Vector3.new(18,0,0),LeftUpperArm=Vector3.new(6,0,-8),Head=Vector3.new(-6,0,0),UpperTorso=Vector3.new(-3,0,0)},CFrame.identity,0)
		end
		-- Posado em torno da origem (pés em y 0, frente −Z): leva tudo para `cf`.
		m:PivotTo(cf*m:GetPivot())
		local head=m:FindFirstChild("Head")
		-- Luz de recorte violeta à frente do rosto: o vazio é escuro, o Regente precisa ser lido.
		if head and head:IsA("BasePart") then
			local key=Art.part(m,"RegentKeyLight",Vector3.new(0.2,0.2,0.2),CFrame.new(head.Position+(cf.LookVector*5)+Vector3.new(0,1.5,0)),violet,Enum.Material.SmoothPlastic)
			key.Transparency=1 key.CastShadow=false
			local light=Instance.new("PointLight") light.Color=Color3.fromRGB(220,190,255) light.Range=14 light.Brightness=2.4 light.Shadows=false light.Parent=key
		end
		return m,if head and head:IsA("BasePart") then head else nil
	end
	local m,_=Villain.regent(parent,cf,scale)
	local head=m:FindFirstChild("Hood")
	return m,if head and head:IsA("BasePart") then head else nil
end

local function whisper(lines: {string}, total: number): ScreenGui?
	local gui=Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not gui then return nil end
	local screen=Instance.new("ScreenGui") screen.Name="RegentWhisper" screen.DisplayOrder=40 screen.IgnoreGuiInset=true screen.ResetOnSpawn=false
	local label=Instance.new("TextLabel") label.AnchorPoint=Vector2.new(0.5,1) label.Position=UDim2.new(0.5,0,1,-60)
	label.Size=UDim2.new(0.86,0,0,70) label.BackgroundTransparency=1 label.Font=Enum.Font.GothamMedium label.TextScaled=true
	label.TextColor3=C(232,210,255) label.TextStrokeTransparency=0.4 label.TextStrokeColor3=C(40,10,60) label.Text="" label.TextTransparency=1 label.Parent=screen
	local constraint=Instance.new("UITextSizeConstraint") constraint.MaxTextSize=28 constraint.Parent=label
	local name=Instance.new("TextLabel") name.AnchorPoint=Vector2.new(0.5,1) name.Position=UDim2.new(0.5,0,1,-134)
	name.Size=UDim2.new(0.6,0,0,22) name.BackgroundTransparency=1 name.Font=Enum.Font.GothamBold name.TextScaled=true
	name.TextColor3=C(190,140,255) name.Text="O REGENTE DO VAZIO" name.TextTransparency=1 name.Parent=screen
	local nameLimit=Instance.new("UITextSizeConstraint") nameLimit.MaxTextSize=16 nameLimit.Parent=name
	screen.Parent=gui
	task.spawn(function()
		local each=total/#lines
		TweenService:Create(name,TweenInfo.new(0.8),{TextTransparency=0}):Play()
		for _,line in lines do
			if not screen.Parent then return end
			label.Text="“"..line.."”"
			TweenService:Create(label,TweenInfo.new(0.6),{TextTransparency=0}):Play()
			task.wait(each-0.7)
			if not screen.Parent then return end
			TweenService:Create(label,TweenInfo.new(0.5),{TextTransparency=1}):Play()
			task.wait(0.6)
		end
	end)
	return screen
end

local function tint(): (ColorCorrectionEffect, BlurEffect)
	local camera=workspace.CurrentCamera
	local cc=Instance.new("ColorCorrectionEffect") cc.Name="RegentVisionTint" cc.TintColor=C(200,170,255) cc.Saturation=-0.2 cc.Contrast=0.15 cc.Brightness=0
	cc.Parent=camera
	local blur=Instance.new("BlurEffect") blur.Name="RegentVisionBlur" blur.Size=0 blur.Parent=camera
	return cc,blur
end

-- O HUD do jogo some durante a visão (só o sussurro aparece).
local function hud(visible: boolean)
	local gui=Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local screen=gui and gui:FindFirstChild("PortalPerdidoHUD")
	if screen and screen:IsA("ScreenGui") then screen.Enabled=visible end
end

local function restoreCamera()
	local camera=workspace.CurrentCamera
	local character=Players.LocalPlayer.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if camera then
		camera.CameraType=Enum.CameraType.Custom
		if humanoid then camera.CameraSubject=humanoid end
		camera.FieldOfView=70
	end
end

-- Flashback: espaço do vazio isolado (alto no céu), câmera aproxima do rosto do Regente.
function Vision.flashback(region: string, onDone: (() -> ())?)
	if Vision.active then return end
	Vision.active=true
	hud(false)
	local camera=workspace.CurrentCamera
	local origin=Vector3.new(0,3400,0)
	local scene=Instance.new("Model") scene.Name="RegentFlashback" scene.Parent=workspace
	-- Fundo: disco escuro com espiral do vazio e estilhaços flutuando.
	local back=Art.part(scene,"VoidBackdrop",Vector3.new(1,220,220),CFrame.new(origin+Vector3.new(0,6,-40))*CFrame.Angles(0,math.pi/2,0),C(12,6,22),Enum.Material.SmoothPlastic,Enum.PartType.Cylinder)
	back.CastShadow=false
	for arm=1,3 do
		for step=1,18 do
			local function point(t: number): Vector3
				local a=t*math.pi*2.6+arm*math.pi*2/3
				local r=4+t*60
				return origin+Vector3.new(math.cos(a)*r,6+math.sin(a)*r,-38)
			end
			local a,b=point((step-1)/18),point(step/18)
			local band=Art.part(scene,"VoidSpiral",Vector3.new(2+step*0.35,0.4,(b-a).Magnitude+1),CFrame.lookAt((a+b)/2,b),violet:Lerp(C(80,40,160),step/18),Enum.Material.Neon)
			band.CastShadow=false band.Transparency=0.3+step/18*0.5
		end
	end
	local rng=Random.new(9)
	local shards: {BasePart}={}
	for i=1,14 do
		local p=origin+Vector3.new(rng:NextNumber(-30,30),rng:NextNumber(-10,24),rng:NextNumber(-30,-4))
		local shard=Art.part(scene,"VoidShard",Vector3.new(1,1.6,1)*rng:NextNumber(0.8,3),CFrame.new(p)*CFrame.Angles(rng:NextNumber(0,6),rng:NextNumber(0,6),0),C(40,30,60),Enum.Material.Slate,Enum.PartType.Ball)
		shard.CastShadow=false
		table.insert(shards,shard)
	end
	local regent,head=regentFigure(scene,CFrame.new(origin+Vector3.new(0,-3.5,0))*CFrame.Angles(0,math.pi,0),1)
	local flashBase=regent:GetPivot()
	local cc,blur=tint()
	cc.Brightness=1
	TweenService:Create(cc,TweenInfo.new(0.9),{Brightness=-0.05}):Play()
	local whisperGui=whisper(Vision.Lines[region] or Vision.Lines.Lumen,6.2)
	local savedFov=camera.FieldOfView
	local start=os.clock()
	local DURATION=7.2
	local connection: RBXScriptConnection
	connection=RunService.RenderStepped:Connect(function()
		local t=(os.clock()-start)/DURATION
		camera.CameraType=Enum.CameraType.Scriptable
		camera.FieldOfView=40
		local headPos=if head then head.Position else regent:GetPivot().Position+Vector3.new(0,6,0)
		local e=1-(1-math.min(t,1))^2
		local eye=headPos+Vector3.new(1.4-0.9*e,-0.4+0.2*e,16-11*e)
		camera.CFrame=CFrame.lookAt(eye,headPos+Vector3.new(0,-0.3,0))
		-- Respiração e flutuação do Regente; estilhaços giram devagar.
		regent:PivotTo(flashBase*CFrame.new(0,math.sin(os.clock()*1.4)*0.15,0))
		for i,shard in shards do shard.CFrame=shard.CFrame*CFrame.Angles(0.004*i%3,0.006,0) end
		blur.Size=if t>0.85 then (t-0.85)/0.15*20 else 0
		if t>=1 then
			connection:Disconnect()
			scene:Destroy() cc:Destroy() blur:Destroy()
			if whisperGui then whisperGui:Destroy() end
			camera.FieldOfView=savedFov
			restoreCamera()
			hud(true)
			Vision.active=false
			if onDone then onDone() end
		end
	end)
end

-- Fenda sobre a arena: abre, mostra o Regente encapuzado lá dentro, fecha num clarão.
function Vision.rift(center: Vector3, onDone: (() -> ())?)
	if Vision.active then return end
	Vision.active=true
	hud(false)
	local camera=workspace.CurrentCamera
	local scene=Instance.new("Model") scene.Name="RegentRift" scene.Parent=workspace
	local riftPos=center+Vector3.new(0,26,-36)
	local facing=CFrame.lookAt(riftPos,Vector3.new(center.X,riftPos.Y,center.Z+40))
	-- Interior: disco escuro com espiral e névoa; o Regente flutua dentro, encapuzado.
	local void=Art.part(scene,"RiftVoid",Vector3.new(0.4,1,1),facing*CFrame.new(0,0,1.5)*CFrame.Angles(0,math.pi/2,0),C(10,4,20),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
	void.CastShadow=false
	local rim: {BasePart}={}
	for k=0,31 do
		local seg=Art.part(scene,"RiftEdge",Vector3.new(0.6,1,0.6),facing,violet,Enum.Material.Neon)
		seg.CastShadow=false
		rim[k+1]=seg
	end
	local spiral: {BasePart}={}
	for k=1,24 do
		local s=Art.part(scene,"RiftSwirl",Vector3.new(0.3,0.3,1),facing,C(220,160,255),Enum.Material.Neon)
		s.CastShadow=false s.Transparency=0.4
		spiral[k]=s
	end
	local regent,head=regentFigure(scene,facing*CFrame.new(0,-8,0.4),1.15)
	for _,p in regent:GetDescendants() do if p:IsA("BasePart") then p.LocalTransparencyModifier=1 end end
	local light=Instance.new("PointLight") light.Color=violet light.Range=60 light.Brightness=0 light.Parent=void
	local cc,blur=tint()
	cc.TintColor=C(235,220,255)
	local whisperGui: ScreenGui?=nil
	local start=os.clock()
	local DURATION=11
	local savedFov=camera.FieldOfView
	local regentBase=regent:GetPivot()
	local connection: RBXScriptConnection
	connection=RunService.RenderStepped:Connect(function()
		local time=os.clock()-start
		local t=time/DURATION
		-- Abertura (0–1,6 s), estável (1,6–9,4 s), fechamento (9,4–11 s).
		local open=if time<1.6 then (time/1.6)^0.6 elseif time>9.4 then math.max(0,1-(time-9.4)/0.9) else 1
		local radiusX,radiusY=9*open,12*open
		void.Size=Vector3.new(0.4,radiusY*2,radiusX*2)
		void.CFrame=facing*CFrame.new(0,0,1.5)*CFrame.Angles(0,math.pi/2,0)*CFrame.new(0,0,0)
		-- Disco elíptico: cilindro esticado (Y = altura, Z = largura depois da rotação).
		for k,seg in rim do
			local a=(k-1)/#rim*math.pi*2
			local b=k/#rim*math.pi*2
			local pa=(facing*CFrame.new(math.cos(a)*radiusX,math.sin(a)*radiusY,1.2)).Position
			local pb=(facing*CFrame.new(math.cos(b)*radiusX,math.sin(b)*radiusY,1.2)).Position
			local jitter=0.35+0.25*math.sin(time*9+k)
			seg.Size=Vector3.new(jitter,jitter,(pb-pa).Magnitude+0.3)
			seg.CFrame=CFrame.lookAt((pa+pb)/2,pb)
			seg.Transparency=if open<=0.02 then 1 else 0
		end
		for k,s in spiral do
			local u=k/#spiral
			local a=u*math.pi*4-time*1.5
			local p=(facing*CFrame.new(math.cos(a)*radiusX*u*0.95,math.sin(a)*radiusY*u*0.95,1.3)).Position
			local a2=a+0.3
			local q=(facing*CFrame.new(math.cos(a2)*radiusX*u*0.95,math.sin(a2)*radiusY*u*0.95,1.3)).Position
			s.Size=Vector3.new(0.25,0.25,math.max(0.1,(q-p).Magnitude))
			s.CFrame=CFrame.lookAt((p+q)/2,q)
			s.Transparency=if open<=0.02 then 1 else 0.35+u*0.4
		end
		light.Brightness=open*3
		-- O Regente surge de dentro da fenda depois que ela se abre.
		local reveal=math.clamp((time-1.8)/1.4,0,1)*(if time>9.2 then math.max(0,1-(time-9.2)/0.5) else 1)
		for _,p in regent:GetDescendants() do if p:IsA("BasePart") then p.LocalTransparencyModifier=1-reveal end end
		regent:PivotTo(regentBase*CFrame.new(0,math.sin(time*1.2)*0.25,0))
		if time>2 and not whisperGui then whisperGui=whisper(Vision.Lines.Convergence,6.6) end
		-- Câmera: dos jogadores olhando a fenda abrir; depois aproxima do rosto encapuzado.
		camera.CameraType=Enum.CameraType.Scriptable
		local wide=CFrame.lookAt(center+Vector3.new(14,6,26),riftPos)
		local headPos=if head then head.Position else regent:GetPivot().Position+Vector3.new(0,6,0)
		local close=CFrame.lookAt(headPos+(facing.LookVector*7)+Vector3.new(1.2,-0.4,0),headPos)
		local push=math.clamp((time-3)/4,0,1)
		push=push*push*(3-2*push)
		if time>8.6 then push=math.max(0,1-(time-8.6)/1.2) end
		camera.CFrame=wide:Lerp(close,push*0.85)
		camera.FieldOfView=55-15*push
		cc.Brightness=if time>9.6 then math.max(0,1-(time-9.6)/1.2)*0.9 else 0
		blur.Size=if time<0.6 then 12*(1-time/0.6) else 0
		if t>=1 then
			connection:Disconnect()
			scene:Destroy() cc:Destroy() blur:Destroy()
			if whisperGui then whisperGui:Destroy() end
			camera.FieldOfView=savedFov
			restoreCamera()
			hud(true)
			Vision.active=false
			if onDone then onDone() end
		end
	end)
end

return Vision
