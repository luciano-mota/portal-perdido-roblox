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
