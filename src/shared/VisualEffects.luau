--!strict
-- Apresentação local limitada; dano e áreas de impacto pertencem ao servidor.
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Players=game:GetService("Players")
local Art=require(script.Parent.Art)
local FX={}
local container: Folder

local function part(position: Vector3,color: Color3,size: Vector3,shape: Enum.PartType?,duration: number)
	local p=Art.part(container,"Effect",size,CFrame.new(position),color,Enum.Material.Neon,shape)
	p.CastShadow=false
	Debris:AddItem(p,duration)
	return p
end

local function ring(position: Vector3,radius: number,color: Color3,duration: number,warning: boolean?)
	local p=part(position,color,Vector3.new(0.08,radius*2,radius*2),Enum.PartType.Cylinder,duration+0.2)
	p.CFrame=CFrame.new(position)*CFrame.Angles(0,0,math.pi/2)
	p.Transparency=if warning then 0.7 else 0.4
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
		if actor and actor.Character then
			actor.Character:SetAttribute("PortalAttackStarted",os.clock())
			actor.Character:SetAttribute("PortalAttackClass",data.classId)
			actor.Character:SetAttribute("PortalAttackDuration",if data.classId=="Explorer" then 0.46 else 0.56)
		end
		if #container:GetChildren()>60 then return end
		if data.classId=="Guardian" then ring(data.position-Vector3.new(0,2.5,0),3,data.color,0.22)
		else
			local beam=Art.segment(container,"ArcaneTrail",data.origin,data.position,0.12,data.color,Enum.Material.Neon)
			beam.CastShadow=false
			TweenService:Create(beam,TweenInfo.new(0.22),{Transparency=1}):Play() Debris:AddItem(beam,0.3)
		end
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
		local orb=part(data.position,data.color,Vector3.new(2,2,2),Enum.PartType.Ball,0.6)
		TweenService:Create(orb,TweenInfo.new(0.5),{Size=Vector3.new(7,7,7),Transparency=1}):Play()
	end
end

return FX
