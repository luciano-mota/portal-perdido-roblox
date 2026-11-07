# Desenvolvimento em andamento — Capítulo 1

Objetivo autorizado: completar o primeiro capítulo jogável da ideia inicial, preservando o roteiro, sem publicação e sem compras.

## Já implementado nesta expansão

- Prólogo, cinco missões encadeadas, três inscrições, puzzle do templo, Guardião de Raízes em duas fases e Fragmento da Aurora com epílogo.
- Três classes com armas visíveis, ataques distintos, habilidades e esquiva; servidor valida ações, dano, alcance, cooldown e recompensas.
- Vale com vila, floresta, trilhas laterais, santuário e arena; Ilyra e três espécies de criaturas com modelos procedurais originais.
- HUD, retratos, diário, telas de seleção e conclusão, controles touch e áudio local com opção de silenciar.
- Checkpoints, fontes de recuperação e crédito cooperativo por participação/apoio.
- Perfil versionado com lease de sessão e proteção contra falhas. No Studio, modo temporário explícito: não se alegou salvamento real em DataStore.
- Contingência visual/animação quando ContentProvider confirma falha de assets, sem substituir controles ou assets que carregaram.

## Evidência obtida

- Uma passagem inteira com Explorador: Ilyra → Sentinela → três guardas/inscrições → selos (erro e sequência correta) → fase 2 do chefe → fragmento → conclusão. QuestIndex=6, HasFragment=true e Coins=200. Repetir fragmento manteve 200.
- Guardião: missão inicial e redução real de dano 10 → 3 durante Égide.
- Oito testes do protocolo de armazenamento executados no Luau do Studio: perfil novo, snapshot, sessão concorrente, lease expirada, sessão antiga bloqueada, liberação/recarga, corrupção/saldos inválidos e falha de rede.
- Medição inicial de 180 frames na arena: média 60,02 FPS, mediana 60,00 e percentil de frames lentos equivalente a 56,38 FPS no desktop atual. Não é benchmark mobile. Memória total informada pelo processo do Studio: 2715 MB; não confundir com memória em celular.

## Em validação / a concluir antes de declarar pronto

- Regressão após o acabamento visual, novas rotas de obstáculos, fontes de recuperação e aumento da vida do chefe (a primeira passagem usou 700 HP; a versão atual usa 1800 e escala cooperativa).
- Dificuldade/duração com público real, seis clientes e casos adicionais de falhas/reconexão. A passagem Artífice solo e Guardião/Explorador em dupla está registrada abaixo.
- Aparelho móvel físico, naturalidade final de poses/armas e acabamento artístico; resultados de emulador e medições sob combate registrados abaixo.
- Documentação/manifesto finais e evidências no PR #30.

## Limites externos conhecidos

- O Studio está recebendo HTTP 403 para assets do avatar/animações e alguns componentes nativos. A contingência mantém o avatar visível e animado; não foi alterada a conta nem automatizado login.
- PlaceId=0 e GameId=0: a versão local não permite comprovar persistência real publicada. O protocolo foi testado com adapter determinístico, sem tocar dados reais.
- Falta aparelho móvel físico e avaliação visual humana. Não declarar desempenho mobile aprovado apenas pela emulação.

## Correção de passadas e uso de armas — 02/11/2026

Causa reproduzida: o rig local usa 15 `AnimationConstraint` e nenhum `Motor6D`. A contingência anterior procurava apenas Motor6D, coletando zero articulações. O problema se somava ao HTTP 403 das animações nativas. Agora ambos os tipos são reconhecidos, e `Transform` é aplicado em PreSimulation conforme a documentação oficial, sem alterar attachments, raiz, controles ou dano.

Implementado `CharacterMotion`: passada proporcional à velocidade, flexão alternada de joelhos/tornozelos, balanço dos braços, tronco, transições suaves, salto e sequências originais de espada, arco e lançamento arcano. Os eventos aprovados pelo servidor acionam os movimentos nos clientes próximos. Trajes receberam couro, ombreiras/peitoral, capa curta e bandoleira ou estola/grimório.

Evidência no Play do Studio, classe Artífice:
- 31 amostras em movimento: LeftKnee entre 0,050 e 0,870 rad; RightShoulder entre -0,546 e 0,458 rad.
- Ataques reais por Q, 200 amostras: RightShoulder entre -1,348 e -0,039 rad; evento confirmou classe Artificer.
- Três previews instanciados sem colisões: Guardian 22 partes, Explorer 24, Artificer 20.
- Poses das três classes verificadas para valores finitos; ainda falta aprovação visual dos três movimentos em combate e avaliação em celular.
- Erros remanescentes consultados no LogService são falhas de carregamento externo; não foi encontrado erro Luau nesta sessão.

Referência: https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint (suporte a Transform e migração Motor6D).

