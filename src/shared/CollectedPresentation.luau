--!strict
-- Coleta por jogador: esconder localmente sem retirar o item dos companheiros.
local Players=game:GetService("Players")
local Presentation={}
function Presentation.init()
	local player=Players.LocalPlayer
	task.spawn(function()
		local world=workspace:WaitForChild("PortalChapter")
		local fragment=world:WaitForChild("Arena"):WaitForChild("AuroraFragment") :: BasePart
		local function refresh()
			local collected=player:GetAttribute("HasFragment")==true
			fragment.LocalTransparencyModifier=if collected then 1 else 0
			for _,item in fragment:GetDescendants() do
				if item:IsA("ProximityPrompt") or item:IsA("BillboardGui") or item:IsA("ParticleEmitter") or item:IsA("Light") then item.Enabled=not collected end
			end
		end
		player:GetAttributeChangedSignal("HasFragment"):Connect(refresh)
		fragment.DescendantAdded:Connect(refresh)
		refresh()
	end)
end
return Presentation
