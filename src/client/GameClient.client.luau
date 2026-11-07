--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Lighting=game:GetService("Lighting")
local GuiService=game:GetService("GuiService")
local player=Players.LocalPlayer
local Chapter=require(ReplicatedStorage.Shared.Config.Chapter)
local Classes=require(ReplicatedStorage.Shared.Config.Classes)
local FX=require(ReplicatedStorage.Shared.VisualEffects)
local Art=require(ReplicatedStorage.Shared.Art)
local Audio=require(ReplicatedStorage.Shared.Audio)
local remotes=ReplicatedStorage:WaitForChild("GameRemotes")
local choose=remotes:WaitForChild("ChooseClass") :: RemoteEvent
local attackRemote=remotes:WaitForChild("AttackEnemy") :: RemoteEvent
local skillRemote=remotes:WaitForChild("UseSkill") :: RemoteEvent
local dashRemote=remotes:WaitForChild("Dash") :: RemoteEvent
local blockRemote=remotes:WaitForChild("Block") :: RemoteEvent
local kickRemote=remotes:WaitForChild("Kick") :: RemoteEvent
local crouchRemote=remotes:WaitForChild("Crouch") :: RemoteEvent
local saveControlsRemote=remotes:WaitForChild("SaveControls") :: RemoteEvent
local Controls=require(ReplicatedStorage.Shared.TouchControls)
local notify=remotes:WaitForChild("Notify") :: RemoteEvent
local gui=player:WaitForChild("PlayerGui")
local old=gui:FindFirstChild("PortalPerdidoHUD") if old then old:Destroy() end
local screen=Instance.new("ScreenGui") screen.Name="PortalPerdidoHUD" screen.ResetOnSpawn=false screen.DisplayOrder=10 screen.Parent=gui
local ink=Color3.fromRGB(20,36,48)
local parchment=Color3.fromRGB(239,231,210)
local amber=Color3.fromRGB(230,185,110)
local teal=Color3.fromRGB(76,171,175)
local introDone=false local introStarted=false local pendingEnding=false
local refresh: () -> ()

local function corner(object: Instance,radius: number)
	local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,radius) c.Parent=object
end
local function frame(parent: Instance,name: string,size: UDim2,pos: UDim2,color: Color3?): Frame
	local f=Instance.new("Frame") f.Name=name f.Size=size f.Position=pos f.BackgroundColor3=color or ink f.BorderSizePixel=0 f.Parent=parent corner(f,10) return f
end
local function text(parent: Instance,name: string,value: string,size: number,pos: UDim2,dimensions: UDim2,color: Color3?): TextLabel
	local t=Instance.new("TextLabel") t.Name=name t.Text=value t.TextSize=size t.Font=Enum.Font.Gotham t.TextColor3=color or parchment t.Size=dimensions t.Position=pos t.BackgroundTransparency=1 t.TextWrapped=true t.Parent=parent return t
end
local function button(parent: Instance,name: string,value: string,pos: UDim2,size: UDim2,color: Color3?): TextButton
	local b=Instance.new("TextButton") b.Name=name b.Text=value b.Font=Enum.Font.GothamSemibold b.TextSize=15 b.TextColor3=parchment b.TextWrapped=true b.Size=size b.Position=pos b.BackgroundColor3=color or Color3.fromRGB(43,106,115) b.BorderSizePixel=0 b.AutoButtonColor=true b.Parent=parent corner(b,10) b.Activated:Connect(Audio.click) return b
end
local function limit(object: Instance,width: number,height: number)
	local c=Instance.new("UISizeConstraint") c.MaxSize=Vector2.new(width,height) c.Parent=object
end
local function stroke(object: Instance,color: Color3)
	local s=Instance.new("UIStroke") s.Color=color s.Thickness=1 s.Transparency=0.5 s.Parent=object
end

local loading=text(screen,"Loading","Preparando a travessia…",19,UDim2.fromScale(0.2,0.4),UDim2.fromScale(0.6,0.15))
local card=frame(screen,"ClassSelection",UDim2.fromOffset(460,350),UDim2.fromScale(0.5,0.5)) card.AnchorPoint=Vector2.new(0.5,0.5) card.Visible=false stroke(card,amber)
local classButtons: {TextButton}={}
local cardScale=Instance.new("UIScale") cardScale.Parent=card
text(card,"Title","AS CRÔNICAS DO\nPORTAL PERDIDO",21,UDim2.fromOffset(18,15),UDim2.new(1,-36,0,57),amber).Font=Enum.Font.GothamBold
text(card,"Subtitle","CAPÍTULO 1 · A TRAVESSIA\nEscolha como enfrentará este novo mundo.",13,UDim2.fromOffset(20,77),UDim2.new(1,-40,0,43))
-- Seis heróis em grade 2×3. Bloqueados (Rota A) mostram como desbloquear; o servidor valida.
local HERO_ORDER={"Guardian","Explorer","Artificer","Brawler","Arcanist","Shade"}
local UNLOCK_HINT={"Conclua o Vale de Lúmen","Conclua o Abismo de Cristal","Conclua o Deserto das Horas"}
local function heroAvailable(id: string): boolean
	local list=player:GetAttribute("AvailableHeroes")
	if typeof(list)~="string" then return Classes[id].unlockPhase==nil end
	return table.find(string.split(list,","),id)~=nil