Esta é uma melhoria funcional de animação, não aprovação de qualidade humana final. Modelagem/realismo final, cooperação e regressão do capítulo continuam em desenvolvimento.

Complemento de validação das articulações no mesmo rig:
- Guardião, seleção real 150 HP e ataques Q: 290 amostras, ombro entre -1,125 e 0,411 rad.
- Explorador, seleção real 110 HP e ataques Q: 193 amostras, ombro entre -0,885 e -0,060 rad; cotovelo entre -1,473 e -0,138 rad.
- Salto por Espaço: 16 amostras Jumping/Freefall, joelho entre 0,203 e 0,550 rad.
- Esses resultados comprovam movimento das articulações em execução; não equivalem a aprovação de naturalidade ou sincronização audiovisual final.

- Respawn após morte induzida de teste: Explorador manteve classe e 110 HP, voltou ao spawn e animou novamente as 15 articulações; 29 amostras andando, joelho entre 0,050 e 0,881 rad. Sem alteração manual de progresso.
- Separado o gesto de ataque do limite de efeitos decorativos: atingir o orçamento visual não cancela a movimentação dos braços.

## Passagem completa atual com Artífice e revisão mobile

Em 02/11/2026, no Studio local, branch feature/cpp-001-003-bootstrap sobre 877609b, mais alterações de HUD/contingência desta sessão:

1. Seleção real de Artífice (100 HP), conversa com Ilyra e fechamento das páginas.
2. Sentinela derrotado por Q/R: quest 3 e 25 moedas.
3. Guardas Dawn/Root/Star derrotados e respectivos prompts acionados: três inscrições, quest 4 e 65 moedas.
4. Fonte do templo utilizada, checkpoint Temple; selos Aurora → Raiz → Estrela levaram a quest 5 e 100 moedas.
5. Entrada pelo limiar e combate contra 1800 HP: 1416 → 1032 → 648 (fase 2) → 432 → 48 → 0. Ataques Q/R e movimento lateral por A/D; sem modificar HP do chefe ou flags de progresso.
6. BossDefeated=true; coleta pelo prompt: quest 6, fragmento=true, checkpoint Village e 200 moedas. Repetição manteve 200. Tela de conclusão exibida após o epílogo.
7. LogService não apresentou erro de execução do jogo na passagem; continuam erros externos 403/mesh/animation asset delivery.

O combate usou emulação de Samsung Galaxy A06, mas mouse/teclado automatizados e InputHold dos prompts: **não é teste físico de toque**. Antes da correção subsequente de layout, o teclado alternava o HUD para desktop; a captura do chefe documenta essa condição histórica.

Medição durante o chefe, 600 frames no desktop com emulador: média 59,99 FPS, mediana 60,01, percentil lento equivalente a 55,55 FPS; memória total informada pelo Studio 2656 MB. Não representa memória nem velocidade de aparelho físico.

### Correções posteriores e escopo de regressão

- Falhas tardias de meshes agora são reavaliadas a cada três segundos: na sessão anterior, 15 meshes já estavam Failure mas não havia shells, pois só se verificava uma vez. Novo Play confirmou 15 shells visuais, sem alterar rig/colisões.
- Seleção compacta sem encolher toda a tipografia: botões 416×49; introdução, continuar, áudio e fechar recebem alvos com pelo menos 44 de altura. HUD de missão 390×76 no viewport de teste.
- TouchEnabled mantém layout de toque mesmo com PreferredInput KeyboardAndMouse. Confirmado após Q no emulador.
- Ajustes de espaçamento da conclusão e diário; a frase de salvamento permanece explícita e curta.
- Árvores com ramos assimétricos, onze grupos de copa e raízes, relevo lateral fora do corredor/inscrições e árvores posicionadas na superfície do terreno. Mundo: 1572 BaseParts. Sem meshes/texturas externos adicionais.
- Uma medição de 300 frames na inicialização da vegetação nova deu média 58,25 FPS, mediana 60,11 e percentil lento 54,94 FPS; memória total Studio 2905 MB. Inclui inicialização e não isola custo da vegetação. Ainda falta comparação aquecida e aparelho físico.
- Sem erro Luau encontrado no Play após a revisão de vegetação. A passagem completa acima precede a alteração da vegetação e o ajuste final do texto do diário; estes não aprovam nova passagem completa por inferência.

### Evidências

Capturas em docs/evidence/2026-11-02-chapter: seleção mobile de 49 px, diálogo/contingência visível, chefe em fase 2 e conclusão com Artífice. As datas/versões e o uso misto de entrada estão descritos em PLAYTEST.md.

Ainda pendentes: cooperação completa na revisão atual, benchmark aquecido sob combate após arte nova, aparelho móvel físico, persistência real, naturalidade/realismo artístico final e duração do capítulo.

