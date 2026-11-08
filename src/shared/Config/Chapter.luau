--!strict
-- Universo e coordenadas originais de As Crônicas do Portal Perdido.
return {
	Version = 3,
	Title = "A TRAVESSIA",
	GroundY = 2,
	-- Alturas absolutas dos pisos jogáveis (referência 2: vale em camadas).
	-- Pisos são peças com altura exata; o terreno de voxels só dá a massa natural.
	Relief = {
		PortalMesa = 21.5, DawnHill = 16, RootMesa = 22, StarIsland = 30, Temple = 26.5, Arena = 40,
		GateZ = -455, VoidY = -40,
		-- Depois do limiar: início do caminho de pedras flutuantes até a arena.
		Threshold = Vector3.new(0, 30, -463),
		Gorge = {z = -108, halfWidth = 12, bottom = -22},
	},
	Checkpoints = {
		Village = Vector3.new(0, 5, 32),
		Forest = Vector3.new(0, 5, -145),
		Temple = Vector3.new(0, 29, -384),
		Arena = Vector3.new(0, 43, -515),
	},
	Ilyra = Vector3.new(12, 0, 14),
	Quests = {
		{title = "UM MUNDO ALÉM", objective = "Encontre Ilyra no Vale de Lúmen.", reward = 0},
		{title = "A PRIMEIRA AMEAÇA", objective = "Derrote o Sentinela de Musgo no caminho da floresta.", reward = 25},
		{title = "VOZES DA FLORESTA", objective = "Recupere as três inscrições guardadas na Floresta Esquecida.", reward = 40},
		{title = "O LIMIAR DO TEMPLO", objective = "Ative os selos na ordem: Aurora, Raiz, Estrela.", reward = 35},
		{title = "O GUARDIÃO DE RAÍZES", objective = "Vença o Guardião e recolha o Fragmento da Aurora.", reward = 100},
	},
	Runes = {
		-- Y é resolvido pelo piso do platô (Relief); aqui só X/Z.
		{id = "Dawn", name = "Inscrição da Aurora", symbol = "I", position = Vector3.new(-62, 0, -184), guard = "RuneMoss"},
		{id = "Root", name = "Inscrição da Raiz", symbol = "II", position = Vector3.new(67, 0, -255), guard = "RuneThorn"},
		{id = "Star", name = "Inscrição da Estrela", symbol = "III", position = Vector3.new(-42, 0, -325), guard = "RuneWisp"},
	},
	SealOrder = {"Dawn", "Root", "Star"},
	EnemyTypes = {
		Moss = {name = "Sentinela de Musgo", health = 120, damage = 10, speed = 7, radius = 7, windup = 0.9, cooldown = 2.8, color = Color3.fromRGB(74, 117, 86)},
		Thorn = {name = "Predador de Espinhos", health = 100, damage = 12, speed = 12, radius = 6, windup = 0.65, cooldown = 2.2, color = Color3.fromRGB(126, 106, 76), agile = 0.2, abilities = {pounce = true}},
		Wisp = {name = "Eco do Vazio", health = 85, damage = 13, speed = 7, radius = 9, windup = 1.0, cooldown = 3.0, color = Color3.fromRGB(129, 108, 190), agile = 0.2},
		Boss = {name = "Guardião de Raízes", health = 1800, damage = 22, speed = 4, radius = 12, windup = 1.4, cooldown = 3.8, color = Color3.fromRGB(103, 125, 83)},
		-- Fase 5: chefe que parece ser o último. Vida escala com quem está na arena (solo viável).
		Herald = {name = "Arauto Partido", title = "ARAUTO PARTIDO", health = 2600, healthPerPlayer = 1500, damage = 24, speed = 7, radius = 10, windup = 1.1, cooldown = 2.6, color = Color3.fromRGB(196, 150, 255), big = true},
		-- Chefões finais das regiões 2–4: mesmo esquema de combate do Arauto (golpes em área
		-- telegrafados, onda ao redor, três fases), com tema e ritmo próprios. Vida escala por
		-- participante, então o solo continua viável. Vencer abre a passagem da região.
		CrystalWyrm = {name = "Wyrm de Cristal", title = "WYRM DE CRISTAL", health = 2000, healthPerPlayer = 1100, damage = 20, speed = 6, radius = 9, windup = 1.25, cooldown = 3.0, color = Color3.fromRGB(150, 210, 255), big = true, ai = "Herald", region = "CrystalAbyss",
			phaseTexts = {"O WYRM DE CRISTAL desperta. Cada reflexo esconde um golpe!", "Os cristais do Wyrm se estilhaçam: crias do abismo surgem na catedral!", "REFRAÇÃO TOTAL: o Wyrm ataca sem pausa!"}},
		SandSphinx = {name = "Esfinge das Horas", title = "ESFINGE DAS HORAS", health = 2200, healthPerPlayer = 1200, damage = 21, speed = 7, radius = 9, windup = 1.15, cooldown = 2.8, color = Color3.fromRGB(240, 190, 110), big = true, ai = "Herald", region = "HourDesert",
			phaseTexts = {"A ESFINGE DAS HORAS desperta. A areia marca onde ela vai golpear!", "A ampulheta vira: as feras das dunas acorrem ao templo!", "A ÚLTIMA HORA: a Esfinge acelera o próprio tempo!"}},
		EclipseDragon = {name = "Dragão do Eclipse", title = "DRAGÃO DO ECLIPSE", health = 2400, healthPerPlayer = 1300, damage = 23, speed = 7, radius = 10, windup = 1.1, cooldown = 2.7, color = Color3.fromRGB(170, 120, 240), big = true, ai = "Herald", region = "EclipseCitadel",
			phaseTexts = {"O DRAGÃO DO ECLIPSE desperta. O sol negro aponta o próximo golpe!", "O eclipse se fecha: as feras da sombra surgem no pátio!", "NOITE ABSOLUTA: o Dragão não dá trégua!"}},
		-- Fase 6: chefe FINAL. Sem capuz pela primeira vez (rosto e coroa à mostra). Além do
		-- esquema do Arauto, a partir da fase 2 usa o Passo do Vazio (some e reaparece junto
		-- do alvo, com aviso no chão). A derrota encerra a campanha.
		VoidRegent = {name = "Regente do Vazio", title = "O REGENTE DO VAZIO", health = 3200, healthPerPlayer = 1600, damage = 26, speed = 7, radius = 10, windup = 1.05, cooldown = 2.5, color = Color3.fromRGB(186, 110, 255), big = true, ai = "Herald", region = "VoidDominion", voidStep = true,
			phaseTexts = {"O REGENTE DO VAZIO baixa o capuz: \"Finalmente, cara a cara.\"", "\"Vocês acham que me venceram nos outros mundos? Eu ESTAVA neles.\" O vazio se abre no átrio!", "\"Se eu cair, Aetherion cai comigo!\" O Regente ataca sem pausa!"}},
		-- Criaturas exclusivas de cada região (modelos gerados; ai = comportamento reaproveitado).
		-- Abismo de Cristal
		CrystalSpider = {name = "Aranha de Cristal", health = 140, damage = 13, speed = 11, radius = 6, windup = 0.6, cooldown = 2.2, color = Color3.fromRGB(130, 210, 255), ai = "Thorn", agile = 0.2, abilities = {shot = "web", webPull = true}},
		PrismBat = {name = "Dragonete Prismático", health = 95, damage = 14, speed = 9, radius = 9, windup = 0.9, cooldown = 2.8, color = Color3.fromRGB(220, 150, 255), ai = "Wisp", agile = 0.25, flier = true, abilities = {shot = "fire"}},
		-- Deserto das Horas
		SandScorpion = {name = "Escorpião das Areias", health = 170, damage = 15, speed = 8, radius = 6, windup = 0.7, cooldown = 2.4, color = Color3.fromRGB(230, 180, 110), ai = "Thorn", abilities = {shot = "sting"}},
		DuneJackal = {name = "Chacal das Dunas", health = 105, damage = 12, speed = 14, radius = 6, windup = 0.5, cooldown = 1.9, color = Color3.fromRGB(200, 150, 90), ai = "Thorn", agile = 0.3, abilities = {pounce = true}},
		-- Cidadela do Eclipse
		EclipseGargoyle = {name = "Gárgula do Eclipse", health = 130, damage = 15, speed = 9, radius = 9, windup = 0.9, cooldown = 2.6, color = Color3.fromRGB(170, 130, 230), ai = "Wisp", agile = 0.2, flier = true, abilities = {shot = "fire"}},
		ShadowHound = {name = "Cão Sombrio", health = 125, damage = 14, speed = 14, radius = 6, windup = 0.55, cooldown = 2.0, color = Color3.fromRGB(150, 110, 230), ai = "Thorn", agile = 0.3, abilities = {pounce = true}},
	},
	-- Fauna de cada região: encontros comuns (slots "Encounter" dos construtores) e reforços.
	-- A Convergência mistura criaturas dos quatro mundos.
	RegionFauna = {
		Lumen = {"Thorn", "Wisp"},
		CrystalAbyss = {"CrystalSpider", "PrismBat"},
		HourDesert = {"SandScorpion", "DuneJackal"},
		EclipseCitadel = {"ShadowHound", "EclipseGargoyle"},
		Convergence = {"CrystalSpider", "SandScorpion", "ShadowHound", "Thorn"},
		VoidDominion = {"ShadowHound", "PrismBat", "EclipseGargoyle"},
	},
	Encounters = {
		{id = "FirstSentinel", kind = "Moss", position = Vector3.new(0, 3, -68), leash = 28},
		-- Guardas das inscrições ficam nos platôs; corrente curta para não saírem do piso.
		{id = "RuneMoss", kind = "Moss", position = Vector3.new(-54, 3, -176), leash = 16},
		{id = "RuneThorn", kind = "Thorn", position = Vector3.new(64, 3, -248), leash = 12},
		{id = "RuneWisp", kind = "Wisp", position = Vector3.new(-38, 3, -318), leash = 14},
		{id = "ForestThorn", kind = "Thorn", position = Vector3.new(40, 3, -142), leash = 22},
		{id = "TempleWisp", kind = "Wisp", position = Vector3.new(32, 3, -358), leash = 22},
		{id = "RootGuardian", kind = "Boss", position = Vector3.new(0, 7, -550), leash = 48, vision = "Lumen"},
		-- Arena da Convergência (origem da região 5). Ao cair, abre a fenda do Regente.
		-- Chefões finais das regiões 2–4, nas arenas dos construtores (slot BossArena; +2 do ajuste de pivô).
		{id = "CrystalWyrm", kind = "CrystalWyrm", position = Vector3.new(3000, 133, -435), leash = 38, vision = "CrystalAbyss", region = "CrystalAbyss"},
		{id = "SandSphinx", kind = "SandSphinx", position = Vector3.new(-3000, 33, -452), leash = 36, vision = "HourDesert", region = "HourDesert"},
		{id = "EclipseDragon", kind = "EclipseDragon", position = Vector3.new(0, 29, 2668), leash = 40, vision = "EclipseCitadel", region = "EclipseCitadel"},
		-- Fase 6: Átrio do Regente (slot RegentAtrium do VoidDominion; origem + (0, 33, −372) + 2).
		{id = "VoidRegent", kind = "VoidRegent", position = Vector3.new(-3000, 335, 2628), leash = 40, region = "VoidDominion", finale = true, groundFromY = 330},
		{id = "Herald", kind = "Herald", position = Vector3.new(3000, 3, 3000), leash = 46, vision = "Convergence", visionStyle = "rift", region = "Convergence"},
	},
	Dialogues = {
		-- Prólogo: uma página por cena de ArrivalCinematic (escola, apagão, silêncio, despertar, confusão).
		ArrivalTitles = {"PRÓLOGO · A FEIRA DE CIÊNCIAS", "PRÓLOGO · O APAGÃO", "PRÓLOGO · O SILÊNCIO", "PRÓLOGO · O DESPERTAR", "PRÓLOGO · OUTRA REALIDADE"},
		Arrival = {"O ginásio está cheio para a feira de ciências. Entre conversas e apresentações, seis jovens acompanham o experimento da bobina.", "A bobina dispara e as luzes piscam. Todos correm para as portas, mas os seis sobem ao palco para tentar desligar a máquina. Um clarão, e tudo se apaga.", "Silêncio. Nenhuma voz, nenhum barulho da escola. Só um vento morno e cheiro de grama.", "Um a um, eles despertam. A cabeça gira, o chão é de grama, e as roupas não são as deles.", "— Onde... a gente está? Cada um sente uma força nova nas mãos: armas, magia, punhos que brilham. No Vale de Lúmen, Ilyra pode ajudar vocês a encontrar o caminho de casa."},
		IlyraFirst = {"Respire. Você está no Vale de Lúmen. Meu nome é Ilyra.", "O Portal Primordial foi selado. Sua chegada não deveria ser possível.", "As raízes da floresta estão inquietas. Afaste o Sentinela do caminho; depois procure as três inscrições antigas."},
		Runes = {"As inscrições respondem à sua presença. Aurora, Raiz, Estrela…", "Lembre a ordem. Os selos do templo guardam uma memória mais antiga que o próprio vale."},
		Temple = {"As portas reconhecem as três inscrições. Um tremor percorre a pedra.", "O Guardião de Raízes protege o Fragmento da Aurora. Observe o chão: suas raízes anunciam cada ataque.", "Quando seu núcleo mudar de cor, o combate entrará em uma segunda fase. Mantenha-se em movimento."},
		Ending = {"O Fragmento da Aurora repousa em suas mãos. Por um instante, você enxerga ilhas além das nuvens.", "Uma voz atravessa a luz: ‘O selo não foi feito para manter vocês do lado de fora.’", "Ilyra empalidece. ‘O Regente do Vazio sabe que você chegou. Esta travessia foi apenas o começo.’"},
	},
}