end
local refreshHeroButtons: () -> ()=function() end
local heroLabels: {[string]: () -> ()}={}
for i,id in HERO_ORDER do
	local class=Classes[id]
	local column=(i-1)%2
	local row=(i-1)//2
	local b=button(card,"Choose"..id,"",UDim2.new(column*0.5,if column==0 then 18 else 5,0,124+row*62),UDim2.new(0.5,-23,0,56),Color3.fromRGB(35,69,81))
	b.TextSize=12
	classButtons[i]=b
	stroke(b,class.color)
	b.TextXAlignment=Enum.TextXAlignment.Left
	heroLabels[id]=function()
		local open=heroAvailable(id)
		b.Text=if open then class.displayName.."\n"..class.health.." VIDA · "..class.skillName else class.displayName.."\nBLOQUEADO · "..(UNLOCK_HINT[class.unlockPhase or 1] or "")
		b.BackgroundColor3=if open then Color3.fromRGB(35,69,81) else Color3.fromRGB(32,38,44)
		b.TextColor3=if open then parchment else Color3.fromRGB(150,156,160)
		b.AutoButtonColor=open
	end
	heroLabels[id]()
	local padding=Instance.new("UIPadding") padding.PaddingLeft=UDim.new(0,58) padding.PaddingRight=UDim.new(0,6) padding.Parent=b
	local preview=Instance.new("ViewportFrame") preview.Name="ClassPortrait" preview.Size=UDim2.fromOffset(50,52) preview.Position=UDim2.fromOffset(-54,2) preview.BackgroundTransparency=1 preview.Ambient=Color3.fromRGB(180,185,194) preview.LightColor=Color3.fromRGB(255,238,211) preview.Parent=b
	local scene=Instance.new("WorldModel") scene.Parent=preview
	local camera=Instance.new("Camera") camera.Parent=preview preview.CurrentCamera=camera
	-- Retrato humanizado publicado pelo servidor (ReplicatedStorage.ClassPreviews). O boneco procedural
	-- só aparece como contingência se o retrato não chegar; antes ele surgia por um instante na abertura.
	local function humanize(source: Instance?): boolean
		local head=source and source:FindFirstChild("Head")
		if not source or not source:IsA("Model") or not head or not head:IsA("BasePart") then return false end
		local humanized=source:Clone()
		humanized:PivotTo(CFrame.identity)
		humanized.Parent=scene
		local headCF=(humanized:FindFirstChild("Head") :: BasePart).CFrame
		local h=headCF.Position
		-- Close de rosto e ombros (o card tem ~58 px), levemente de lado, na direção do rosto.
		camera.CFrame=CFrame.lookAt(h+headCF.LookVector*2.9+headCF.RightVector*0.55+Vector3.new(0,0.2,0),h-Vector3.new(0,0.22,0))
		camera.FieldOfView=32
		return true
	end
	local previews=ReplicatedStorage:FindFirstChild("ClassPreviews")
	if not humanize(previews and previews:FindFirstChild(id)) then
		task.spawn(function()
			local folder=ReplicatedStorage:WaitForChild("ClassPreviews",4)
			if humanize(folder and folder:WaitForChild(id,2)) then return end
			local model=Art.classPreview(id,class.color) model.Parent=scene
			camera.CFrame=CFrame.lookAt(Vector3.new(5,4.2,-8),Vector3.new(0,3.1,0)) camera.FieldOfView=40
		end)
	end
	b.Activated:Connect(function() if heroAvailable(id) then choose:FireServer(id) end end)
end
refreshHeroButtons=function() for _,update in heroLabels do update() end end
player:GetAttributeChangedSignal("AvailableHeroes"):Connect(refreshHeroButtons)
text(card,"Footer","Q atacar  ·  R habilidade  ·  Shift esquiva\nNo celular, use os botões na tela.",11,UDim2.fromOffset(20,318),UDim2.new(1,-40,0,26),Color3.fromRGB(177,195,200))

local hud=frame(screen,"QuestPanel",UDim2.new(0.92,0,0,96),UDim2.new(0.5,0,0,8)) hud.AnchorPoint=Vector2.new(0.5,0) limit(hud,510,96) hud.Visible=false
local heading=text(hud,"Heading","",12,UDim2.fromOffset(12,7),UDim2.new(1,-24,0,18),amber) heading.Font=Enum.Font.GothamSemibold
local objective=text(hud,"Objective","",14,UDim2.fromOffset(12,28),UDim2.new(1,-24,0,39))
local hpBG=frame(hud,"HealthTrack",UDim2.new(0.52,0,0,8),UDim2.new(0.04,0,0,78),Color3.fromRGB(50,66,74))
local hpFill=frame(hpBG,"Fill",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Color3.fromRGB(104,170,135))
local hpText=text(hud,"Health","",10,UDim2.new(0.04,0,0,64),UDim2.new(0.52,0,0,14))
local coins=text(hud,"Coins","",11,UDim2.new(0.6,0,0,62),UDim2.new(0.36,0,0,31),amber)
local journalButton=button(screen,"JournalButton","DIÁRIO  [J]",UDim2.new(1,-110,0,112),UDim2.fromOffset(100,32),ink) journalButton.Visible=false
local attackButton=button(screen,"AttackButton","ATACAR [Q]",UDim2.new(1,-174,1,-90),UDim2.fromOffset(150,60),Color3.fromRGB(169,89,65)) attackButton.Visible=false
local skillButton=button(screen,"SkillButton","HABILIDADE",UDim2.new(1,-290,1,-90),UDim2.fromOffset(106,60)) skillButton.Visible=false
local dashButton=button(screen,"DashButton","ESQUIVA",UDim2.new(1,-174,1,-142),UDim2.fromOffset(150,42),ink) dashButton.Visible=false
-- Defesa do Guardião: segurar F ou o botão (toque) mantém o escudo erguido; o servidor valida.
local blockButton=button(screen,"BlockButton","DEFENDER [F]",UDim2.new(1,-290,1,-142),UDim2.fromOffset(106,42),Color3.fromRGB(46,72,128)) blockButton.Visible=false
local kickButton=button(screen,"KickButton","CHUTAR [C]",UDim2.new(1,-174,1,-194),UDim2.fromOffset(150,44),ink) kickButton.Visible=false
-- Agachar: segurar Ctrl (teclado) ou tocar para alternar (toque). Agachado + chutar = rasteira.
local crouchButton=button(screen,"CrouchButton","AGACHAR [CTRL]",UDim2.new(1,-290,1,-194),UDim2.fromOffset(106,44),ink) crouchButton.Visible=false
-- Pular (toque): substitui o botão de pulo padrão do Roblox para entrar no layout configurável.
local jumpButton=button(screen,"JumpButton","PULAR",UDim2.new(1,-140,1,-64),UDim2.fromOffset(120,50),Color3.fromRGB(58,84,110)) jumpButton.Visible=false
local boss=frame(screen,"BossHealth",UDim2.new(0.86,0,0,40),UDim2.new(0.5,0,0,116),Color3.fromRGB(51,32,41)) boss.AnchorPoint=Vector2.new(0.5,0) limit(boss,500,40) boss.Visible=false
local bossText=text(boss,"Name","",12,UDim2.new(0.03,0,0,3),UDim2.new(0.94,0,0,20),parchment)
local bossFill=frame(boss,"Fill",UDim2.new(0.94,0,0,6),UDim2.new(0.03,0,0,28),Color3.fromRGB(196,114,87))
local toast=text(screen,"Toast","",15,UDim2.fromScale(0.5,0.37),UDim2.new(0.85,0,0,46),amber) toast.AnchorPoint=Vector2.new(0.5,0.5) toast.TextStrokeTransparency=0.15 toast.Visible=false
local toastVersion=0
local function showToast(value: string)
	-- O objetivo inicial já aparece no HUD depois da introdução; não sobrepor o texto do prólogo.
	if not introDone then return end
	toastVersion+=1 local version=toastVersion toast.Text=value toast.Visible=true
	task.delay(4,function() if toastVersion==version then toast.Visible=false end end)
