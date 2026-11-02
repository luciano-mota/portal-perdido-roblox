# Teste manual — Primeira aventura (CPP-003/009/012/013/016/017)

**Ambiente:** Roblox Studio no Windows 11, Rojo 7.7.1, experiência Baseplate privada.

## Preparação

Após uma reinicialização do Windows, o processo `rojo serve` precisa ser iniciado novamente:

```powershell
cd "$HOME\Projetos\portal-perdido-roblox"
git switch feature/cpp-001-003-bootstrap
git pull --ff-only
C:\tools\rojo\rojo.exe serve
```

No Roblox Studio, abrir o projeto Baseplate, plugin Rojo > **Connect** > **Play**. Conferir o **Output**.

## Sequência principal

- [ ] O Baseplate padrão é substituído por terreno verde, árvores, ruínas, portal luminoso e um ponto de spawn.
- [ ] Ao entrar, aparece o painel com **Guardião**, **Explorador** e **Artífice**.
- [ ] Ao escolher classe, o painel desaparece e surge o painel de missão e botão **ATACAR [Q]**.
- [ ] Caminhar até a mentora **Ilyra**, perto da entrada, e pressionar **E** (ProximityPrompt).
- [ ] A missão passa para **A PRIMEIRA AMEAÇA**.
- [ ] Aproximar-se do **Sentinela de Musgo**, mais adiante em direção ao portal.
- [ ] Apertar **Q** ou o botão **ATACAR** três a quatro vezes, respeitando o cooldown; o HP do inimigo diminui.
- [ ] Sentinela persegue jogador, causa dano a curta distância e ressurge após ~7 segundos de ser derrotado.
- [ ] A missão muda para **Volte para Ilyra**.
- [ ] Conversar com Ilyra e receber **25 moedas**; repetir o diálogo não dá moedas extras.
- [ ] Ao sair do servidor e voltar, moedas recomeçam em 0 (comportamento provisório até CPP-004).

## Testes de segurança/robustez

- [ ] Atacar longe do inimigo não causa dano.
- [ ] Disparar ataques repetidamente não supera o limite do servidor.
- [ ] Atacar antes de escolher a classe não causa dano.
- [ ] Não é possível receber recompensa sem derrotar o sentinela com a missão ativa.
- [ ] Repetir conversa com NPC após recompensa não gera moedas duplicadas.
- [ ] Morrer ou reiniciar avatar não desconfigura a classe durante a sessão.
- [ ] Testar com 2 jogadores: o inimigo é compartilhado e o crédito da missão vai para quem dá o golpe final (limitação do protótipo).

## Erros comuns

- **Cena não aparece:** confira se o plugin Rojo está conectado; clique Play. O mapa é criado em tempo de execução.
- **Interface não aparece:** verifique StarterPlayer > StarterPlayerScripts > GameClient.
- **Infinite yield:** conferir GameRemotes, ReplicatedStorage.Shared.Config.Classes e módulos em ServerScriptService.Services.
- **Não ataca:** precisa escolher classe, estar vivo e a até 18 studs do Sentinela; aguardar 0,65 s entre golpes.
- **Desconexão do Rojo:** o PowerShell com `rojo serve` precisa permanecer aberto.

## Evidências

Registrar capturas do mapa, HUD, NPC, HP do Sentinela, estado de missão concluída e erros do Output. **Não fechar cards sem validar no Studio.**

## Verificação de interface (02/11/2026)

- [ ] Modal exibe **título**, depois descrição, depois os botões **Guardião / Explorador / Artífice**, nessa ordem.
- [ ] Em tela desktop de cerca de 1136×628, modal fica à direita do chat nativo aberto, sem sobreposição importante.
- [ ] HUD da missão não cobre o chat nativo no desktop.
- [ ] No celular, modal permanece centralizado e sem botões cortados.
- [ ] Ao iniciar, a câmera não fica colada em tronco de árvore; caminho, mentora e portal devem ficar visíveis.
- [ ] Moedas só aparecem após escolha de classe.

Se o Rojo já estiver em execução, atualize o Git **fora do modo Play**, pare e reinicie o Play Test para gerar novamente o cenário via `WorldBuilder`. Se o servidor Rojo ficar com arquivos antigos, reinicie `rojo serve` e reconecte o plugin.

## Sessão MCP — 02/11/2026

