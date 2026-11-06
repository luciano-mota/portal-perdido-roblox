--!strict
-- Um único marcador local; decisões de missão continuam no servidor.
local Players=game:GetService("Players")
local Chapter=require(script.Parent.Config.Chapter)
local Guide={}
local function livingEncounter(id: string,position: Vector3): Model?
	local enemies=workspace:FindFirstChild("PortalEnemies")
	if not enemies then return nil end
	local target: Model?=nil local nearest=math.huge
	for _,enemy in enemies:GetChildren() do
		if enemy:IsA("Model") and enemy.PrimaryPart and enemy:GetAttribute("EncounterGroup")==id and (enemy:GetAttribute("Health") or 0)>0 then
			local distance=(enemy.PrimaryPart.Position-position).Magnitude
			if distance<nearest then nearest=distance target=enemy end
		end
	end
	return target
end

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
			local humanoid=character and character:FindFirstChildOfClass("Humanoid")
			local target: BasePart?=nil
			local title=""
			local quest=player:GetAttribute("QuestIndex")
			if world and root and root:IsA("BasePart") and humanoid and humanoid.Health>0 and player:GetAttribute("ClassId") then
				if quest==1 then
					local village=world:FindFirstChild("Village")
					local npc=village and village:FindFirstChild("Ilyra")
					if npc and npc:IsA("Model") then target=npc.PrimaryPart title="CONVERSE COM ILYRA" end
				elseif quest==2 then
					local enemies=workspace:FindFirstChild("PortalEnemies")
					local leader=enemies and enemies:FindFirstChild("FirstSentinel")
					if leader and leader:GetAttribute("EncounterCleared") then
						local village=world:FindFirstChild("Village")
						local npc=village and village:FindFirstChild("Ilyra")
						if npc and npc:IsA("Model") then target=npc.PrimaryPart title="RETORNE A ILYRA" end
					else
						local enemy=livingEncounter("FirstSentinel",root.Position) or leader
						if enemy and enemy:IsA("Model") then target=enemy.PrimaryPart title=if (enemy:GetAttribute("Health") or 0)<=0 then "REFORÇOS A CAMINHO" elseif enemy.Name=="FirstSentinel" then "SENTINELA DE MUSGO" else "ELIMINE OS REFORÇOS" end
					end
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
				elseif quest==4 then
					local temple=world:FindFirstChild("Temple")
					local seals=temple and temple:FindFirstChild("Seals")
					local progress=player:GetAttribute("SealProgress")
					local index=if typeof(progress)=="number" then math.clamp(math.floor(progress)+1,1,3) else 1
					local seal=seals and seals:FindFirstChild(Chapter.SealOrder[index])
					local core=seal and seal:FindFirstChild("Core")
					if core and core:IsA("BasePart") then target=core title="SELO "..({"AURORA","RAIZ","ESTRELA"})[index] end
				elseif quest==5 then
					local arena=world:FindFirstChild("Arena")
					local inArena=root.Position.Z<Chapter.Relief.GateZ-3
					if not inArena then
						if humanoid.Health<humanoid.MaxHealth*0.7 and not player:GetAttribute("BossDefeated") then
							local shrines=world:FindFirstChild("RestShrines")
							local shrine=shrines and shrines:FindFirstChild("Temple")
							local core=shrine and shrine:FindFirstChild("Core")
							if core and core:IsA("BasePart") then target=core title="RECUPERE SUA VIDA" end
						else
							local temple=world:FindFirstChild("Temple")
							local gate=temple and temple:FindFirstChild("ArenaGate")
							if gate and gate:IsA("BasePart") then target=gate title="ATRAVESSE O LIMIAR" end
						end
					elseif player:GetAttribute("BossDefeated") then
						local fragment=arena and arena:FindFirstChild("AuroraFragment")
						if fragment and fragment:IsA("BasePart") then target=fragment title="RECOLHA O FRAGMENTO" end
					else
						local enemies=workspace:FindFirstChild("PortalEnemies")
						local boss=livingEncounter("RootGuardian",root.Position) or (enemies and enemies:FindFirstChild("RootGuardian"))
						if boss and boss:IsA("Model") then target=boss.PrimaryPart title=if boss.Name=="RootGuardian" then "GUARDIÃO DE RAÍZES" else "ELIMINE OS REFORÇOS" end
					end
				elseif typeof(quest)=="number" and quest>5 and root.Position.Z<Chapter.Relief.GateZ-3 then
					local arena=world:FindFirstChild("Arena")
					local stone=arena and arena:FindFirstChild("ReturnStone")
					if stone and stone:IsA("BasePart") then target=stone title="RETORNE AO VALE" end
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