end

local dialogue=frame(screen,"Dialogue",UDim2.new(0.92,0,0,180),UDim2.new(0.5,0,1,-14)) dialogue.AnchorPoint=Vector2.new(0.5,1) limit(dialogue,650,180) dialogue.Visible=false stroke(dialogue,amber)
local speaker=text(dialogue,"Speaker","",13,UDim2.fromOffset(18,12),UDim2.new(1,-36,0,20),amber)
local speech=text(dialogue,"Speech","",16,UDim2.fromOffset(18,39),UDim2.new(1,-36,0,83))
local portrait=Instance.new("ViewportFrame") portrait.Name="IlyraPortrait" portrait.Size=UDim2.fromOffset(88,95) portrait.Position=UDim2.fromOffset(16,39) portrait.BackgroundColor3=Color3.fromRGB(31,54,65) portrait.Ambient=Color3.fromRGB(188,192,203) portrait.LightColor=Color3.fromRGB(255,236,215) portrait.Parent=dialogue corner(portrait,8)
local portraitReady=false
local function setPortrait(show: boolean)
	portrait.Visible=show
	speech.Position=UDim2.fromOffset(if show then 120 else 18,39)
	speech.Size=UDim2.new(1,if show then -138 else -36,0,83)
	if show and not portraitReady then
		local world=workspace:FindFirstChild("PortalChapter")
		local npc=world and world:FindFirstChild("Village") and world.Village:FindFirstChild("Ilyra")
		if npc and npc:IsA("Model") then
			local scene=Instance.new("WorldModel") scene.Parent=portrait
			local clone=npc:Clone()
			for _, v in clone:GetDescendants() do if v:IsA("BillboardGui") or v:IsA("ProximityPrompt") then v:Destroy() elseif v:IsA("BasePart") then v.LocalTransparencyModifier=0 end end
			clone:PivotTo(CFrame.identity) clone.Parent=scene
			-- Enquadra rosto e ombros: funciona tanto para a Ilyra gerada quanto para a provisória.
			local head=clone:FindFirstChild("Head",true)
			local focus=if head and head:IsA("BasePart") then head.Position-Vector3.new(0,0.3,0) else Vector3.new(0,2.6,0)
			local camera=Instance.new("Camera") camera.CFrame=CFrame.lookAt(focus+Vector3.new(0.35,0.15,-3.4),focus) camera.FieldOfView=30 camera.Parent=portrait portrait.CurrentCamera=camera portraitReady=true
		end
	end
end
local continueButton=button(dialogue,"Continue","CONTINUAR",UDim2.new(1,-156,1,-45),UDim2.fromOffset(138,32))
local pages: {string}={} local page=1
local ending=frame(screen,"Ending",UDim2.fromScale(0.9,0.85),UDim2.fromScale(0.5,0.5)) ending.AnchorPoint=Vector2.new(0.5,0.5) limit(ending,620,420) ending.Visible=false stroke(ending,amber)
text(ending,"Chapter","CAPÍTULO CONCLUÍDO",14,UDim2.fromScale(0.05,0.08),UDim2.fromScale(0.9,0.1),amber)
text(ending,"Title","O FRAGMENTO\nDA AURORA",30,UDim2.fromScale(0.08,0.22),UDim2.fromScale(0.84,0.25),parchment).Font=Enum.Font.GothamBold
text(ending,"Epilogue","O Portal Primordial continua selado.\nO Regente do Vazio sabe que você chegou.\n\nSua primeira travessia terminou. A aventura em Aetherion continua.",16,UDim2.fromScale(0.1,0.5),UDim2.fromScale(0.8,0.28))
button(ending,"Explore","CONTINUAR EXPLORANDO",UDim2.fromScale(0.15,0.83),UDim2.fromScale(0.7,0.11)).Activated:Connect(function() ending.Visible=false refresh() end)
continueButton.Activated:Connect(function()
	page+=1
	if page>#pages then dialogue.Visible=false if pendingEnding then pendingEnding=false ending.Visible=true end refresh()
	else speech.Text=pages[page] continueButton.Text=if page==#pages then "CONCLUIR" else "CONTINUAR" end
end)