**Base:** `08acf5c5fe30f7b2538eff2f501c7246459f577a`, branch `feature/cpp-001-003-bootstrap`, PR #30. Os ajustes abaixo foram sincronizados pelo Rojo e testados no Studio antes do commit desta seção. Lugar local confirmado pelo operador: `Template_95206881_AutoRecovery_0.rbxl`, PlaceId/GameId 0. Nada publicado.

### Resultado observado

| Caso | Resultado / evidência |
| --- | --- |
| Play real com personagem | PASSOU. Inicialização do servidor, UI e mundo gerado; não foi usado Run. |
| Movimento desktop | PASSOU. W/A/S/D produziram deslocamentos; Espaço levou a `Freefall`, com aumento de Y ~6,45 studs. Logs em [output.json](evidence/2026-11-02/output.json). |
| Física do avatar | WalkSpeed 16, JumpPower 50, JumpHeight 7,2, PlatformStand=false, Sit=false, RootAnchored=false. |
| Entrada consumida | Ao abrir o chat com `/`, W chegou como `Processed=true`, sem deslocamento. `GetFocusedTextBox()` retornou nil: não usar esse campo isoladamente para excluir consumo pelo CoreGui. Antes de abrir o chat, W chegou como `Processed=false` e moveu o avatar. |
| Controles padrão | `PlayerModule` presente em `StarterPlayer.PlayerModule` nesta versão do Studio. Ausência em PlayerScripts, sozinha, NÃO é falha. Não foi instalado/forkado controle customizado. |
| Três classes | PASSOU. Botões Guardian/Explorer/Artificer selecionaram a classe e fecharam o modal. MaxHealth observado: 150/110/100. Tentativas de trocar Explorer para Guardian e para classe inválida não alteraram a escolha. |
| Guardião | Missão completa com E/Q no desktop: ACTIVE → READY em 4 golpes de 33; COMPLETED e 25 moedas com Ilyra. Repetir diálogo manteve 25. Repetido em servidor com dois jogadores. |
| Explorador | Missão completa com E e botão ATACAR: 3 golpes de 40; recompensa 25. Recriação do avatar manteve Explorer, MaxHealth 110 e moedas 25. |
| Artífice / emulador | Missão completa com botão ATACAR: 4 golpes de 30; recompensa 25, repetição manteve 25. ProximityPrompt acionado por `InputHoldBegin`/`InputHoldEnd` no cliente, preservando validação de distância do servidor. Clique automatizado no balão nativo não foi confiável. |
| Celular / iPhone XR | TouchEnabled=true, PreferredInput=Touch, viewport 801×413 e área útil 801×355. Modal final escalado a 0,9457; botões com altura ~49 px úteis. Movimento por arrasto do direcional levou Z de 19,5079 a 12,2278. |
| HUD touch | ATACAR em (661,169), tamanho 120×56; salto nativo em (706,265), 70×70: sem interseção. Moedas dentro do painel superior, fora do direcional. [Captura final](evidence/2026-11-02/mobile-hud-final.jpg). |
| Perseguição / área segura | Após retornar a Ilyra, Sentinela voltou a (0,2,-22); Artífice permaneceu com 100 HP, sem spawn camping. Respawn do inimigo observado com Health=100. |
| Dois jogadores reais | PASSOU. Servidor local separado e dois clientes conectados (Player1 e Player2), com classe e missão independentes. [Captura](evidence/2026-11-02/two-player-server.jpg). |
| Crédito compartilhado | Player1 Guardian finalizou o inimigo e recebeu READY e depois 25 moedas. Player2 Explorer permaneceu ACTIVE/0 moedas; conversar sem golpe final não premiou. Comportamento limitado ao autor do golpe final, conforme arquitetura atual. |
| Cooldown / dano falso | 15 disparos diretos de AttackEnemy no alcance, enviando 100000 como argumento, reduziram o HP de 100 para 67: apenas um golpe Guardian aceito. Ataques sem classe e fora do alcance mantiveram HP=100. |
| Morte / respawn multiplayer | Player1 morto pelo teste reapareceu com Guardian, MaxHealth/Health=150, COMPLETED e Coins=25. Repetição da entrega antes da morte não duplicou moedas. |
| Reiniciar servidor | Moedas voltaram a 0. Persistência continua NÃO implementada. |
| Output | Nenhum stack trace Luau ou infinite yield observado. Aviso de conteúdo pendente, detalhado abaixo. |
| Build | `rojo build` com Rojo 7.7.1 e `git diff --check` passaram. Runtime testado no Studio; build isolado não é prova de gameplay. |

