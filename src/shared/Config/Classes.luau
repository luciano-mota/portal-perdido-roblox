--!strict
-- Seis heróis (docs/CAMPAIGN_SIX_PHASES.md). Os três originais estão sempre disponíveis.
-- Rota A: Lutador, Arcanista e Véu são desbloqueados ao concluir as fases 1, 2 e 3 (`unlockPhase`).
-- Rota B (4–6 jogadores): os seis ficam disponíveis na expedição, sem desbloqueio permanente.
return {
	Guardian = {order = 1, displayName = "Guardião Astral", description = "Espada, escudo e proteção astral.", health = 150, damage = 30, range = 16, cooldown = 0.6, skillName = "ÉGIDE", skillCooldown = 12, color = Color3.fromRGB(89, 185, 224)},
	Explorer = {order = 2, displayName = "Explorador", description = "Arco preciso e uma chuva de flechas.", health = 110, damage = 33, range = 72, cooldown = 0.7, skillName = "RAJADA", skillCooldown = 10, color = Color3.fromRGB(161, 205, 112)},
	Artificer = {order = 3, displayName = "Artífice", description = "Foco arcano e pulso de energia.", health = 100, damage = 28, range = 55, cooldown = 0.7, skillName = "PULSO", skillCooldown = 11, color = Color3.fromRGB(207, 156, 239)},
	Brawler = {order = 4, unlockPhase = 1, displayName = "Lutador Solar", description = "O poder dele é lutar: golpes mais fortes, combo de 4 socos, Martelo Solar no ar, Gancho Ascendente agachado e chutes em dobro.", health = 140, damage = 36, range = 11, cooldown = 0.42, skillName = "CHUTE SOMBRA", skillCooldown = 9, color = Color3.fromRGB(255, 150, 60)},
	Arcanist = {order = 5, unlockPhase = 2, displayName = "Arcanista", description = "Cajado solar: esferas de fogo e um sol que explode em área.", health = 95, damage = 31, range = 64, cooldown = 0.8, skillName = "SOL NASCENTE", skillCooldown = 12, color = Color3.fromRGB(255, 196, 90)},
	Shade = {order = 6, unlockPhase = 3, displayName = "Véu", description = "Adagas e ilusões: some e reaparece atrás do alvo.", health = 100, damage = 22, range = 10, cooldown = 0.38, skillName = "PASSO DO VÉU", skillCooldown = 9, color = Color3.fromRGB(176, 130, 255)},
}
