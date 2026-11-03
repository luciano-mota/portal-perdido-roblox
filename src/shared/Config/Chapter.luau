--!strict
-- Universo e coordenadas originais de As Crônicas do Portal Perdido.
return {
	Version = 2,
	Title = "A TRAVESSIA",
	GroundY = 2,
	Checkpoints = {
		Village = Vector3.new(0, 5, 32),
		Forest = Vector3.new(0, 5, -145),
		Temple = Vector3.new(0, 5, -392),
		Arena = Vector3.new(0, 5, -510),
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
		{id = "Dawn", name = "Inscrição da Aurora", symbol = "I", position = Vector3.new(-62, 0, -182), guard = "RuneMoss"},
		{id = "Root", name = "Inscrição da Raiz", symbol = "II", position = Vector3.new(65, 0, -255), guard = "RuneThorn"},
		{id = "Star", name = "Inscrição da Estrela", symbol = "III", position = Vector3.new(-38, 0, -322), guard = "RuneWisp"},
	},
	SealOrder = {"Dawn", "Root", "Star"},
	EnemyTypes = {
		Moss = {name = "Sentinela de Musgo", health = 120, damage = 10, speed = 7, radius = 7, windup = 0.9, cooldown = 2.8, color = Color3.fromRGB(74, 117, 86)},
		Thorn = {name = "Predador de Espinhos", health = 100, damage = 12, speed = 11, radius = 6, windup = 0.7, cooldown = 2.4, color = Color3.fromRGB(126, 106, 76)},
		Wisp = {name = "Eco do Vazio", health = 85, damage = 13, speed = 6, radius = 9, windup = 1.1, cooldown = 3.2, color = Color3.fromRGB(129, 108, 190)},
		Boss = {name = "Guardião de Raízes", health = 1800, damage = 22, speed = 4, radius = 15, windup = 1.4, cooldown = 3.8, color = Color3.fromRGB(103, 125, 83)},
	},
	Encounters = {
		{id = "FirstSentinel", kind = "Moss", position = Vector3.new(0, 3, -68), leash = 28},
		{id = "RuneMoss", kind = "Moss", position = Vector3.new(-52, 3, -175), leash = 26},
		{id = "RuneThorn", kind = "Thorn", position = Vector3.new(57, 3, -244), leash = 28},
		{id = "RuneWisp", kind = "Wisp", position = Vector3.new(-29, 3, -311), leash = 27},
		{id = "ForestThorn", kind = "Thorn", position = Vector3.new(40, 3, -142), leash = 22},
		{id = "TempleWisp", kind = "Wisp", position = Vector3.new(32, 3, -358), leash = 22},
		{id = "RootGuardian", kind = "Boss", position = Vector3.new(0, 7, -550), leash = 48},
	},
	Dialogues = {
		Arrival = {"Uma demonstração. Um instante de luz. E então… a fenda.", "Você desperta sob um céu desconhecido. Ilhas flutuam além do horizonte.", "Um portal pulsa entre as ruínas. Alguém espera no caminho."},
		IlyraFirst = {"Respire. Você está no Vale de Lúmen. Meu nome é Ilyra.", "O Portal Primordial foi selado. Sua chegada não deveria ser possível.", "As raízes da floresta estão inquietas. Afaste o Sentinela do caminho; depois procure as três inscrições antigas."},
		Runes = {"As inscrições respondem à sua presença. Aurora, Raiz, Estrela…", "Lembre a ordem. Os selos do templo guardam uma memória mais antiga que o próprio vale."},
		Temple = {"As portas reconhecem as três inscrições. Um tremor percorre a pedra.", "O Guardião de Raízes protege o Fragmento da Aurora. Observe o chão: suas raízes anunciam cada ataque.", "Quando seu núcleo mudar de cor, o combate entrará em uma segunda fase. Mantenha-se em movimento."},
		Ending = {"O Fragmento da Aurora repousa em suas mãos. Por um instante, você enxerga ilhas além das nuvens.", "Uma voz atravessa a luz: ‘O selo não foi feito para manter vocês do lado de fora.’", "Ilyra empalidece. ‘O Regente do Vazio sabe que você chegou. Esta travessia foi apenas o começo.’"},
	},
}
