--!strict
-- Prólogo 3D local: demonstração, ruptura e chegada. Não altera o mundo do servidor.
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Art=require(script.Parent.Art)
local Cinematic={}
local origin=Vector3.new(0,2000,0)
function Cinematic.start(onPage: (number) -> (),onFinish: () -> ())
	local scene=Instance.new("Model") scene.Name="PortalArrivalCinematic" scene.Parent=workspace
	local function block(name: string,size: Vector3,p: Vector3,color: Color3,material: Enum.Material)
		return Art.part(scene,name,size,CFrame.new(origin+p),color,material)
	end
	block("DemonstrationFloor",Vector3.new(72,1,72),Vector3.new(0,-0.5,0),Color3.fromRGB(36,43,56),Enum.Material.Metal)
	for _,x in {-36,36} do block("SideWall",Vector3.new(1,24,72),Vector3.new(x,12,0),Color3.fromRGB(24,31,44),Enum.Material.Metal) end
	block("Ceiling",Vector3.new(72,1,72),Vector3.new(0,24,0),Color3.fromRGB(28,36,49),Enum.Material.Metal)
	block("FrontWall",Vector3.new(72,24,1),Vector3.new(0,12,36),Color3.fromRGB(24,31,44),Enum.Material.Metal)
	block("LaboratoryWall",Vector3.new(56,20,1),Vector3.new(0,10,-22),Color3.fromRGB(23,32,49),Enum.Material.Metal)
	for _,x in {-24,24} do
		block("LaboratoryColumn",Vector3.new(2,20,2),Vector3.new(x,10,-15),Color3.fromRGB(67,83,98),Enum.Material.Metal)
		block("LaboratoryLight",Vector3.new(0.2,15,0.2),Vector3.new(x,10,-13.8),Color3.fromRGB(122,206,221),Enum.Material.Neon)
	end
	local portal=Art.portal(scene,origin+Vector3.new(0,0,-14),7)
	local rift=portal:FindFirstChild("Rift") :: BasePart
	rift.Transparency=0.8
	for _,x in {-11,11} do
		block("ControlConsole",Vector3.new(5,3,3),Vector3.new(x,1.5,-8),Color3.fromRGB(62,73,90),Enum.Material.Metal)
		block("ControlScreen",Vector3.new(4,0.15,2),Vector3.new(x,3.1,-8),Color3.fromRGB(69,161,180),Enum.Material.Neon)
	end
	local actors={}
	local previews=ReplicatedStorage:FindFirstChild("ClassPreviews")
	for i=1,6 do
		local template=previews and previews:FindFirstChild(({"Guardian","Explorer","Artificer"})[(i-1)%3+1])
		if template and template:IsA("Model") then
			local actor=template:Clone() actor.Name="Traveler"..i
			for _,item in actor:GetDescendants() do
				if item:IsA("Script") or item:IsA("LocalScript") or item:IsA("BillboardGui") then item:Destroy()
				elseif item:IsA("BasePart") then item.Anchored=true item.CanCollide=false item.CanTouch=false item.CanQuery=false end
			end
			actor.Parent=scene
			local p=origin+Vector3.new((i-3.5)*3.2,3.1,6+(i%2)*3)
			actor:PivotTo(CFrame.lookAt(p,origin+Vector3.new(0,3,-14)))
			table.insert(actors,{model=actor,start=p})
		end
	end
	local camera=workspace.CurrentCamera
	local savedFov=if camera then camera.FieldOfView else 70
	local page=1 local elapsed=0 local stopped=false
	local connection: RBXScriptConnection?=nil
	local function stop()
		if stopped then return end stopped=true
		if connection then connection:Disconnect() end
		scene:Destroy()
		if camera then camera.FieldOfView=savedFov end
	end
	local function setPage(index: number)
		page=index elapsed=0
		if index>3 then stop() onFinish() else onPage(index) end
	end
	onPage(1)
	connection=RunService.RenderStepped:Connect(function(dt)
		if stopped then return end
		elapsed+=dt
		if elapsed>=8 then setPage(page+1) return end
		if not camera then return end
		camera.CameraType=Enum.CameraType.Scriptable
		local t=elapsed/8
		if page==1 then
			camera.CFrame=CFrame.lookAt(origin+Vector3.new(23-5*t,12,25-4*t),origin+Vector3.new(0,5,-7))
			rift.Transparency=0.8-0.5*t
		elseif page==2 then
			camera.CFrame=CFrame.lookAt(origin+Vector3.new(-16+8*t,9,17-7*t),origin+Vector3.new(0,6,-14))
			rift.Transparency=0.12+math.sin(elapsed*6)*0.08
			rift.Size=Vector3.new(10.15,11.9,0.3)*(1+0.2*math.sin(elapsed*2)^2)
			for i,actor in actors do
				local progress=math.clamp((elapsed-i*0.35)/4,0,1)
				local p=actor.start:Lerp(origin+Vector3.new(0,6,-14),progress*progress)
				actor.model:PivotTo(CFrame.lookAt(p,origin+Vector3.new(0,6,-15))*CFrame.Angles(0,0,math.sin(elapsed*2+i)*0.15*progress))
			end
		else
			camera.CFrame=CFrame.lookAt(Vector3.new(45-22*t,25-14*t,68-21*t),Vector3.new(-35+35*t,8,-8+20*t))
		end
	end)
	return {stop=stop,next=function() if not stopped then setPage(page+1) end end}
end
return Cinematic
