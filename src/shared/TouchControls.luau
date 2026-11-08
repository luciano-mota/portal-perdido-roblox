--!strict
-- Controles de toque configuráveis (somente cliente/apresentação).
--   register(id, button): botão de ação que o jogador pode mover, redimensionar e esmaecer.
--   apply(touch): depois do layout padrão, aplica o layout salvo (só no toque).
--   openEditor(): modo de edição — arrastar botões, tamanho +/−, opacidade +/−, padrão, salvar.
-- O layout é validado e persistido pelo servidor (remote SaveControls → perfil → atributo
-- ControlLayout). Durante a edição `Controls.editing` é true e as ações não disparam.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local HttpService=game:GetService("HttpService")
local Layout=require(script.Parent.ControlLayout)

local Controls={}
Controls.editing=false
Controls.onChanged=nil :: (() -> ())?

local player=Players.LocalPlayer
local registry: {[string]: TextButton}={}
local saved: any=nil -- layout salvo (sanitizado)
local draft: any=nil -- layout em edição
local screen: ScreenGui?=nil
local saveRemote: RemoteEvent?=nil
local touchActive=false

local function readSaved()
	local raw=player:GetAttribute("ControlLayout")
	saved=nil
	if typeof(raw)=="string" then
		local ok,decoded=pcall(function() return HttpService:JSONDecode(raw) end)
		if ok then saved=Layout.sanitize(decoded) end
	end
end

function Controls.init(gui: ScreenGui,remote: RemoteEvent)
	screen=gui saveRemote=remote
	readSaved()
	player:GetAttributeChangedSignal("ControlLayout"):Connect(function()
		readSaved()
		if not Controls.editing and Controls.onChanged then Controls.onChanged() end
	end)
end

function Controls.register(id: string,button: TextButton)
	registry[id]=button
end

-- Base de cada botão no layout padrão (capturada antes de aplicar o personalizado).
local base: {[string]: {size: UDim2,position: UDim2,anchor: Vector2}}={}

local function styleOpacity(button: TextButton,opacity: number)
	button.BackgroundTransparency=1-opacity
	button.TextTransparency=(1-opacity)*0.6
end

local function place(id: string,button: TextButton,entry: any)
	local b=base[id]
	if not b then return end
	if entry then
		button.AnchorPoint=Vector2.new(0.5,0.5)
		button.Position=UDim2.fromScale(entry.x,entry.y)
		button.Size=UDim2.fromOffset(b.size.X.Offset*entry.s,b.size.Y.Offset*entry.s)
	else
		button.AnchorPoint=b.anchor button.Position=b.position button.Size=b.size
	end
end

-- Chamado ao fim do layout padrão (o padrão grava Position/Size; aqui sobrepõe se houver).
function Controls.apply(touch: boolean)
	touchActive=touch
	local layout=if Controls.editing then draft else saved
	for id,button in registry do
		if not Controls.editing then base[id]={size=button.Size,position=button.Position,anchor=button.AnchorPoint} end
		local entry=touch and layout and layout.buttons[id] or nil
		place(id,button,entry)
		styleOpacity(button,if touch and layout then layout.opacity else 1)
	end
end

-- Centro atual do botão em fração da tela.
local function centerOf(button: TextButton): (number,number)
	local size=(screen :: ScreenGui).AbsoluteSize
	local c=button.AbsolutePosition+button.AbsoluteSize/2
	return c.X/math.max(size.X,1),c.Y/math.max(size.Y,1)
end

local editorFrame: Frame?=nil
local connections: {RBXScriptConnection}={}
local selected: string?=nil

local function closeEditor(keep: boolean)
	for _,c in connections do c:Disconnect() end
	table.clear(connections)
	for _,button in registry do
		local stroke=button:FindFirstChild("EditStroke") if stroke then stroke:Destroy() end
		button.ZIndex=1
	end
	if editorFrame then editorFrame:Destroy() editorFrame=nil end
	Controls.editing=false
	selected=nil
	if not keep then draft=nil end
	if Controls.onChanged then Controls.onChanged() end
end