## Cooperação completa e iluminação realista — 02/11/2026

Base f00356d, com correção de linha de visão descrita abaixo. Teste local real de servidor e dois clientes: Player1 Guardião, Player2 Explorador. Arte/vegetação e HUD da revisão atual presentes.

### Defeito reproduzido e corrigido

O raio antigo atingiu `Workspace.Player1.UpperTorso` entre Explorador e Sentinela, impedindo o ataque. EnemyService agora exclui os personagens aliados do filtro, mantendo o cenário. Regressão: disparo através da posição do aliado reduziu Sentinela de 120 para 96. Um primeiro ensaio de parede foi inconclusivo porque o inimigo atravessou a posição da barreira; foi repetido com distância e raio confirmados. No ensaio válido, o raio atingiu `Workspace.CoopLOSWall`, RuneMoss ficou em 120 após Q e morreu somente depois de remover a barreira e atacar. Barreira temporária removida; nenhum objeto de teste incorporado à cena/código.

### Passagem em dupla

- Ilyra: ambos em quest 2, classes Guardian/Explorer e saúde 150/110.
- Sentinela: Guardião usou Égide, Explorador atacou; ambos avançaram a quest 3 com 25 moedas. Apoio concedeu crédito mesmo sem golpe do Guardião.
- Cada jogador leu Dawn/Root/Star após as derrotas compartilhadas: ambos em quest 4, três inscrições e 65 moedas.
- Selos individuais: Player1 Dawn=1; Player2 Root primeiro foi rejeitado e permaneceu em 0, sem apagar Player1. Ambos completaram a sequência e chegaram a quest 5/100 moedas.
- Morte induzida apenas para teste no Player2: reapareceu no checkpoint Temple com Explorer, 110 HP, três inscrições, quest 5 e 100 moedas. Progresso não foi alterado manualmente.
- Ambos atravessaram o limiar. Chefe escalou de 1800 para 2900 HP; sequência observada 2801 → 2354 → 1889 → 1394 (fase 2) → 761 → 68 → 0. Ambos receberam BossDefeated=true.
- Combate por Q/R com deslocamento automatizado usando Humanoid.MoveTo em percursos circulares. Não houve mudança direta de vida, dano, velocidade, moedas ou progresso para vencer. Essa automação não aprova dificuldade/duração para público real.
- Ambos recolheram fragmento, receberam epílogo/conclusão, quest 6, HasFragment=true, checkpoint Village e 200 moedas. Repetir coleta manteve 200 para cada um. Retorno pela pedra levou ambos ao Vale e preservou a conclusão.
- Snapshot final foi capturado após o chefe reaparecer (40 segundos): seus atributos já voltaram a 1800; as flags individuais de vitória/conclusão permaneceram. Não interpretar esse snapshot como estado instantâneo da derrota.
- Pedidos de classe Admin e troca posterior para Artificer foram rejeitados; vinte remotes com alvo/dano/saldo falsos não afetaram chefe distante, classe Explorer ou saldo real 25. Atributo Coins alterado só no cliente foi restaurado e não mudou o saldo do servidor.
- Sem erro de execução do jogo identificado no servidor; houve erros externos de meshes/animações e ícones de plugin.

### Medida aquecida após a nova vegetação

600 frames durante combate cooperativo no cliente Guardião: média 60,0006 FPS, mediana 59,9808, percentil lento 55,7063; memória total reportada pelo cliente Studio 2348 MB. Desktop com servidor/dois clientes locais, não medição de celular nem estimativa de memória do aplicativo publicado.

### Realistic Lighting

LightingStyle estava Soft. Agora o projeto Rojo serializa LightingStyle=Realistic e PrioritizeLightingQuality=true em `default.project.json`. Não configurar LightingStyle em script de runtime: o Studio atual exige capacidade de plugin para escrita. Uma tentativa inicial no WorldBuilder falhou, foi removida e o novo Play confirmou mapa pronto sem erro.

Vista do vale comparada em RenderSettings.QualityLevel Level01 e Level21, sem mover o personagem e com HUD oculto apenas para inspeção artística. 300 frames em cada amostra: baixa média 59,9963 / mediana 60,0777 / percentil lento 55,6081; alta média 60,0035 / mediana 60,1594 / percentil lento 55,6068. Não é benchmark de GPU móvel nem promessa de fotorealismo. Qualidade automática, câmera Custom e HUD foram restaurados após o teste.

Após essa configuração, Play com Guardião confirmou Ilyra → Sentinela → quest 3 e 25 moedas, sem novo erro do jogo. A passagem cooperativa completa precedeu somente essa troca de iluminação; não houve mudança adicional de combate.

Pendências atuais: realismo/modelagem/animação final, teste humano de naturalidade e duração, aparelho móvel físico e persistência real. Escala de seis jogadores está implementada, mas a execução completa foi testada com dois.

