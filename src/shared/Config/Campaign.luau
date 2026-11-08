--!strict
-- Campanha V3 (docs/CAMPAIGN_SIX_PHASES.md): seis regiões no mesmo lugar, afastadas 3000 studs.
-- Com StreamingEnabled (raio 1024) o cliente só recebe a região onde está.
-- Coordenadas de cada região são locais à sua `origin`; -Z é o sentido do percurso.
--
-- Estado: cenários e conexões. A jogabilidade das regiões 2–6 ainda não existe, por isso
-- `gateRequiresCompletion` só vale para o Vale (Guardião de Raízes vencido).
export type Atmosphere={
	clock: number, latitude: number, brightness: number, exposure: number,
	ambient: Color3, outdoor: Color3,
	density: number, offset: number, color: Color3, decay: Color3, haze: number, glare: number,
	cloudCover: number, cloudDensity: number, cloudColor: Color3,
	tint: Color3, saturation: number, contrast: number,
}
export type Region={
	id: string, order: number, name: string, subtitle: string,
	origin: Vector3, voidY: number, gateRequiresCompletion: boolean,
	-- Portal escondido até o encontro indicado ser vencido (fase 5: parece a última).
	exitRevealedBy: string?,
	atmosphere: Atmosphere,
}

local C=Color3.fromRGB
local Campaign={}

Campaign.Regions={
	{
		id="Lumen", order=1, name="VALE DE LÚMEN", subtitle="Fase 1 · Refúgio dos viajantes",
		origin=Vector3.new(0,0,0), voidY=-40, gateRequiresCompletion=true,
		-- Referência 2: hora dourada com céu rosado (sol baixo, névoa quente, nuvens rosadas).
		atmosphere={clock=17.45, latitude=35, brightness=2.3, exposure=0.22, ambient=C(92,88,108), outdoor=C(150,128,136),
			density=0.27, offset=0.18, color=C(246,214,206), decay=C(156,124,168), haze=1.5, glare=0.3,
			cloudCover=0.46, cloudDensity=0.45, cloudColor=C(255,206,196), tint=C(255,240,230), saturation=0.07, contrast=0.09},
	},
	{
		id="CrystalAbyss", order=2, name="ABISMO DE CRISTAL", subtitle="Fase 2 · Pontes sobre o eco",
		origin=Vector3.new(3000,100,0), voidY=-70, gateRequiresCompletion=false,
		atmosphere={clock=17.2, latitude=18, brightness=2.6, exposure=0.1, ambient=C(92,88,108), outdoor=C(124,116,136),
			density=0.22, offset=0.1, color=C(248,196,212), decay=C(156,108,180), haze=1.0, glare=0.6,
			cloudCover=0.42, cloudDensity=0.38, cloudColor=C(255,206,214), tint=C(255,244,242), saturation=0.14, contrast=0.12},
	},
	{
		id="HourDesert", order=3, name="DESERTO DAS HORAS", subtitle="Fase 3 · Ruínas fora do tempo",
		origin=Vector3.new(-3000,0,0), voidY=-40, gateRequiresCompletion=false,
		atmosphere={clock=16.9, latitude=10, brightness=2.6, exposure=0.15, ambient=C(120,96,72), outdoor=C(170,138,100),
			density=0.36, offset=0.2, color=C(242,196,136), decay=C(196,128,92), haze=2.2, glare=0.35,
			cloudCover=0.3, cloudDensity=0.35, cloudColor=C(255,214,170), tint=C(255,240,218), saturation=0.12, contrast=0.1},
	},
	{
		id="EclipseCitadel", order=4, name="CIDADELA DO ECLIPSE", subtitle="Fase 4 · A fortaleza sob o sol negro",
		origin=Vector3.new(0,0,3000), voidY=-45, gateRequiresCompletion=false,
		atmosphere={clock=18.15, latitude=40, brightness=1.8, exposure=0.25, ambient=C(98,86,132), outdoor=C(118,102,152),
			density=0.3, offset=0.1, color=C(110,92,150), decay=C(78,54,104), haze=1.2, glare=0.1,
			cloudCover=0.55, cloudDensity=0.5, cloudColor=C(110,92,150), tint=C(232,222,255), saturation=0.05, contrast=0.14},
	},
	{
		id="Convergence", order=5, name="LIMIAR DA CONVERGÊNCIA", subtitle="Fase 5 · Onde os caminhos se encontram",
		origin=Vector3.new(3000,150,3000), voidY=-50, gateRequiresCompletion=false, exitRevealedBy="Herald",
		atmosphere={clock=17.95, latitude=25, brightness=2.1, exposure=0.15, ambient=C(104,108,140), outdoor=C(130,134,170),
			density=0.3, offset=0.3, color=C(188,196,232), decay=C(122,108,170), haze=1.5, glare=0.2,
			cloudCover=0.5, cloudDensity=0.42, cloudColor=C(232,214,250), tint=C(240,240,255), saturation=0.08, contrast=0.1},
	},
	{
		id="VoidDominion", order=6, name="DOMÍNIO DO VAZIO", subtitle="Fase 6 · A fortaleza do Regente",
		origin=Vector3.new(-3000,300,3000), voidY=-60, gateRequiresCompletion=false,
		atmosphere={clock=17.8, latitude=30, brightness=2, exposure=0.22, ambient=C(112,88,142), outdoor=C(132,102,166),
			density=0.33, offset=0.2, color=C(150,112,196), decay=C(96,58,130), haze=1.7, glare=0.3,
			cloudCover=0.6, cloudDensity=0.5, cloudColor=C(176,128,220), tint=C(244,230,255), saturation=0.14, contrast=0.12},
	},
} :: {Region}