local journal=frame(screen,"Journal",UDim2.new(0.92,0,0.9,0),UDim2.fromScale(0.5,0.5)) journal.AnchorPoint=Vector2.new(0.5,0.5) limit(journal,550,440) journal.Visible=false stroke(journal,amber)
text(journal,"Title","DIÁRIO DA TRAVESSIA",20,UDim2.fromScale(0.05,0.03),UDim2.fromScale(0.75,0.1),amber)
button(journal,"Close","X",UDim2.new(1,-46,0,12),UDim2.fromOffset(32,30),ink).Activated:Connect(function() journal.Visible=false refresh() end)
local entries={}
for i,q in Chapter.Quests do entries[i]=text(journal,"Quest"..i,"",14,UDim2.new(0.07,0,0.17+(i-1)*0.105,0),UDim2.new(0.86,0,0.1,0)) entries[i].TextXAlignment=Enum.TextXAlignment.Left end
local journalDetails=text(journal,"Details","",12,UDim2.fromScale(0.07,0.73),UDim2.fromScale(0.86,0.16),Color3.fromRGB(178,201,205))
local audioToggle=button(journal,"AudioToggle","ÁUDIO: LIGADO",UDim2.fromScale(0.07,0.91),UDim2.fromScale(0.45,0.07),ink) audioToggle.TextSize=12
audioToggle.Activated:Connect(function() Audio.muted=not Audio.muted audioToggle.Text=if Audio.muted then "ÁUDIO: DESLIGADO" else "ÁUDIO: LIGADO" end)
-- Editor dos controles de toque (posição, tamanho e opacidade; salvo no perfil).
local controlsButton=button(journal,"ControlsButton","CONTROLES",UDim2.fromScale(0.55,0.91),UDim2.fromScale(0.38,0.07),Color3.fromRGB(43,72,96)) controlsButton.TextSize=12
journalButton.Activated:Connect(function() journal.Visible=not journal.Visible refresh() end)

local intro=frame(screen,"Prologue",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Color3.fromRGB(8,18,28)) intro.BackgroundTransparency=0.88 intro.Visible=false
local introKicker=text(intro,"Kicker",Chapter.Dialogues.ArrivalTitles[1],13,UDim2.fromScale(0.1,0.12),UDim2.fromScale(0.8,0.1),amber)
local introText=text(intro,"Story","",24,UDim2.fromScale(0.1,0.62),UDim2.fromScale(0.8,0.15)) introText.Font=Enum.Font.GothamSemibold
local introNext=button(intro,"Next","CONTINUAR",UDim2.fromScale(0.35,0.76),UDim2.fromScale(0.3,0.12))
local introSkip=button(intro,"Skip","PULAR INTRODUÇÃO",UDim2.fromScale(0.3,0.91),UDim2.fromScale(0.4,0.065),ink) introSkip.TextSize=11
local introPage=1
local cameraTween: Tween?=nil
local cinematic: any=nil
local function finishIntro()
	introDone=true intro.Visible=false
	if cinematic then cinematic.stop() cinematic=nil end
	if cameraTween then cameraTween:Cancel() end
	local camera=workspace.CurrentCamera
	if camera then camera.CameraType=Enum.CameraType.Custom local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid") if h then camera.CameraSubject=h end end
	refresh()
end
introSkip.Activated:Connect(finishIntro)
introNext.Activated:Connect(function() if cinematic then cinematic.next() end end)
local function beginIntro()
	introStarted=true intro.Visible=true introText.Text=Chapter.Dialogues.Arrival[1]
	cinematic=require(ReplicatedStorage.Shared.ArrivalCinematic).start(function(page)
		introPage=page introText.Text=Chapter.Dialogues.Arrival[page] introKicker.Text=Chapter.Dialogues.ArrivalTitles[page]
	end,finishIntro)
end