## Regressão G0 e personagens humanizados — 03/11/2026

Branch feature/cpp-001-003-bootstrap sobre ba19522. Backup do lugar antes das mudanças: `~/Projetos/portal-perdido-backups/portal-perdido-g0-backup-20261103.rbxl`.

**G0 aprovado no Studio para as três classes**, cada uma em Play separado com interface real (pular prólogo e escolher classe por clique), teclas reais (W/Espaço, E, Q, R) e navegação do personagem:

| Classe | HP | Ilyra → missão 2 | Sentinela | Missão/moedas | Erros Luau |
| --- | --- | --- | --- | --- | --- |
| Guardião (avatar padrão, antes do template) | 150 | sim | 0 HP | 3 / 25 | 0 |
| Explorador | 110 | sim | 0 HP | 3 / 25 | 0 |
| Artífice | 100 | sim | 0 HP | 3 / 25 | 0 |
| Guardião humanizado | 150 | sim | 0 HP | 3 / 25 | 0 |

- Animações nativas voltaram a carregar (`PortalFallbackActive=false`, faixas do Animator tocando); o HTTP 403 de 02/11 não se repetiu nesta sessão.
- Único aviso: `rbxassetid://203785492` (já documentado, origem externa).

Mudanças:
- Ilyra humanizada aprovada e ativa (ver `ILYRA_VISUAL_REVIEW.md`): sinal dos ombros corrigido, gesto de fala, retrato do diálogo enquadrando o rosto.
- Guardião humanizado gerado, exportado e integrado (ver `GUARDIAN_RIG_QA.md`).
- Modelos de revisão que apareciam no caminho do spawn movidos para `ServerStorage.ReviewArchive` (mudança apenas na cena do Studio).

Pendente: captura visual do Guardião em jogo (o renderizador do Studio entrou em estado branco após a geração), passagem completa do capítulo com os novos modelos, aparelho móvel físico e persistência publicada.

### Passagem completa com o Guardião humanizado — 03/11/2026

Play solo, classe escolhida pela interface real. Movimento por `Humanoid:MoveTo`, ataques/habilidade/esquiva pelos mesmos RemoteEvents que Q/R/Shift disparam, prompts por `InputHoldBegin/End`, diálogos fechados pelo botão real (dois intermediários ocultados no cliente — sem efeito no servidor). Nenhuma alteração direta de vida, dano, moedas ou progresso para vencer.

1. Ilyra → missão 2. Sentinela → missão 3, 25 moedas.
2. RuneMoss/RuneThorn/RuneWisp derrotados; Dawn/Root/Star lidas → missão 4, 65 moedas.
3. Selo Raiz primeiro: rejeitado ("A sequência se desfez"), progresso 0. Aurora → Raiz → Estrela → missão 5, 100 moedas, checkpoint Temple.
4. Limiar → Arena. Chefe 1800 HP: 1800 → 1410 → 1050 → 690 (fase 2) → morte do jogador; renasceu na Arena com Guardian, rig gerado, 5 peças de equipamento, missão 5, 100 moedas, 3 inscrições; chefe manteve 630 HP. Segunda morte em 240; terceira tentativa: 240 → 120 → 0. BossDefeated=true.
5. Fragmento → missão 6, HasFragment=true, 200 moedas, checkpoint Village. Repetição manteve 200. Epílogo fechado pelo botão real → tela de conclusão visível.
6. Zero erros Luau no cliente e no servidor.

**Defeito encontrado e corrigido:** ao renascer na Arena (que fica toda dentro do raio de 48 studs do chefe), o jogador levava dano antes de agir (150 → 96 em 1,5 s; outra vez começou com 42). `ClassService` agora adiciona `ForceField` "SpawnGrace" por 4 s ao posicionar no checkpoint. Validação com morte induzida só para teste: SpawnGrace presente, `TakeDamage(40)` manteve 110/110, proteção removida após 4,5 s e `TakeDamage(10)` → 100. Classe e rig preservados.

A automação não aprova dificuldade/duração para público real; as três mortes indicam que o chefe exige atenção à esquiva, o que precisa de avaliação humana.

## Acabamento visual de equipamentos e seleção — 03/11/2026 (após reinício do Studio)

Studio reiniciado pelo usuário; lugar salvo como "Primeira Fase - As Cronicas do Portal Perdido.rbxl". Renderização normal. Capturas confirmaram o Guardião humanizado em jogo (cabelo dourado, armadura prateada com filetes dourados, túnica azul).

Revisão por captura, com correções em `Art.equipment` e `GameClient`:

