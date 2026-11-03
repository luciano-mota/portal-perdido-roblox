# Guardião humanizado — QA de 03/11/2026

Pedido do usuário: as três classes com aspecto humanizado. Até esta data o Guardião usava o avatar padrão do Roblox com armadura procedural, porque `ClassService` procurava um `GuardianTemplate` inexistente.

## Geração e exportação

- Gerado por `generate_avatar` (pipeline `npc`, cabeça dinâmica) a partir de descrição textual original baseada em `assets/characters/references/guardian-reference-v1.png`: jovem cavaleiro de cabelo dourado ondulado, armadura prateada com acabamento dourado, túnica azul e capa curta com estrela de oito pontas. A chamada excedeu o tempo limite da ferramenta, mas o modelo apareceu no Workspace depois, como já ocorrera com o Artífice e a Ilyra.
- Estrutura: 16 MeshParts com SurfaceAppearance, 15 AnimationConstraints, Humanoid e HumanoidRootPart, sem scripts. Altura 6,1 studs.
- Exportado sem perda via `SerializationService` → POST para receptor local em 127.0.0.1 (HttpEnabled ligado só durante o envio e restaurado para false). Arquivo: `assets/characters/models/guardian-generated-v1.rbxm`, 659.107 bytes, cabeçalho binário `<roblox!` íntegro. Fonte original guardada em `ServerStorage.GeneratedReferences` do lugar de trabalho.
- Mapeado em `default.project.json` como `ServerStorage.GuardianTemplate`.

## Integração

- `Art.equipment` agora descarta Breastplate, Pauldrons e PlateTrim em rigs gerados (a armadura já está modelada). Espada e escudo astral continuam.

## Evidência no Play (Studio local)

- Seleção pela interface real: `PortalGeneratedRig=true`, 150/150 HP; equipamento = SwordBlade, SwordGuard, SwordGrip, AstralShield, ShieldSigil.
- Tecla E na Ilyra → missão 2; Égide (R) e ataques Q → Sentinela 0 HP, missão 3, 25 moedas. Zero erros Luau no servidor.

## Limitações

- O viewport 3D do Studio passou a renderizar em branco logo após a geração (UI normal, 15 FPS, 3,4 GB). Cena e Lighting conferidos sem anomalia: é estado do Studio/GPU. **A aparência do Guardião em jogo ainda não foi verificada por captura**; repetir após reiniciar o Studio.
- Asset depende dos IDs de malha/textura entregues pelo Roblox na conta do desenvolvedor.