local bloom=Instance.new("BloomEffect") bloom.Name="PortalPerdidoBloom" bloom.Intensity=0.14 bloom.Size=18 bloom.Threshold=1.7 bloom.Parent=Lighting
-- Luz, atmosfera e céu da região onde a câmera está (depois do prólogo).
require(ReplicatedStorage.Shared.RegionAtmosphere).start(function() return introDone end)
local function layout()
	local available=screen.AbsoluteSize
	local touch=UIS.TouchEnabled and UIS.PreferredInput~=Enum.PreferredInput.Gamepad
	local compact=touch and available.Y<450
	card.Size=UDim2.fromOffset(if compact then math.min(460,available.X-24) else 460,if compact then 256 else 350)
	cardScale.Scale=if compact then math.min(1,(available.Y-16)/256) else math.clamp(math.min((available.X-24)/460,(available.Y-24)/350),0.2,1)
	local title=card:FindFirstChild("Title") :: TextLabel
	local subtitle=card:FindFirstChild("Subtitle") :: TextLabel
	local footer=card:FindFirstChild("Footer") :: TextLabel
	title.Position=UDim2.fromOffset(18,if compact then 8 else 15)
	title.Size=UDim2.new(1,-36,0,if compact then 40 else 57)
	title.TextSize=if compact then 18 else 21
	subtitle.Position=UDim2.fromOffset(20,if compact then 48 else 77)
	subtitle.Size=UDim2.new(1,-40,0,if compact then 32 else 43)
	subtitle.TextSize=if compact then 12 else 13
	footer.Visible=not compact
	for i,b in classButtons do
		local column=(i-1)%2
		local row=(i-1)//2
		b.Position=UDim2.new(column*0.5,if column==0 then 18 else 5,0,(if compact then 84 else 124)+row*(if compact then 55 else 62))
		b.Size=UDim2.new(0.5,-23,0,if compact then 50 else 56)
		b.TextSize=if compact then 11 else 12
	end
	hud.Size=UDim2.new(if compact then 0.72 else 0.92,0,0,if compact then 76 else 96)
	hud:FindFirstChildOfClass("UISizeConstraint").MaxSize=Vector2.new(if compact then 390 else 510,96)
	heading.Position=UDim2.fromOffset(12,if compact then 4 else 7)
	objective.Position=UDim2.fromOffset(12,if compact then 22 else 28)
	objective.Size=UDim2.new(1,-24,0,if compact then 28 else 39)
	objective.TextSize=if compact then 13 else 14
	hpBG.Position=UDim2.new(0.04,0,0,if compact then 64 else 78)
	hpText.Position=UDim2.new(0.04,0,0,if compact then 50 else 64)
	coins.Position=UDim2.new(0.6,0,0,if compact then 46 else 62)
	boss.Position=UDim2.new(0.5,0,0,if compact then 90 else 116)
	boss.Size=UDim2.new(if compact then 0.48 else 0.86,0,0,40)
	continueButton.Size=UDim2.fromOffset(138,if touch then 44 else 32)
	continueButton.Position=UDim2.new(1,-156,1,if touch then -52 else -45)
	journal.Close.Size=UDim2.fromOffset(if touch then 44 else 32,if touch then 44 else 30)
	journal.Close.Position=UDim2.new(1,if touch then -52 else -46,0,8)
	audioToggle.Position=UDim2.new(0.07,0,1,-52)
	audioToggle.Size=UDim2.new(0.45,0,0,44)
	controlsButton.Position=UDim2.new(0.55,0,1,-52)
	controlsButton.Size=UDim2.new(0.38,0,0,44)
	journalDetails.Position=UDim2.fromScale(0.07,0.65)
	journalDetails.Size=UDim2.fromScale(0.86,0.12)
	for i,entry in entries do entry.Position=UDim2.new(0.07,0,0.17+(i-1)*0.09,0) entry.Size=UDim2.new(0.86,0,0.085,0) end
	ending.Explore.Position=UDim2.new(0.15,0,1,-54)
	ending.Explore.Size=UDim2.new(0.7,0,0,44)
	ending.Title.TextSize=if compact then 24 else 30
	ending.Epilogue.Position=UDim2.fromScale(0.1,if compact then 0.46 else 0.5)
	ending.Epilogue.Size=UDim2.fromScale(0.8,if compact then 0.27 else 0.28)
	ending.Epilogue.TextSize=if compact then 14 else 16
	introNext.Position=UDim2.new(0.35,0,1,-104)
	introNext.Size=UDim2.new(0.3,0,0,44)
	introSkip.Position=UDim2.new(0.3,0,1,-52)
	introSkip.Size=UDim2.new(0.4,0,0,44)
	bloom.Enabled=not touch
	attackButton.Position=if touch then UDim2.new(1,-140,1,-124) else UDim2.new(1,-174,1,-90)
	attackButton.Size=if touch then UDim2.fromOffset(120,54) else UDim2.fromOffset(150,60)
	skillButton.Position=if touch then UDim2.new(1,-250,1,-124) else UDim2.new(1,-290,1,-90)
	skillButton.Size=UDim2.fromOffset(100,54)
	dashButton.Position=if touch then UDim2.new(1,-120,1,-180) else UDim2.new(1,-174,1,-142)
	dashButton.Size=if touch then UDim2.fromOffset(100,48) else UDim2.fromOffset(150,42)
	blockButton.Position=if touch then UDim2.new(1,-230,1,-180) else UDim2.new(1,-290,1,-142)
	blockButton.Size=if touch then UDim2.fromOffset(100,48) else UDim2.fromOffset(106,42)
	blockButton.Text=if touch then "DEFENDER" else "DEFENDER [F]"
	kickButton.Position=if touch then UDim2.new(1,-120,1,-236) else UDim2.new(1,-174,1,-194)
	kickButton.Size=if touch then UDim2.fromOffset(100,48) else UDim2.fromOffset(150,44)
	crouchButton.Position=if touch then UDim2.new(1,-230,1,-236) else UDim2.new(1,-290,1,-194)
	crouchButton.Size=if touch then UDim2.fromOffset(100,48) else UDim2.fromOffset(106,44)
	crouchButton.Text=if touch then "AGACHAR" else "AGACHAR [CTRL]"
	jumpButton.Position=UDim2.new(1,-140,1,-64)
	jumpButton.Size=UDim2.fromOffset(120,50)
	-- Layout salvo pelo jogador (só no toque) sobrepõe o padrão acima.
	Controls.apply(touch)
	attackButton.Text=if touch then "ATACAR" else "ATACAR [Q]"
	journalButton.Text=if touch then "DIÁRIO" else "DIÁRIO [J]"
	journalButton.Size=UDim2.fromOffset(100,if touch then 44 else 32)
	journalButton.Position=if touch then UDim2.new(0.5,-50,1,-52) else UDim2.new(1,-110,0,112)
	introText.TextSize=if available.Y<450 then 18 else 24
	speech.TextSize=if available.Y<450 then 14 else 16
	if refresh then refresh() end
end
screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
UIS:GetPropertyChangedSignal("PreferredInput"):Connect(layout)
-- Celular: respeita entalhes/barras do aparelho e registra os botões configuráveis.
screen.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets
Controls.init(screen,saveControlsRemote)
for id,b in {Attack=attackButton,Skill=skillButton,Kick=kickButton,Jump=jumpButton,Dash=dashButton,Crouch=crouchButton,Block=blockButton} do Controls.register(id,b) end
Controls.onChanged=layout
layout()

local humanoid: Humanoid?=nil
local healthConnection: RBXScriptConnection?=nil
local function updateHealth()
	if not humanoid then return end
	hpFill.Size=UDim2.fromScale(math.clamp(humanoid.Health/math.max(humanoid.MaxHealth,1),0,1),1)
	hpText.Text="VIDA "..math.ceil(humanoid.Health).." / "..humanoid.MaxHealth
	local shield=player:GetAttribute("ShieldUntil")
	hpFill.BackgroundColor3=if typeof(shield)=="number" and shield>workspace:GetServerTimeNow() then teal else Color3.fromRGB(104,170,135)
end
local function bindCharacter(character: Model)
	if healthConnection then healthConnection:Disconnect() end
	local h=character:WaitForChild("Humanoid",10)
	if h and h:IsA("Humanoid") then humanoid=h healthConnection=h.HealthChanged:Connect(updateHealth) updateHealth() end
	if introDone then local camera=workspace.CurrentCamera if camera and humanoid then camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=humanoid end end
end
player.CharacterAdded:Connect(bindCharacter)
if player.Character then task.spawn(bindCharacter,player.Character) end

-- Direção da esquiva: para onde o jogador está andando (vazio = passo para trás, no servidor).
local function dodgeDirection(): Vector3
	local move=if humanoid then humanoid.MoveDirection else Vector3.zero
	return Vector3.new(move.X,0,move.Z)