- **Espada do Guardião** saía do punho na direção do antebraço, com o pomo além dos dedos (visível no golpe). Agora é montada no próprio eixo e encaixada no punho fechado; lâmina fina com sulco e ponta, guarda com remates, punho de couro e pomo. Em repouso fica abaixada à frente; no golpe Q sobe empunhada.
- **Escudo** trocado de elipsoide com barra neon para escudo redondo azul real com aro dourado, estrela de oito pontas (elipsoides afiladas) e gema central na cor da classe.
- **Aljava do Explorador**: cilindro escuro grande e solto virou aljava de couro nas costas, na diagonal, com aro e três flechas emplumadas.
- **Foco da Artífice**: esfera neon grande que estourava no Bloom virou cristal pequeno (núcleo neon dentro de vidro translúcido) com PointLight suave, flutuando junto aos dedos e fora do casaco. O offset foi medido no Play (eixos da mão do rig gerado são girados em repouso). Grimório agora pende no quadril com páginas e fecho.
- **Tela de seleção**: os retratos usavam bonecos de blocos. O servidor publica `ReplicatedStorage.ClassPreviews` (cópias ancoradas dos rigs, sem Humanoid/scripts, com equipamento) e o cliente troca o boneco por close de rosto quando disponível; o boneco antigo permanece como contingência.
- Retrato do diálogo da Ilyra confirmado por captura (rosto enquadrado).

Regressão após as mudanças: Artífice escolhida pela interface → Ilyra (missão 2) → Sentinela (missão 3, 25 moedas); 60 FPS no desktop; zero erros Luau. Memória total do processo do Studio 3996 MB após várias sessões de Play — não representa o app em celular.

## Abertura sem personagens antigos — 03/11/2026

Relato do usuário: ao iniciar no Studio, apareciam os personagens antigos até a escolha de classe. Reproduzido: durante prólogo e seleção, o avatar padrão do Roblox (blocos) ficava no caminho da vila, e os cards da seleção mostravam por um instante os bonecos procedurais antes dos retratos humanizados.

Correções:
- `ClassService`: sem classe escolhida, o avatar padrão fica invisível (partes e decals, inclusive acessórios que chegam depois — segunda passada após 1 s), ancorado e sem nome exibido (`AwaitingClass=true`). A escolha troca pelo rig humanizado. Se faltar template, a visibilidade original é restaurada como contingência.
- `AvatarFallback` não cria cascas visíveis sobre um avatar em `AwaitingClass`.
- Cards da seleção nascem com o retrato humanizado; o boneco procedural só aparece se `ClassPreviews` não chegar em ~6 s.
- `SpawnGrace` continua protegendo em todo posicionamento, mas a bolha só é visível fora da vila (respawn em combate).
- Avisos (toasts) não aparecem sobre o texto do prólogo.

Evidência (Play): durante o prólogo 0 partes visíveis do avatar, raiz ancorada; cards com Guardian/Explorer/Artificer como MeshPart desde a abertura; após escolher Explorador, rig gerado visível (28/32 partes; 4 âncoras do arco são invisíveis por design), solto, 110 HP, proteção sem bolha; aviso do objetivo oculto durante o prólogo; zero erros. As capturas do MCP nesta etapa saíram brancas (janela do Studio sem foco); a confirmação visual fica para o usuário.

## Chefões finais das regiões 2–4 — 07/11/2026

Motivo: o commit `38f908a` passou a exigir o chefão de cada região para abrir a passagem, mas Abismo, Deserto e Cidadela não tinham chefe — a campanha travava depois do Vale (Rota A) e o Arauto nunca liberava (Rota B).

**Implementado:**
- `Chapter.EnemyTypes`: Colosso de Cristal (2000 HP + 1100/jogador), Guardião das Horas (2200 + 1200), Cavaleiro do Eclipse (2400 + 1300). Reutilizam a IA do Arauto (`ai="Herald"`: golpes em área telegrafados, onda ao redor, fases em 60% e 25%, reforços na fase 2), com textos de fase próprios.
- Encontros nos slots `BossArena` de cada construtor, com `vision` da região: ao cair, disparam a visão do Regente e `onBossDefeated` (Rota A: `profile.phase` e desbloqueio de herói; Rota B: ramo resolvido).
- `Art.enemy`: visual procedural original por região (cristais no Abismo; ampulheta e disco solar no Deserto; sol negro, crista e lâmina na Cidadela).
- HUD: barra de chefe genérica para qualquer criatura com `BossBar` (título em `BossTitle`).

**Testado no Studio (Play solo, Rota A, Guardião):**
- Os três chefes nascem sobre o piso das arenas (CathedralFloor 130,4; ArenaFloor 30,4; CourtyardFloor 26,4).
- Abismo: IA atacou ao aproximar; dano via `QAFixtures.hurtEnemy` (atalho de QA, não combate manual) → fase 2 em 1100/2000, fase 3 em 350, derrota; 4 reforços; visão `CrystalAbyss`; `CampaignPhase=2`; Arcanista desbloqueado.
- Passagem do Abismo pelo ProximityPrompt real → Deserto. Passagem do Deserto com chefe vivo: recusada ("A passagem só desperta quando o guardião desta região for vencido.").
- Barra de vida perto do Guardião das Horas: "GUARDIÃO DAS HORAS · FASE 1 2100 / 2200".
- Zero erros Luau no servidor e no cliente.

