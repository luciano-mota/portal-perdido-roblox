--!strict
-- Layout dos controles de toque configurável pelo jogador (posição, tamanho e opacidade).
-- Puro (sem serviços): usado pelo cliente (editor) e pelo servidor (validação e perfil).
-- Formato: {opacity=0.35..1, buttons={[id]={x=0..1, y=0..1, s=0.6..1.8}}}
--   x/y: centro do botão em fração da tela; s: multiplicador do tamanho padrão.
local Layout={}

-- Botões que o jogador pode mover/redimensionar (ordem usada no editor).
Layout.Ids={"Attack","Skill","Kick","Jump","Dash","Crouch","Block"}
Layout.Labels={Attack="ATACAR",Skill="HABILIDADE",Kick="CHUTAR",Jump="PULAR",Dash="ESQUIVA",Crouch="AGACHAR",Block="DEFENDER"}
Layout.MinScale=0.6
Layout.MaxScale=1.8
Layout.MinOpacity=0.35

local valid: {[string]: boolean}={}
for _,id in Layout.Ids do valid[id]=true end

local function finite(n: any): boolean
	return typeof(n)=="number" and n==n and n~=math.huge and n~=-math.huge
end

-- Devolve uma cópia limpa ou nil se o valor não for um layout válido.
function Layout.sanitize(value: any): any
	if typeof(value)~="table" then return nil end
	local clean={opacity=1,buttons={}}
	if value.opacity~=nil then
		if not finite(value.opacity) then return nil end
		clean.opacity=math.clamp(value.opacity,Layout.MinOpacity,1)
	end
	if value.buttons~=nil then
		if typeof(value.buttons)~="table" then return nil end
		for id,entry in value.buttons do
			if typeof(id)~="string" or not valid[id] or typeof(entry)~="table" then return nil end
			if not finite(entry.x) or not finite(entry.y) or not finite(entry.s) then return nil end
			clean.buttons[id]={
				x=math.clamp(entry.x,0.03,0.97),
				y=math.clamp(entry.y,0.05,0.97),
				s=math.clamp(entry.s,Layout.MinScale,Layout.MaxScale),
			}
		end
	end
	return clean
end

return Layout