end
local lastAttack=-math.huge
local crouching=false
local jumpPressedAt=-math.huge
local function airborneNow(): boolean
	if not humanoid then return false end
	local state=humanoid:GetState()
	return state==Enum.HumanoidStateType.Freefall or state==Enum.HumanoidStateType.Jumping
end
local function setCrouch(active: boolean)
	if Controls.editing then active=false end
	if active and (not humanoid or humanoid.Health<=0 or dialogue.Visible or journal.Visible or intro.Visible or ending.Visible) then active=false end
	if crouching==active then return end
	crouching=active
	crouchButton.BackgroundColor3=if active then Color3.fromRGB(96,84,60) else ink
	crouchRemote:FireServer(active)
end
-- O servidor zera o agachamento ao renascer: mantém o estado local alinhado.
player:GetAttributeChangedSignal("Crouching"):Connect(function()
	if player:GetAttribute("Crouching")~=true and crouching then crouching=false crouchButton.BackgroundColor3=ink end
end)
-- Pular levanta do agachamento e marca o instante para o combo pulo + chute.
UIS.JumpRequest:Connect(function()
	jumpPressedAt=os.clock()
	if crouching then setCrouch(false) end
end)
local function attack()
	if Controls.editing then return end
	local id=player:GetAttribute("ClassId")
	local class=if typeof(id)=="string" then Classes[id] else nil
	if not class or not humanoid or humanoid.Health<=0 or dialogue.Visible or journal.Visible or intro.Visible or ending.Visible then return end
	if os.clock()-lastAttack<class.cooldown then return end
	-- Lutador: pular + atacar = Martelo Solar; agachado + atacar = Gancho Ascendente.
	-- O servidor confirma o estado (no ar / agachado) antes de aplicar a variante.
	local variant=nil
	if id=="Brawler" then variant=if crouching then "low" elseif airborneNow() then "air" else nil end
	lastAttack=os.clock() attackRemote:FireServer(variant)
	attackButton.BackgroundColor3=Color3.fromRGB(103,67,57)
	task.delay(class.cooldown,function() attackButton.BackgroundColor3=Color3.fromRGB(169,89,65) end)
end
attackButton.Activated:Connect(attack)
-- Chute: em pé = frontal; pulando (ou pulo + chute juntos) = chute voador; agachado = rasteira.
local kickPending=false
local function lunge()
	-- Chute voador: impulso à frente no próprio personagem (física do cliente).
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		local look=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
		if look.Magnitude>0.1 then
			local v=root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity=Vector3.new(look.Unit.X*30,math.max(v.Y,6),look.Unit.Z*30)
		end
	end
end
local function kick()
	if Controls.editing then return end
	if kickPending or not humanoid or humanoid.Health<=0 or dialogue.Visible or journal.Visible or intro.Visible or ending.Visible then return end
	if crouching then kickRemote:FireServer("sweep") return end
	if airborneNow() then kickRemote:FireServer("jump") lunge() return end
	kickPending=true
	task.spawn(function()
		-- Janela curta para "pular junto com chutar" (em qualquer ordem).
		local started=os.clock()
		while os.clock()-started<0.12 and os.clock()-jumpPressedAt>0.3 do task.wait() end
		if os.clock()-jumpPressedAt<=0.3 then
			local waitStart=os.clock()
			while not airborneNow() and os.clock()-waitStart<0.3 do task.wait() end
			if airborneNow() then kickRemote:FireServer("jump") lunge() else kickRemote:FireServer("front") end
		else
			kickRemote:FireServer("front")
		end
		kickPending=false
	end)
end
kickButton.Activated:Connect(kick)
crouchButton.Activated:Connect(function() setCrouch(not crouching) end)
-- Pular pelo botão próprio: mesmo efeito do pulo nativo (inclui o combo pulo + chute).
jumpButton.InputBegan:Connect(function(input)
	if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
	if Controls.editing or not humanoid or humanoid.Health<=0 then return end
	jumpPressedAt=os.clock()
	if crouching then setCrouch(false) return end
	humanoid.Jump=true
end)
-- Esconde o botão de pulo padrão do Roblox no toque (o nosso entra no layout configurável).
local function hideDefaultJump(touchGui: Instance)
	local jump=touchGui:FindFirstChild("JumpButton",true)
	if jump and jump:IsA("GuiObject") then
		jump.Visible=false
		jump:GetPropertyChangedSignal("Visible"):Connect(function() if jump.Visible then jump.Visible=false end end)
	end
end
task.spawn(function()
	local touchGui=gui:WaitForChild("TouchGui",30)
	if not touchGui then return end
	hideDefaultJump(touchGui)
	touchGui.DescendantAdded:Connect(function(item) if item.Name=="JumpButton" then task.defer(hideDefaultJump,touchGui) end end)
end)
skillButton.Activated:Connect(function() if not Controls.editing and not dialogue.Visible and not journal.Visible then skillRemote:FireServer() end end)
dashButton.Activated:Connect(function() if not Controls.editing and not dialogue.Visible and not journal.Visible then dashRemote:FireServer(dodgeDirection()) end end)
local blocking=false
local function setBlock(active: boolean)
	if Controls.editing then active=false end
	if active and (dialogue.Visible or journal.Visible or intro.Visible or player:GetAttribute("ClassId")~="Guardian") then active=false end
	if blocking==active then return end
	blocking=active
	blockButton.BackgroundColor3=if active then Color3.fromRGB(86,128,201) else Color3.fromRGB(46,72,128)
	blockRemote:FireServer(active)