**Pendente:** combate manual completo contra cada chefe (dificuldade/duração por avaliação humana), Rota B com 4–6 jogadores, Deserto e Cidadela até a derrota, reforços que continuam vivos após a queda do chefe (mesmo comportamento do Arauto), arte gerada/final dos chefes, aparelho móvel físico.

## Monstros exclusivos por região e combate dinâmico — 07/11/2026

Pedido do proprietário: cada mundo com monstros próprios; chefões que sejam monstros de verdade (não bonecos de esferas); todos chutando com combinações (pular + chutar, agachar, rasteira); Lutador com golpes diferenciados e mais fortes.

**Implementado:**
- 9 criaturas geradas (generate_mesh, partes nomeadas e articuladas em `Art.GENERATED`):
  - Abismo de Cristal: Aranha de Cristal, Morcego Prismático; chefão **Wyrm de Cristal**.
  - Deserto das Horas: Escorpião das Areias, Chacal das Dunas; chefão **Esfinge das Horas**.
  - Cidadela do Eclipse: Cão Sombrio, Gárgula do Eclipse; chefão **Dragão do Eclipse**.
  - Comportamento reaproveitado por arquétipo (`stats.ai`: Thorn corpo a corpo, Wisp à distância, Herald para chefões); `MotionKind` escolhe as poses no cliente.
- `Chapter.RegionFauna`: encontros comuns nascem nos slots `Encounter` de cada construtor (líder + 1–2) e os reforços usam a fauna da região. A Convergência mistura criaturas dos quatro mundos. Antes os reforços eram sempre Predador/Eco do Vale.
- Chutes para todas as classes (`Kick` com variante validada no servidor): frontal (14), **chute voador** (no ar, medido por raycast; 20, avanço e atordoamento) e **rasteira** (agachado; 12, arco largo, derruba todos à frente). Recarga 1,8 s (Lutador 1,0 s e dano dobrado).
- Agachar: Ctrl (segurar), L3 no controle ou botão AGACHAR (toque alterna). Velocidade 7, sem pulo; pular levanta. Replicado como atributo `Crouching`.
- Lutador: dano 24 → 36, vida 140, combo de 4 com Punho Solar, Martelo Solar (no ar), Gancho Ascendente (agachado), Chute Sombra 55 → 75. Nome do golpe especial flutua sobre o personagem.
- Atordoamento: criaturas comuns ficam paradas (estrelas + meia queda); chefões apenas ficam lentos.

**Testado no Studio (Play):**
- 9 tipos novos nascem com o modelo gerado (`GeneratedCreature=true`), com a cabeça para −Z; contagem por tipo coerente com os slots; zero erros/avisos Luau.
- Guardião contra Aranha de Cristal: frontal 140→126; agachado (WalkSpeed 7) + rasteira 126→114 com atordoamento; chute voador em Freefall 114→94 com atordoamento; pedido de "jump" sem estar no ar e de "sweep" em pé viram chute frontal.
- Lutador contra o grupo do aqueduto: socos 36/39/46 e Punho Solar 141 em área; Gancho Ascendente e Rasteira Solar (24) acionados; ataques "air" sem estar no ar viram combo normal.
- Capturas: Wyrm na catedral; Escorpião, Chacal e Esfinge no deserto; poses de agachar e rasteira.
- Para o teste a vida do jogador foi elevada a 5000 (somente QA, não persistido).

**Pendente:**
- **Salvar o lugar (Ctrl+S)** e exportar os 9 `*Template` de `ServerStorage` para `assets/characters/models/` (Save to File) e mapear no `default.project.json`. Até lá existem só no lugar do Studio; sem eles o jogo usa a contingência procedural.
- Avaliação humana das poses (agachar, rasteira, chute voador, golpes do Lutador) — ângulos estimados, não calibrados como os do Guardião.
- Dificuldade dos grupos regionais (o Guardião com 150 HP caiu para o grupo da ilha-pilar), monstros da fase 6, celular físico.

## Luta final contra o Regente, novo Arauto e equilíbrio solo — 07/11/2026

