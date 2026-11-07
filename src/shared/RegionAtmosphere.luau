--!strict
-- Cliente: luz, atmosfera, nuvens, correção de cor e céu de cada região (Config/Campaign).
-- Tudo local: o servidor mantém a luz do Vale; cada cliente aplica a da região onde a câmera está.
-- Elementos de céu (eclipse, galáxia, aurora) são peças locais que acompanham a câmera,
-- para parecerem infinitamente distantes sem depender do streaming.
local Lighting=game:GetService("Lighting")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Players=game:GetService("Players")
local Campaign=require(script.Parent.Config.Campaign)

local Atmosphere={}

local C=Color3.fromRGB

local function neon(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,transparency: number,shape: Enum.PartType?): Part
	local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color
	p.Material=Enum.Material.Neon p.Transparency=transparency p.Shape=shape or Enum.PartType.Block
	p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
	p.Parent=parent
	return p
end

-- Disco voltado para a câmera (cilindro com eixo na direção `dir`).
local function facing(dir: Vector3,distance: number): CFrame
	local p=dir.Unit*distance
	return CFrame.lookAt(p,Vector3.zero)*CFrame.Angles(0,math.pi/2,0)
end

local function eclipse(parent: Model,dir: Vector3,size: number,corona: Color3)
	-- Perto da câmera (escala proporcional) para a névoa da Atmosphere não clarear o disco.
	local distance=300
	local radius=size*distance/650
	local base=facing(dir,distance)
	neon(parent,"EclipseHalo",Vector3.new(0.5,radius*3.4,radius*3.4),base*CFrame.new(-6,0,0),corona,0.86,Enum.PartType.Cylinder)
	neon(parent,"EclipseCorona",Vector3.new(0.5,radius*2.35,radius*2.35),base*CFrame.new(-4,0,0),corona,0.35,Enum.PartType.Cylinder)
	neon(parent,"EclipseRim",Vector3.new(0.5,radius*2.1,radius*2.1),base*CFrame.new(-2,0,0),corona:Lerp(Color3.new(1,1,1),0.5),0.1,Enum.PartType.Cylinder)
	local disc=Instance.new("Part") disc.Name="EclipseDisc" disc.Shape=Enum.PartType.Cylinder
	disc.Size=Vector3.new(0.5,radius*2,radius*2) disc.CFrame=base disc.Color=C(10,6,18) disc.Material=Enum.Material.SmoothPlastic
	disc.Anchored=true disc.CanCollide=false disc.CanQuery=false disc.CanTouch=false disc.CastShadow=false disc.Parent=parent
end

local function galaxy(parent: Model,dir: Vector3,radius: number)
	local center=dir.Unit*640
	local frame=CFrame.lookAt(center,Vector3.zero)
	for arm=1,3 do
		for step=1,16 do
			local function point(t: number): Vector3
				local a=t*math.pi*2.2+arm*math.pi*2/3
				local r=radius*(0.1+t*0.9)
				return (frame*CFrame.new(math.cos(a)*r,math.sin(a)*r*0.55,0)).Position
			end
			local a,b=point((step-1)/16),point(step/16)
			local color=C(255,214,160):Lerp(C(170,120,255),step/16)
			neon(parent,"GalaxyArm",Vector3.new(radius*0.09*(1.2-step/16),radius*0.05,(b-a).Magnitude+2),CFrame.lookAt((a+b)/2,b),color,0.35+step/16*0.45)
		end
	end
	neon(parent,"GalaxyCore",Vector3.new(radius*0.35,radius*0.22,radius*0.35),frame,C(255,236,200),0.1,Enum.PartType.Ball)
end

local function moon(parent: Model,dir: Vector3,radius: number,color: Color3)
	local p=Instance.new("Part") p.Name="Moon" p.Shape=Enum.PartType.Ball p.Size=Vector3.one*radius*2
	p.CFrame=CFrame.new(dir.Unit*660) p.Color=color p.Material=Enum.Material.SmoothPlastic
	p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false p.Parent=parent
end

local function aurora(parent: Model)
	for band=1,3 do
		local y=180+band*40
		for k=0,17 do
			local a0=(k/18)*math.pi*1.3-math.pi*0.65+band*0.3
			local a1=((k+1)/18)*math.pi*1.3-math.pi*0.65+band*0.3
			local r=560-band*40
			local p0=Vector3.new(math.sin(a0)*r,y+math.sin(k*0.9+band)*18,-math.cos(a0)*r)
			local p1=Vector3.new(math.sin(a1)*r,y+math.sin((k+1)*0.9+band)*18,-math.cos(a1)*r)
			local color=if band==1 then C(110,240,200) elseif band==2 then C(150,170,255) else C(230,150,240)
			neon(parent,"AuroraRibbon",Vector3.new(0.5,30,(p1-p0).Magnitude+1),CFrame.lookAt((p0+p1)/2,p1),color,0.86)
		end
	end
end