end
blockButton.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then setBlock(true) end
end)
blockButton.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then setBlock(false) end
end)
-- Abre o editor dos controles de toque (depois de setBlock/setCrouch existirem).
controlsButton.Activated:Connect(function()
	journal.Visible=false
	setCrouch(false) setBlock(false)
	Controls.openEditor()
	refresh()
end)
UIS.InputEnded:Connect(function(input)
	if input.KeyCode==Enum.KeyCode.F then setBlock(false) end
	if input.KeyCode==Enum.KeyCode.LeftControl or input.KeyCode==Enum.KeyCode.ButtonL3 then setCrouch(false) end
end)
UIS.InputBegan:Connect(function(input,processed)
	if processed then return end
	if input.KeyCode==Enum.KeyCode.Q then attack()
	elseif input.KeyCode==Enum.KeyCode.C then kick()
	elseif input.KeyCode==Enum.KeyCode.R then if not dialogue.Visible and not intro.Visible and not journal.Visible then skillRemote:FireServer() end
	elseif input.KeyCode==Enum.KeyCode.LeftShift then if not intro.Visible and not dialogue.Visible and not journal.Visible then dashRemote:FireServer(dodgeDirection()) end
	elseif input.KeyCode==Enum.KeyCode.F then setBlock(true)
	elseif input.KeyCode==Enum.KeyCode.LeftControl or input.KeyCode==Enum.KeyCode.ButtonL3 then setCrouch(true)
	elseif input.KeyCode==Enum.KeyCode.J and introDone then journal.Visible=not journal.Visible refresh() end
end)

refresh=function()
	local index=player:GetAttribute("QuestIndex")
	local ready=typeof(index)=="number"
	loading.Visible=not ready
	if not ready then return end
	if not introStarted then if index>1 then introStarted=true introDone=true else beginIntro() end end
	local classId=player:GetAttribute("ClassId")
	local selected=typeof(classId)=="string" and Classes[classId]~=nil
	card.Visible=introDone and not selected
	local gameplay=introDone and selected
	hud.Visible=gameplay and not ending.Visible
	journalButton.Visible=gameplay and not dialogue.Visible and not ending.Visible
	local controls=gameplay and not dialogue.Visible and not journal.Visible and not ending.Visible
	attackButton.Visible=controls skillButton.Visible=controls dashButton.Visible=controls
	kickButton.Visible=controls
	crouchButton.Visible=controls
	if not controls then setCrouch(false) end
	blockButton.Visible=controls and classId=="Guardian"
	-- Pulo próprio só no toque (o padrão do Roblox fica escondido para não sobrepor o layout).
	local touchNow=UIS.TouchEnabled and UIS.PreferredInput~=Enum.PreferredInput.Gamepad
	jumpButton.Visible=controls and touchNow
	-- No editor todos os botões configuráveis aparecem (inclusive Defender e Pular).
	if Controls.editing then for _,b in {attackButton,skillButton,dashButton,kickButton,crouchButton,blockButton,jumpButton} do b.Visible=true end end
	if not blockButton.Visible then setBlock(false) end
	if index<=5 then
		heading.Text="MISSÃO "..index.." / 5 · "..Chapter.Quests[index].title
		objective.Text=Chapter.Quests[index].objective..(if index==3 then "  ("..tostring(player:GetAttribute("RuneCount") or 0).."/3)" elseif index==4 then "  ("..tostring(player:GetAttribute("SealProgress") or 0).."/3)" else "")
		if index==5 and player:GetAttribute("BossDefeated")==true then
			objective.Text="Recolha o Fragmento da Aurora no altar do santuário."
		end
		if not workspace:GetAttribute("ExpeditionStarted") then
			local ends=workspace:GetAttribute("ExpeditionGatherEndsAt")
			local left=if typeof(ends)=="number" then math.max(0,math.ceil(ends-workspace:GetServerTimeNow())) else nil
			objective.Text="Reunindo viajantes: "..tostring(workspace:GetAttribute("ExpeditionReadyPlayers") or 0).." pronto(s)"..(if left then " · a travessia começa em "..left.." s" else "").." (1–3: jornada · 4–6: expedição)"
		end
	else heading.Text="A TRAVESSIA · CONCLUÍDA" objective.Text="O Fragmento da Aurora está seguro. Explore o vale ou retorne a Ilyra." end
	coins.Text="Moedas: "..tostring(player:GetAttribute("Coins") or 0).."\n"..(if player:GetAttribute("DataStatus")=="Saved" then "Salvo" elseif player:GetAttribute("DataStatus")=="StudioMemory" then "Progresso temporário" else "Não salvo")
	for i,q in Chapter.Quests do entries[i].Text=(if index>i then "CONCLUÍDA   " elseif index==i then "EM CURSO   " else "A SEGUIR   ")..q.title entries[i].TextColor3=if index>i then teal elseif index==i then amber else Color3.fromRGB(130,151,160) end
	local status=player:GetAttribute("DataStatus")
	local saving=if status=="Saved" then "Progresso salvo." elseif status=="Pending" then "Aguardando salvamento automático…" elseif status=="StudioMemory" then "Studio: progresso temporário desta sessão." elseif status=="Loading" then "Carregando progresso…" else "Salvamento indisponível; progresso temporário."
	journalDetails.Text="Inscrições: "..tostring(player:GetAttribute("RuneCount") or 0).."/3  ·  Fragmento: "..(if player:GetAttribute("HasFragment") then "adquirido" else "não adquirido").."\n"..saving
	updateHealth()
end
for _, attribute in {"ClassId","QuestIndex","Coins","RuneCount","SealProgress","HasFragment","DataStatus","ShieldUntil","BossDefeated"} do player:GetAttributeChangedSignal(attribute):Connect(refresh) end
workspace:GetAttributeChangedSignal("ExpeditionStarted"):Connect(refresh)
workspace:GetAttributeChangedSignal("ExpeditionReadyPlayers"):Connect(refresh)
-- Contagem da janela de reunião antes da travessia.
task.spawn(function() while true do task.wait(1) if not workspace:GetAttribute("ExpeditionStarted") then refresh() end end end)

