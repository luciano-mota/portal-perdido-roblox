--!strict
-- Constrói as regiões 2–6 em suas origens (Config/Campaign) e o portal de saída do Vale.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Campaign=require(ReplicatedStorage.Shared.Config.Campaign)
local Chapter=require(ReplicatedStorage.Shared.Config.Chapter)
local Kit=require(script.Parent.RegionKit)
local folder=script.Parent:WaitForChild("regions")

local Regions={}

local BUILDERS={"CrystalAbyss","HourDesert","EclipseCitadel","Convergence","VoidDominion"}

function Regions.build(world: Model)
	-- Vale: portal de saída na arena suspensa, aceso só depois do Fragmento (TravelService).
	local arena=world:FindFirstChild("Arena")
	if arena then
		local base=Vector3.new(-30,Chapter.Relief.Arena,-568)
		local gate=Kit.travelGate(arena,"ExitGate",base,Vector3.new(0,0,-550)-Vector3.new(base.X,0,base.Z),7,Color3.fromRGB(126,128,137),Color3.fromRGB(76,201,205),"PASSAGEM DA AURORA","Desperta com o Fragmento")
		gate:SetAttribute("RegionId","Lumen")
	end
	for _,id in BUILDERS do
		local module=folder:FindFirstChild(id)
		local region=Campaign.get(id)
		if not module or not module:IsA("ModuleScript") or not region then
			warn("[PortalPerdido][Regions] Construtor ausente: "..id)
			continue
		end
		local started=os.clock()
		local ok,result=pcall(function()
			return (require(module) :: any).build(world,region.origin)
		end)
		if ok and typeof(result)=="Instance" and result:IsA("Model") then
			-- Como no Vale: a superfície suave dos voxels fica 2 studs acima do topo preenchido.
			-- Subir as peças alinha pisos, escadas e caminhos ao terreno.
			result:PivotTo(result:GetPivot()+Vector3.new(0,2,0))
		end
		if ok then
			print(string.format("[PortalPerdido] %s construída em %.1f s.",region.name,os.clock()-started))
		else
			warn("[PortalPerdido][Regions] Falha ao construir "..id..": "..tostring(result))
		end
		task.wait()
	end
end

return Regions