local SKIES: {[string]: (Model) -> ()}={
	HourDesert=function(sky)
		galaxy(sky,Vector3.new(0.35,0.55,-1),150)
		moon(sky,Vector3.new(0.9,0.4,-0.6),34,C(236,206,220))
	end,
	EclipseCitadel=function(sky)
		eclipse(sky,Vector3.new(-0.3,0.4,-1),62,C(255,120,60))
	end,
	Convergence=function(sky)
		aurora(sky)
		moon(sky,Vector3.new(-0.7,0.35,-0.8),22,C(220,226,255))
	end,
	VoidDominion=function(sky)
		eclipse(sky,Vector3.new(-0.55,0.32,-1),70,C(255,140,64))
	end,
	CrystalAbyss=function(sky)
		moon(sky,Vector3.new(-0.8,0.45,-0.7),18,C(240,226,255))
	end,
}

local function tweenTo(region: Campaign.Region,seconds: number)
	local a=region.atmosphere
	local info=TweenInfo.new(seconds,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
	TweenService:Create(Lighting,info,{ClockTime=a.clock,Brightness=a.brightness,ExposureCompensation=a.exposure,Ambient=a.ambient,OutdoorAmbient=a.outdoor,GeographicLatitude=a.latitude}):Play()
	local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		TweenService:Create(atmosphere,info,{Density=a.density,Offset=a.offset,Color=a.color,Decay=a.decay,Haze=a.haze,Glare=a.glare}):Play()
	end
	local color=Lighting:FindFirstChild("PortalPerdidoColor")
	if color and color:IsA("ColorCorrectionEffect") then
		TweenService:Create(color,info,{TintColor=a.tint,Saturation=a.saturation,Contrast=a.contrast}):Play()
	end
	local clouds=workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		TweenService:Create(clouds,info,{Cover=a.cloudCover,Density=a.cloudDensity,Color=a.cloudColor}):Play()
	end
end

-- Faixa com o nome da região ao entrar nela.
local function banner(region: Campaign.Region)
	local gui=Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not gui then return end
	local old=gui:FindFirstChild("RegionBanner") if old then old:Destroy() end
	local screen=Instance.new("ScreenGui") screen.Name="RegionBanner" screen.DisplayOrder=12 screen.IgnoreGuiInset=true screen.ResetOnSpawn=false
	local title=Instance.new("TextLabel") title.AnchorPoint=Vector2.new(0.5,0.5) title.Position=UDim2.fromScale(0.5,0.31)
	title.Size=UDim2.new(0.9,0,0,46) title.BackgroundTransparency=1 title.Font=Enum.Font.GothamBold title.TextScaled=true
	title.TextColor3=C(246,236,214) title.TextStrokeTransparency=0.5 title.Text=region.name title.TextTransparency=1 title.Parent=screen
	local constraint=Instance.new("UITextSizeConstraint") constraint.MaxTextSize=40 constraint.Parent=title
	local sub=Instance.new("TextLabel") sub.AnchorPoint=Vector2.new(0.5,0.5) sub.Position=UDim2.new(0.5,0,0.31,40)
	sub.Size=UDim2.new(0.9,0,0,24) sub.BackgroundTransparency=1 sub.Font=Enum.Font.GothamMedium sub.TextScaled=true
	sub.TextColor3=C(220,206,180) sub.TextStrokeTransparency=0.6 sub.Text=region.subtitle sub.TextTransparency=1 sub.Parent=screen
	local subConstraint=Instance.new("UITextSizeConstraint") subConstraint.MaxTextSize=20 subConstraint.Parent=sub
	screen.Parent=gui
	local fadeIn=TweenInfo.new(0.8)
	TweenService:Create(title,fadeIn,{TextTransparency=0,TextStrokeTransparency=0.5}):Play()
	TweenService:Create(sub,fadeIn,{TextTransparency=0}):Play()
	task.delay(3.6,function()
		if not screen.Parent then return end
		local fadeOut=TweenInfo.new(1.2)
		TweenService:Create(title,fadeOut,{TextTransparency=1,TextStrokeTransparency=1}):Play()
		TweenService:Create(sub,fadeOut,{TextTransparency=1}):Play()
		task.delay(1.3,function() screen:Destroy() end)
	end)
end

-- `enabled()`: falso durante o prólogo (a cinemática controla câmera e cor).
function Atmosphere.start(enabled: () -> boolean)
	local currentId: string?=nil
	local sky: Model?=nil
	local elapsed=0
	RunService.RenderStepped:Connect(function(dt)
		local camera=workspace.CurrentCamera
		if not camera then return end
		if sky then sky:PivotTo(CFrame.new(camera.CFrame.Position)) end
		elapsed+=dt
		if elapsed<0.5 then return end
		elapsed=0
		if not enabled() then return end
		local region=Campaign.regionAt(camera.CFrame.Position)
		if region.id==currentId then return end
		local first=currentId==nil
		currentId=region.id
		tweenTo(region,if first then 0.01 else 2.5)
		if sky then sky:Destroy() sky=nil end
		local build=SKIES[region.id]
		if build then
			local model=Instance.new("Model") model.Name="RegionSky"
			build(model)
			model.WorldPivot=CFrame.identity
			model.Parent=camera
			sky=model
		end
		if not first or region.id~="Lumen" then banner(region) end
	end)
end

return Atmosphere