FX.init()
require(ReplicatedStorage.Shared.ObjectiveGuide).init()
require(ReplicatedStorage.Shared.CollectedPresentation).init()
require(ReplicatedStorage.Shared.AvatarFallback).init()
require(ReplicatedStorage.Shared.ActorPresentation).init()
notify.OnClientEvent:Connect(function(data)
	if typeof(data)~="table" then return end
	if data.kind=="dialogue" then
		setPortrait(data.speaker=="ILYRA")
		pages=data.lines page=1 speaker.Text=data.speaker speech.Text=pages[1] continueButton.Text=if #pages==1 then "CONCLUIR" else "CONTINUAR" dialogue.Visible=true journal.Visible=false refresh()
	elseif data.kind=="ending" then pendingEnding=true if not dialogue.Visible then pendingEnding=false ending.Visible=true refresh() end
	elseif data.kind=="toast" or data.kind=="bossPhase" then showToast(data.text)
	elseif data.kind=="quest" then Audio.quest() showToast(data.text..(if data.coins>0 then "  +"..data.coins.." moedas" else ""))
	elseif data.kind=="hurt" then if data.shielded then showToast("ÉGIDE: dano reduzido") end
	elseif data.kind=="finale" then
		-- Fim da campanha (Regente vencido na fase 6): a mesma tela de conclusão, com o epílogo final.
		ending.Chapter.Text="CAMPANHA CONCLUÍDA"
		ending.Title.Text="O PORTAL\nPRIMORDIAL"
		ending.Epilogue.Text="O Regente do Vazio se desfaz em poeira violeta. Pela primeira vez, o Portal Primordial se abre — e, do outro lado, as luzes do ginásio piscam.\n\nMas a coroa caída ainda pulsa no chão do átrio. Algo no vazio continua acordado."
		pendingEnding=true if not dialogue.Visible then pendingEnding=false ending.Visible=true refresh() end
	elseif data.kind=="vision" then
		-- Visão do Regente do Vazio depois do chefe final de uma região.
		local Vision=require(ReplicatedStorage.Shared.RegentVision)
		if data.style=="rift" and typeof(data.center)=="Vector3" then Vision.rift(data.center)
		elseif typeof(data.region)=="string" then Vision.flashback(data.region) end
	else
		FX.play(data)
		if data.kind=="impact" then local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart") if root and root:IsA("BasePart") and (root.Position-data.position).Magnitude<55 then Audio.impact() end end
	end
end)

local uiElapsed=0
RunService.RenderStepped:Connect(function(dt)
	uiElapsed+=dt if uiElapsed<0.1 then return end uiElapsed=0
	local id=player:GetAttribute("ClassId")
	local class=if typeof(id)=="string" then Classes[id] else nil
	if class then
		local kickTime=math.max(0,(player:GetAttribute("KickReadyAt") or 0)-workspace:GetServerTimeNow())
		kickButton.Text=if kickTime>0 then "CHUTE "..math.ceil(kickTime).." s" elseif UIS.PreferredInput==Enum.PreferredInput.Touch then "CHUTAR" else "CHUTAR [C]"
		local remaining=math.max(0,(player:GetAttribute("SkillReadyAt") or 0)-workspace:GetServerTimeNow())
		skillButton.Text=class.skillName..(if remaining>0 then "\n"..math.ceil(remaining).." s" elseif UIS.PreferredInput==Enum.PreferredInput.Touch then "" else " [R]")
		skillButton.BackgroundColor3=if remaining>0 then Color3.fromRGB(55,67,76) else Color3.fromRGB(43,106,115)
	end
	local dashTime=math.max(0,(player:GetAttribute("DashReadyAt") or 0)-workspace:GetServerTimeNow())
	dashButton.Text=if dashTime>0 then "ESQUIVA "..math.ceil(dashTime).." s" elseif UIS.PreferredInput==Enum.PreferredInput.Touch then "ESQUIVA" else "ESQUIVA [SHIFT]"
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local enemyFolder=workspace:FindFirstChild("PortalEnemies")
	local guardian=enemyFolder and enemyFolder:FindFirstChild("RootGuardian")
	-- Colossos (Arauto e chefões das regiões 2–4) marcados com BossBar pelo servidor.
	local colossus: Model?=nil
	if enemyFolder and root and root:IsA("BasePart") then
		for _,model in enemyFolder:GetChildren() do
			if model:IsA("Model") and model:GetAttribute("BossBar")==true and model.PrimaryPart and (model:GetAttribute("Health") or 0)>0
				and (root.Position-model.PrimaryPart.Position).Magnitude<70 then colossus=model break end
		end
	end
	local nearGuardian=player:GetAttribute("QuestIndex")==5 and root~=nil and root:IsA("BasePart") and root.Position.Z< -485 and root.Position.X>-500 and root.Position.X<500 and guardian~=nil and (guardian:GetAttribute("Health") or 0)>0
	boss.Visible=hud.Visible and (nearGuardian or colossus~=nil)
	local current=colossus or guardian
	if boss.Visible and current then
		local hp=current:GetAttribute("Health") or 0 local max=current:GetAttribute("MaxHealth") or 1
		local title=if colossus then tostring(colossus:GetAttribute("BossTitle") or "") else "GUARDIÃO DE RAÍZES"
		bossText.Text=title.." · FASE "..tostring(current:GetAttribute("Phase")).."  "..hp.." / "..max
		bossFill.Size=UDim2.new(0.94*hp/math.max(max,1),0,0,6)
	end
	updateHealth()
end)

if RunService:IsStudio() then
	local count=0
	UIS.InputBegan:Connect(function(input,processed)
		if not table.find({Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Space},input.KeyCode) or count>=12 then return end
		count+=1 local character=player.Character local root=character and character:FindFirstChild("HumanoidRootPart")
		local focused=UIS:GetFocusedTextBox()
		print("[PortalPerdido][MovementDebug]",input.KeyCode.Name,"Processed="..tostring(processed),"MenuOpen="..tostring(GuiService.MenuIsOpen),"FocusedTextBox="..(if focused then focused:GetFullName() else "none"))
		if root and root:IsA("BasePart") then
			local before=root.Position
			task.delay(0.35,function() if root.Parent and player.Character==character then print("[PortalPerdido][MovementDebug] AfterInput Delta="..tostring(root.Position-before),"RootAnchored="..tostring(root.Anchored),"WalkSpeed="..tostring(if humanoid then humanoid.WalkSpeed else 0)) end end)
		end
	end)
end
layout() refresh()