**Implementado:**
- **Regente do Vazio (fase 6)** no Átrio da fortaleza: rig gerado `RegentTemplate` (o mesmo das visões) em escala 3×, **sem capuz** pela primeira vez. 3200 HP + 1600 por jogador; IA do Arauto + **Passo do Vazio** (fase 2+: marca o chão por 0,7 s, some e reaparece junto do alvo com um golpe). Três falas de fase. Reforços da fauna do Domínio (Cão Sombrio, Morcego, Gárgula).
- Derrota do Regente: `CampaignPhase=6` (Rota A) / ramo resolvido (Rota B) e tela **CAMPANHA CONCLUÍDA — O PORTAL PRIMORDIAL** com epílogo original (o portal se abre para o ginásio; a coroa caída ainda pulsa).
- `Art.buildGenerated` aceita rigs R15 (`humanoidRig`): remove motores/Humanoid/HRP do template e solda acessórios ao tronco; alinha pela caixa, não pelo pivô.
- **Arauto Partido** deixou de ser o boneco de esferas: não existia `HeraldTemplate`, então caía no procedural. Agora é uma criatura alada gerada (cristais, olho violeta, halo dourado partido).
- **Equilíbrio solo:** no máximo 2 criaturas comuns iniciam golpes contra o mesmo jogador ao mesmo tempo (as outras rodeiam e esperam); reforços 1 sozinho / 2 em grupo / 3 com 5–6.
- Modelo antigo "Towering armored fantasy knight…" que estava solto no caminho da floresta (−6, 2, −272) movido para `ServerStorage.ReviewArchive.HeraldKnightRig_unused` (mudança só na cena do Studio).

**Testado no Studio (Play):**
- Regente nasce no `AtriumFloor` (y 332) após corrigir a altura de partida do raycast (`groundFromY`); Arauto com modelo gerado; zero erros/avisos Luau.
- Lutador: **Martelo Solar** confirmado (Freefall, 57 de dano por golpe no Regente, duas vezes).
- Regente: fase 1 → 2 (1786) → 3 (586) → 0; três falas, reforços, `CampaignPhase=6`, tela final visível com o título certo.
- Passo do Vazio: em fase 2, com o jogador a 24 studs, `CastKind=VoidStep` aos 2 s, evento `blink`, distância 17 → 8.
- Captura: Regente coroado e sem capuz no átrio, barra "O REGENTE DO VAZIO · FASE 2", Cães Sombrios de reforço, Portal Primordial ao fundo.
- Dano aos chefes por atalho de QA; vida do jogador elevada só para o teste.

**Pendente:** salvar o lugar e exportar `HeraldTemplate` e os 9 templates de fauna; luta manual completa contra o Regente (dificuldade/duração por pessoa); efeito visual do Passo do Vazio no cliente além do rastro `blink`; o que acontece depois do epílogo (Portal Primordial como saída).

## Celular: controles de toque configuráveis — 07/11/2026

Pedido do proprietário: preparar o jogo para celular e permitir configurar os comandos de toque.

**Implementado:**
- **Editor de controles** (Diário → CONTROLES): arrastar cada botão de ação (Atacar, Habilidade, Chutar, Pular, Esquiva, Agachar, Defender), TAMANHO −/+ (0,6×–1,8×; no botão selecionado ou em todos), OPACIDADE −/+ (35–100%), PADRÃO, CANCELAR e SALVAR. Durante a edição nenhuma ação dispara. Módulo `src/shared/TouchControls.luau`.
- **Persistência e validação no servidor:** remote `SaveControls` (limite de 1 envio a cada 2 s) → `ControlLayout.sanitize` (ids conhecidos, números finitos, faixas limitadas) → `profile.controls` → atributo `ControlLayout` (JSON). `ProfileStore.sanitize` mantém o layout válido e descarta um inválido **sem** rejeitar o perfil. O layout só é aplicado no toque; teclado/controle mantêm o padrão.
- **Botão PULAR próprio** no toque, dentro do layout configurável; o pulo padrão do Roblox fica escondido para não sobrepor os botões. Pulo + Chutar continua gerando o chute voador.
- `ScreenInsets = DeviceSafeInsets` no HUD (entalhes e barras do aparelho).

**Testado no Studio:**
- Editor aberto pelo botão real do Diário (cliques reais de mouse); PULAR arrastado para a esquerda, selecionado (contorno azul) e ampliado; barra de ferramentas visível.
- `SaveControls`: layout válido gravado e publicado no atributo; id desconhecido ignorado; valores fora da faixa limitados (posição 0,97/0,05; tamanho 1,8; opacidade 0,35).
- `tests/ProfileStore.spec.luau` executado no Studio: **10/10 casos**, incluindo o novo caso do layout de controles.
- Zero erros Luau no cliente e no servidor.
- Corrigido durante o teste: o handler do botão CONTROLES chamava `setBlock` antes de ele existir ("attempt to call a nil value").