-- Rota A (1–3 jogadores): sequencial. Rota B (4–6): ramos 1–4 em paralelo, depois 5 e 6.
Campaign.RouteA={"Lumen","CrystalAbyss","HourDesert","EclipseCitadel","Convergence","VoidDominion"}
Campaign.BranchRegions={"Lumen","CrystalAbyss","HourDesert","EclipseCitadel"}

local byId: {[string]: Region}={}
for _,region in Campaign.Regions do byId[region.id]=region end

function Campaign.get(id: string?): Region?
	return if id then byId[id] else nil
end

-- Região que contém um ponto: a origem mais próxima (as regiões ficam a 3000 studs umas das outras).
function Campaign.regionAt(position: Vector3): Region
	local best,bestDistance=Campaign.Regions[1],math.huge
	for _,region in Campaign.Regions do
		local offset=position-region.origin
		local distance=Vector3.new(offset.X,0,offset.Z).Magnitude
		if distance<bestDistance then best,bestDistance=region,distance end
	end
	return best
end

-- Próxima região a partir de `id`, conforme a rota da expedição.
function Campaign.nextRegion(id: string, route: string): string?
	if route=="B" then
		for _,branch in Campaign.BranchRegions do
			if branch==id then return "Convergence" end
		end
	end
	for index,regionId in Campaign.RouteA do
		if regionId==id then return Campaign.RouteA[index+1] end
	end
	return nil
end

-- Objetivo exibido no HUD em cada região 2–6 (o Vale usa as cinco missões do capítulo).
-- `done` aparece depois que o chefão cai (CampaignPhase na Rota A; Resolved_<id> na Rota B).
Campaign.Objectives={
	CrystalAbyss={title="O CRISTAL QUE LEMBRA",goal="Atravesse as pontes do abismo e vença o Wyrm de Cristal na catedral.",done="O Wyrm caiu. Siga pela Passagem de Cristal atrás da catedral."},
	HourDesert={title="A AREIA QUE NÃO PASSA",goal="Cruze as dunas até o templo das horas e vença a Esfinge das Horas.",done="A Esfinge caiu. A Passagem das Horas está aberta ao lado do templo."},
	EclipseCitadel={title="SOB O SOL NEGRO",goal="Suba à cidadela e vença o Dragão do Eclipse no pátio do castelo.",done="O Dragão caiu. Atravesse a Passagem Oculta além do selo."},
	Convergence={title="ONDE OS CAMINHOS SE ENCONTRAM",goal="Reúna-se na arena central e vença o Arauto Partido.",done="O Arauto caiu. Um caminho novo surgiu para o Domínio do Vazio."},
	VoidDominion={title="O DOMÍNIO DO VAZIO",goal="Atravesse as ilhas suspensas até o Átrio e enfrente o Regente do Vazio.",done="O Regente caiu. O Portal Primordial está aberto."},
}

-- Rota fixada pela quantidade de participantes confirmada no início (1–3 = A, 4–6 = B).
function Campaign.routeFor(players: number): string
	return if players>=4 then "B" else "A"
end

return Campaign
