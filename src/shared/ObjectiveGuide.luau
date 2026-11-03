--!strict
-- Um único marcador local; decisões de missão continuam no servidor.
local Players=game:GetService("Players")
local Chapter=require(script.Parent.Config.Chapter)
local Guide={}

function Guide.init()
	local player=Players.LocalPlayer
	local gui=Instance.new("BillboardGui")
	gui.Name="PortalObjectiveGuide" gui.Size=UDim2.fromOffset(190,40)
	gui.StudsOffsetWorldSpace=Vector3.new(0,7,0)
	gui.AlwaysOnTop=true gui.MaxDistance=220 gui.Enabled=false
	gui.Parent=player:WaitForChild("PlayerGui") gui.ResetOnSpawn=false
	local text=Instance.new("TextLabel") text.Size=UDim2.fromScale(1,1)
	text.BackgroundTransparency=1 text.Font=Enum.Font.GothamSemibold
	text.TextSize=14 text.TextColor3=Color3.fromRGB(255,222,151)
	text.TextStrokeTransparency=0.25 text.Parent=gui
	task.spawn(function()
		while gui.Parent do
			local world=workspace:FindFirstChild("PortalChapter")
			local character=player.Character
			local root=character and character:FindFirstChild("HumanoidRootPart")
			local target: BasePart?=nil
			local title=""
			local quest=player:GetAttribute("QuestIndex")
			if world and root and root:IsA("BasePart") and player:GetAttribute("ClassId") then
				if quest==1 then
					local village=world:FindFirstChild("Village")
					local npc=village and village:FindFirstChild("Ilyra")
					if npc and npc:IsA("Model") then target=npc.PrimaryPart title="CONVERSE COM ILYRA" end
				elseif quest==2 then
					local enemies=workspace:FindFirstChild("PortalEnemies")
					local enemy=enemies and enemies:FindFirstChild("FirstSentinel")
					if enemy and enemy:IsA("Model") then target=enemy.PrimaryPart title="SENTINELA DE MUSGO" end
				elseif quest==3 then
					local runes=world:FindFirstChild("Runes")
					local nearest=math.huge
					for _,definition in Chapter.Runes do
						local rune=runes and runes:FindFirstChild(definition.id)
						local core=rune and rune:FindFirstChild("Core")
						if not player:GetAttribute("Rune"..definition.id) and core and core:IsA("BasePart") then
							local distance=(core.Position-root.Position).Magnitude
							if distance<nearest then nearest=distance target=core title=definition.name end
						end
					end
				end
			end
			gui.Adornee=target gui.Enabled=target~=nil
			if target and root and root:IsA("BasePart") then
				text.Text="◇ "..title
			end
			task.wait(0.5)
		end
	end)
end

return Guide