function Controls.openEditor()
	if Controls.editing or not screen then return end
	Controls.editing=true
	-- Rascunho: parte do layout salvo ou das posições atuais.
	draft={opacity=if saved then saved.opacity else 1,buttons={}}
	for id,button in registry do
		local entry=saved and saved.buttons[id]
		if entry then draft.buttons[id]={x=entry.x,y=entry.y,s=entry.s}
		else local x,y=centerOf(button) draft.buttons[id]={x=x,y=y,s=1} end
	end
	if Controls.onChanged then Controls.onChanged() end -- mostra todos os botões

	local gui=screen :: ScreenGui
	local overlay=Instance.new("Frame") overlay.Name="ControlEditor" overlay.Size=UDim2.fromScale(1,1)
	overlay.BackgroundColor3=Color3.fromRGB(6,14,22) overlay.BackgroundTransparency=0.45 overlay.ZIndex=40 overlay.Active=true overlay.Parent=gui
	editorFrame=overlay
	local bar=Instance.new("Frame") bar.Name="Toolbar" bar.AnchorPoint=Vector2.new(0.5,0) bar.Position=UDim2.new(0.5,0,0,10)
	bar.Size=UDim2.new(0.96,0,0,112) bar.BackgroundColor3=Color3.fromRGB(20,36,48) bar.ZIndex=41 bar.Parent=overlay
	local size=Instance.new("UISizeConstraint") size.MaxSize=Vector2.new(640,112) size.Parent=bar
	local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,10) corner.Parent=bar
	local hint=Instance.new("TextLabel") hint.BackgroundTransparency=1 hint.Size=UDim2.new(1,-16,0,34) hint.Position=UDim2.fromOffset(8,4)
	hint.Font=Enum.Font.Gotham hint.TextSize=13 hint.TextWrapped=true hint.TextColor3=Color3.fromRGB(239,231,210) hint.ZIndex=42 hint.Parent=bar
	local function refreshHint()
		hint.Text=if selected then "Selecionado: "..Layout.Labels[selected].." — arraste para mover; use TAMANHO para ajustar."
			else "Arraste os botões para onde preferir. Toque em um botão para selecioná-lo."
	end
	refreshHint()
	local grid=Instance.new("Frame") grid.BackgroundTransparency=1 grid.Size=UDim2.new(1,-16,0,68) grid.Position=UDim2.fromOffset(8,40) grid.ZIndex=42 grid.Parent=bar
	local list=Instance.new("UIGridLayout") list.SortOrder=Enum.SortOrder.LayoutOrder list.CellSize=UDim2.new(0.25,-6,0,30) list.CellPadding=UDim2.fromOffset(6,6) list.Parent=grid
	local order=0
	local function tool(label: string,color: Color3,action: () -> ())
		local b=Instance.new("TextButton") b.Name="Tool_"..(label:gsub("−","Menos"):gsub("%+","Mais"):gsub("[^%w]","")) b.Text=label b.Font=Enum.Font.GothamSemibold b.TextSize=12 b.TextWrapped=true
		order+=1 b.LayoutOrder=order
		b.TextColor3=Color3.fromRGB(239,231,210) b.BackgroundColor3=color b.ZIndex=43 b.Parent=grid
		local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,8) c.Parent=b
		b.Activated:Connect(action)
	end
	local function resize(delta: number)
		local targets=if selected then {selected} else Layout.Ids
		for _,id in targets do
			local entry=draft.buttons[id]
			if entry then entry.s=math.clamp(entry.s+delta,Layout.MinScale,Layout.MaxScale) end
		end
		Controls.apply(touchActive)
	end
	local slate=Color3.fromRGB(43,72,96)
	tool("TAMANHO −",slate,function() resize(-0.1) end)
	tool("TAMANHO +",slate,function() resize(0.1) end)
	tool("OPACIDADE −",slate,function() draft.opacity=math.clamp(draft.opacity-0.1,Layout.MinOpacity,1) Controls.apply(touchActive) end)
	tool("OPACIDADE +",slate,function() draft.opacity=math.clamp(draft.opacity+0.1,Layout.MinOpacity,1) Controls.apply(touchActive) end)
	tool("PADRÃO",Color3.fromRGB(110,74,52),function()
		-- Volta ao padrão do jogo (o servidor apaga o layout salvo).
		if saveRemote then saveRemote:FireServer(nil) end
		saved=nil
		closeEditor(false)
	end)
	tool("CANCELAR",Color3.fromRGB(70,70,80),function() closeEditor(false) end)
	tool("SALVAR",Color3.fromRGB(43,106,115),function()
		local clean=Layout.sanitize(draft)
		if clean and saveRemote then saveRemote:FireServer(clean) saved=clean end
		closeEditor(false)
	end)
	tool("TODOS",slate,function() selected=nil refreshHint() for _,b in registry do local s=b:FindFirstChild("EditStroke") if s then (s :: UIStroke).Color=Color3.fromRGB(230,185,110) end end end)

	-- Arrastar: toque/clique num botão seleciona e move; o centro segue o dedo, dentro da tela.
	local dragging: {input: InputObject?,id: string,start: Vector2,origin: Vector2}?=nil
	for id,button in registry do
		button.ZIndex=45
		local stroke=Instance.new("UIStroke") stroke.Name="EditStroke" stroke.Thickness=2 stroke.Color=Color3.fromRGB(230,185,110) stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border stroke.Parent=button
		table.insert(connections,button.InputBegan:Connect(function(input)
			if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
			selected=id refreshHint()
			for other,b in registry do local s=b:FindFirstChild("EditStroke") if s then (s :: UIStroke).Color=if other==id then Color3.fromRGB(120,230,255) else Color3.fromRGB(230,185,110) end end
			local entry=draft.buttons[id]
			local screenSize=gui.AbsoluteSize
			dragging={input=if input.UserInputType==Enum.UserInputType.Touch then input else nil,id=id,
				start=Vector2.new(input.Position.X,input.Position.Y),origin=Vector2.new(entry.x*screenSize.X,entry.y*screenSize.Y)}
		end))
	end
	table.insert(connections,UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		local isTouch=input.UserInputType==Enum.UserInputType.Touch
		if isTouch and dragging.input~=input then return end
		if not isTouch and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
		local screenSize=gui.AbsoluteSize
		local p=dragging.origin+(Vector2.new(input.Position.X,input.Position.Y)-dragging.start)
		local entry=draft.buttons[dragging.id]
		entry.x=math.clamp(p.X/math.max(screenSize.X,1),0.03,0.97)
		entry.y=math.clamp(p.Y/math.max(screenSize.Y,1),0.05,0.97)
		Controls.apply(touchActive)
	end))
	table.insert(connections,UIS.InputEnded:Connect(function(input)
		if not dragging then return end
		if input.UserInputType==Enum.UserInputType.Touch and dragging.input==input then dragging=nil
		elseif input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=nil end
	end))
	-- No editor vale o posicionamento livre mesmo fora do toque (testar no PC/emulador).
	Controls.apply(true)
end

return Controls