**Não testado / limitações:**
- O clique simulado em SALVAR na 2ª fileira da barra não registrou (a ferramenta de mouse não desconta a margem superior do Roblox); o salvamento foi validado pelo mesmo remote. Confirmar tocando em SALVAR no aparelho.
- Aplicação do layout salvo com toque real e o pulo padrão escondido: o Studio via MCP não emula toque. Testar no Emulador de Dispositivos do Studio e num celular físico.
- No Studio o progresso é temporário (sem DataStore), então a persistência entre sessões só aparece em servidor publicado.

## Modelos versionados como dados, objetivos por região e dicas de controle — 07/11/2026

**Implementado:**
- `src/server/services/CreatureMeshes.luau`: os 10 templates gerados (9 criaturas + Arauto) versionados como dados — asset da malha, textura, tamanho e CFrame relativo de cada parte. No início do servidor, `ensure()` reconstrói com `AssetService:CreateMeshPartAsync` os que faltarem no `ServerStorage` (lugar sem salvar, build do Rojo, servidor novo). Templates já presentes têm prioridade. **Isto resolve a pendência de exportar os .rbxm das criaturas.** Continuam fora do Git os rigs R15 (`RegentTemplate`, `BrawlerTemplate`, `ArcanistTemplate`, `ShadeTemplate`).
- HUD das regiões 2–6: "FASE n / 6 · título" com objetivo da região e texto de conclusão depois do chefão (`Campaign.Objectives`; Rota A por `CampaignPhase`, Rota B por `Resolved_<região>`). Antes aparecia "A TRAVESSIA · CONCLUÍDA — explore o vale" em qualquer região. No Vale concluído, o objetivo aponta a Passagem da Aurora.
- Tela de seleção: dica de controles atualizada (chutar, agachar, chute voador, rasteira); no toque, explica os botões e o Diário › Controles.

**Testado no Studio (Play):**
- Removidos `CrystalSpiderTemplate` e `HeraldTemplate` da cópia do Play → `ensure()` reconstruiu os 2 em 2,2 s com as mesmas dimensões; `Art.templateReady` verdadeiro; Aranha criada pelo caminho normal com textura completa (captura).
- Explorador no Abismo: "FASE 2 / 6 · O CRISTAL QUE LEMBRA — Atravesse as pontes…"; após o Wyrm cair (atalho de QA): "O Wyrm caiu. Siga pela Passagem de Cristal…".
- Zero erros/avisos Luau no cliente e no servidor.

## Poses revisadas por captura, final da campanha e reserva do Regente — 07/11/2026

**Poses (CharacterMotion) — revisadas por captura com a animação congelada no meio:**
- **Defeito encontrado:** nos rigs gerados (AnimationConstraint) X+ no quadril leva a coxa para a FRENTE. Com o sinal estimado (X−), o **chute frontal saía para trás** (defeito antigo, anterior a esta sessão), o chute voador parecia ajoelhado no ar e o agachar parecia ajoelhar. Corrigidos os quadris de: chute frontal (`Br_Chamber`/overlay), chute voador, rasteira, agachar (`Motion.Crouch`) e `Br_Low`.
- Gancho Ascendente: punho sobe à frente do rosto com o cotovelo dobrado (antes o braço ia esticado para trás, como comemoração).
- Martelo Solar: dois punhos juntos golpeando à frente e para baixo (antes os braços pendiam).
- Rasteira: perna mais baixa, rente ao chão.
- Conferidos em captura: chute frontal, chute voador, agachar, Punho Solar, Gancho Ascendente e Martelo Solar com o Lutador; rasteira com o Guardião (convenção válida em outro rig).

**Final da campanha:**
- Portal Primordial (após o Regente): leva ao Vale com "Por um instante, vocês veem o ginásio da escola do outro lado do portal…" (antes: "O caminho de casa ainda está selado", contraditório com o epílogo).
- Ilyra: falas de encerramento quando `phase ≥ 6` e indicação da passagem quando `phase ≥ 1` (o epílogo do Vale continua ao recolher o fragmento).
- Testado: portal pelo prompt real → Vale com a mensagem; diálogo da Ilyra com a fala nova.

**Rigs humanoides (pendência de versionamento):**
- `RegentTemplate`, `BrawlerTemplate`, `ArcanistTemplate` e `ShadeTemplate` têm ossos (malha deformável), AnimationConstraints, SurfaceAppearance (PBR), WrapTarget e FaceControls. O mapa do SurfaceAppearance não pode ser definido por script em tempo de execução, então **não** dá para versioná-los como dados como as criaturas. Continuam dependendo do lugar salvo ou de `.rbxm` exportado manualmente (Save to File).
- Mitigação: sem o `RegentTemplate`, o Regente da fase 6 usa a figura procedural das visões (`VillainArt.regent`, escala 3,1, ~27 studs) em vez do corpo de pedra genérico. Testado removendo o template no Play: 59 peças, sem erro. Os heróis já tinham reserva procedural.