### Alterações desta sessão

- HUD responsivo considera a área útil do ScreenGui; adapta-se a mudanças de câmera, tamanho e tipo de entrada. Fundo opaco melhora leitura; removido glifo que aparecia como quadrado na fonte.
- ATACAR touch fica acima do salto nativo, com retorno visual do cooldown e bloqueio local de repetição/morte. Validação autoritativa permanece no servidor.
- Sentinela inicia mais distante, ignora jogadores sem classe e retorna à origem quando não há jogador elegível dentro de 24 studs da origem. Evita perseguir até a entrada/Ilyra.
- ClassService lê a classe depois que o Humanoid existe no CharacterAdded; elimina a janela em que uma seleção durante construção do personagem podia perder a saúde de classe.
- QuestService rejeita interação de personagem morto.
- MovementDebug agora registra estado, MoveDirection, MenuIsOpen, localização do PlayerModule e deslocamento 0,35 s após entrada; continua exclusivo do Studio e limitado a 12 entradas.

### Pendências e limites

- **#31 continua aberta.** O travamento original com viewport em foco não se reproduziu. Consumo de entrada pelo chat foi observado, mas não há evidência suficiente para declarar que foi a causa do relato original. Nenhum reset arbitrário de WalkSpeed, âncora ou controles foi adicionado.
- `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type` ocorre desde a primeira inspeção em Edit e reaparece nos testes. `MarketplaceService:GetProductInfoAsync` identificou `Pop Close Sound`, AssetTypeId=3 (áudio). Não há referência em src/, scripts sincronizados ou propriedades de mídia inspecionadas do jogo. Origem ainda não localizada; não foi silenciado nem declarado corrigido. Investigar componentes/plugins do Studio separadamente, sem editar conta.
- Emulação não substitui teste em aparelho físico, medição de FPS/memória ou redes móveis. Não foi realizado perfil de desempenho. Mapa permanece blockout provisório.
- Interação por toque físico no ProximityPrompt precisa confirmação manual: a missão no emulador usou a API de input do próprio prompt, sem alterar atributos de missão/moedas ou invocar QuestService diretamente.
- Nenhum teste completo de habilidades avançadas, persistência ou monetização; esses sistemas não existem nesta entrega. Não publicar nem ativar compras sem aprovação.

### Capturas

- [Seleção das três classes, layout final](evidence/2026-11-02/mobile-classes.jpg)
- [HUD final no celular](evidence/2026-11-02/mobile-hud-final.jpg)
- [Artífice com missão concluída e 25 moedas](evidence/2026-11-02/mobile-artificer-completed.jpg) — anterior ao ajuste final de opacidade/glifo do HUD.
- [Servidor com dois jogadores após respawn](evidence/2026-11-02/two-player-server.jpg)
- [Output capturado por MCP](evidence/2026-11-02/output.json)

## Complemento visual — 02/11/2026

Solicitação do operador: efeitos semirrealistas mantendo a história e os cenários iniciais. Direção canônica e distinção entre conteúdo entregue/planejado em [VISUAL_DIRECTION.md](VISUAL_DIRECTION.md).

- PASSOU no Studio: perfil touch manteve atmosfera e correção de cor, com Bloom, SunRays, DepthOfField e PortalPerdidoBloom desativados.
- PASSOU no Studio: perfil KeyboardAndMouse ativou somente o bloom discreto do projeto; efeitos herdados permaneceram desativados.
- PASSOU: nova execução de `WorldBuilder.build()` manteve **1 Atmosphere e 58 BaseParts**, sem duplicar efeitos ou geometria.
- PASSOU: movimento W continuou funcionando após a mudança; deslocamento observado de ~5,79 studs em 0,35 s, `Processed=false`, `MenuOpen=false`. Seleção de Guardião e aceite da missão com Ilyra no emulador continuaram funcionando.
- Nenhum stack trace novo ou infinite yield; o aviso externo de asset 203785492 permanece pendente. Build Rojo e verificação de whitespace passaram.
- Capturas: [desktop semirrealista](evidence/2026-11-02/semireal-desktop.jpg), [mobile semirrealista](evidence/2026-11-02/semireal-mobile.jpg).
- Limites: sem benchmark de GPU/FPS, sem teste em celular físico e sem nova construção de floresta/templo/chefe. A suíte completa da missão/multiplayer acima foi executada antes desta alteração de iluminação; depois dela houve apenas os testes pontuais descritos neste complemento.
