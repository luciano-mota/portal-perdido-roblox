# Arquitetura — As Crônicas do Portal Perdido (campanha de seis fases)

## Autoridade e fluxo

O cliente apresenta interface, controles, poses e efeitos. O servidor decide classe, alvos válidos, dano, cooldown, variantes de golpe (chão/ar/agachado), inscrições, missão, fase da campanha, checkpoints, recompensas e o layout salvo dos controles. `src` sincronizado por Rojo é a fonte de verdade; não editar módulos sincronizados só na memória do Studio.

`GameServer` constrói o Vale (WorldBuilder/LumenRelief/LumenScenery) e as regiões 2–6 (Regions), garante os templates das criaturas (CreatureMeshes), cria os encontros regionais e conecta serviços/remotes. Perfis carregam antes de registrar classe e missão. O prólogo e a seleção são apresentados ao cliente quando QuestIndex está disponível.

## Módulos

| Módulo | Responsabilidade |
| --- | --- |
| WorldBuilder / LumenRelief / LumenScenery | Vale de Lúmen determinístico: vila, relevo em camadas, praças com borda de cantaria, escadarias com variação, ruínas, montanhas com arco de rocha, névoa. |
| Regions + regions/* + RegionKit | Cenários das regiões 2–6 em origens afastadas 3000 studs; slots `Encounter`, `BossArena`, pontos seguros e portais de saída. |
| CreatureMeshes | Os 10 templates gerados (fauna + Arauto) versionados como dados (MeshId/TextureID/tamanho/CFrame) e reconstruídos com `AssetService:CreateMeshPartAsync` quando faltam. |
| ClassService | Allowlist de seis heróis, desbloqueio por fase (Rota A), escolha persistida, rig/equipamento e retorno ao checkpoint. |
| ExpeditionService | Rota A (1–3, sequencial) e B (4–6, sorteio por região, reencontro na fase 5, eliminação só na expedição). |
| TravelService | Portais entre regiões (abertos pelo chefão), ponto de renascimento por região, quedas no vazio, cura nos pontos seguros (recarga 20 s), Portal Primordial de volta ao Vale. |
| PlayerDataService | Sessões, atributos replicados (inclui `CampaignPhase`, `ControlLayout`), mutações no servidor, recompensas por chave, autosave/release. Studio usa memória temporária. |
| ProfileStore | Schema v2, sanitização (missões, `phase`, heróis, recompensas `1–5` e `phase2–6`, `controls`) e adapter UpdateAsync com lease; perfil corrompido ou sessão concorrente não é sobrescrito; layout inválido é descartado sem rejeitar o perfil. |
| QuestService | Cinco etapas do Vale, prompts com validação de vida/distância, inscrições/selos, descanso, fragmento, limiar e falas da Ilyra conforme a fase da campanha. |
| EnemyService | Encontros do Vale e das regiões (fauna por região, `RegionFauna`), arquétipos de IA (`stats.ai`: Thorn/Wisp/Moss/Herald), vez de atacar (máx. 2 iniciando contra o mesmo jogador), chefões em três fases, Passo do Vazio do Regente, reforços escalados por grupo e desfeitos quando o chefão cai, atordoamento, chutes e golpes do Lutador. |
| GameClient | Prólogo/câmera, seleção, HUD (objetivo por região), diário/diálogo, pedidos de combate (variantes de chute/ataque), agachar, botão de pulo próprio no toque e tela final. |
| TouchControls / ControlLayout | Editor de controles de toque (arrastar, tamanho, opacidade, padrão, salvar) e validação pura compartilhada com o servidor. |
| Art / VillainArt | Geometria reproduzível, montagem das criaturas geradas com articulações (inclui rigs R15), reserva procedural do Regente. |
| ActorPresentation / AvatarFallback / CharacterMotion | Movimento local das criaturas por `MotionKind`; poses de heróis (combos, chutes, agachar) sem alterar raiz ou hitboxes. |
| VisualEffects / Audio / RegentVision | Telegráficos, impactos, nomes de golpes especiais, atordoamento, visões e fenda do Regente. |

## Contratos remotos

- `ChooseClass(classId)`: string em allowlist e herói disponível; escolha existente não muda.
- `AttackEnemy(variant?)`: servidor escolhe alvo por alcance/linha de visão. `variant` ("air"/"low") só vale para o Lutador e só se o servidor confirmar no ar (raycast) ou agachado (atributo).
- `Kick(variant?)`: "front"/"jump"/"sweep"; "jump" exige estar no ar (raycast), "sweep" exige `Crouching`; senão vira chute frontal. Dano/recarga decididos no servidor.
- `Crouch(active)`: define `Crouching` (velocidade 7, sem pulo); zerado ao renascer.
- `UseSkill()`, `Dash(dir)`, `Block(active)`: classe, personagem vivo e cooldown verificados no servidor.
- `SaveControls(layout|nil)`: limite de 1 envio a cada 2 s; `ControlLayout.sanitize` (ids conhecidos, números finitos, faixas); `nil` volta ao padrão. Sem efeito em jogabilidade.
- `Notify`: servidor envia apresentação, mensagens e eventos; cliente não concede moedas, fase nem desbloqueios.

Recompensas usam chaves (missões `1–5`, chefões `phase2–6`); repetir não paga de novo. Progressão pertence ao perfil do servidor, não a atributos alteráveis localmente.

## Cooperação e limites

Inimigos são compartilhados. Crédito de derrota exige contribuição recente, personagem vivo e proximidade. Vida dos chefões escala no primeiro dano com participantes elegíveis (até seis). Ausência de alvo por 12 s reinicia o encontro. Solo validado de ponta a ponta no Studio (Vale → Domínio); 3–6 clientes reais, Rota B real, dificuldade/duração humanas e dispositivo físico ainda não foram aprovados.

Rigs humanoides gerados (Regente, Lutador, Arcanista, Véu) dependem do lugar salvo ou de `.rbxm` exportado: o mapa do `SurfaceAppearance` não pode ser definido por script. O protocolo de perfil foi testado com adapter determinístico; DataStore real não foi comprovado (PlaceId=0).

Não há MarketplaceService nem compras. Publicação e monetização dependem de aprovação do usuário.

## Validação

Consulte DEVELOPMENT_STATUS.md e PLAYTEST.md para cenários e limites. `tests/ProfileStore.spec.luau` roda no Studio (10 casos). CI verifica estrutura/JSON/build, não simula gameplay. Testes no emulador não substituem aparelho físico.
