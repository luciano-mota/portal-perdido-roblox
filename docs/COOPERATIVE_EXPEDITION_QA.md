# Expedição cooperativa — 04/11/2026

Branch `feature/cpp-001-003-bootstrap`, PR #30. Implementação posterior a e9c2ffd.

## Regras implementadas

- Ilyra inicia a expedição com pelo menos três jogadores de classe escolhida; seis recomendados. A sessão continua se alguém sair depois do início. Ainda não há matchmaking nem reinício formal de expedição.
- Inimigos patrulham antes da aproximação. O primeiro dano chama uma única leva finita: dois reforços com três/quatro prontos, três com cinco ou mais. Reforços não chamam outros reforços e mortos não renascem.
- Objetivo de encontro só termina após líder e reforços morrerem. Guia aponta para reforços sobreviventes.
- Avanço narrativo contempla companheiros vivos a menos de 100 studs do último inimigo, inclusive suporte sem dano. Recompensa continua individual e idempotente. Conversar com Ilyra recupera a etapa do Sentinela se o encontro já terminou.

## Teste real: servidor e três clientes locais

- Guardião, Explorador e Artífice escolhidos pela interface; conversa por ProximityPrompt; caminhada por Humanoid.MoveTo, sem preparar HP, moedas ou progresso.
- Rodada inicial: bloqueio em 1/3 e 2/3; início em 3/3. Patrulha distante deslocou 1,296 studs em dois segundos.
- Reprodução revelou que companheiros sem dano permaneciam na missão 2. Corrigido crédito de presença e repetido em nova sessão.
- Nova rodada: somente Guardião atacou; Sentinela e dois reforços terminaram com HP 0. Os três ficaram na missão 3, com 25 moedas cada. HP final: Guardião 75, Explorador 110, Artífice 100.
- Nenhum MessageError no servidor ao terminar essa rodada.

## Limites

Este teste aprova o primeiro encontro e o avanço compartilhado, não o equilíbrio do capítulo inteiro. Ainda é necessário completar runas, templo e chefe com três e seis participantes, testar desconexões/reentrada e medir aparelhos móveis físicos. Testes automatizados de movimento não substituem avaliação humana do desafio.

## Rodada com seis clientes: defeitos encontrados

- Seis classes escolhidas, seis jogadores na missão 2. Primeiro golpe chamou três reforços, sem chamadas recursivas.
- Chute: 30 chamadas simultâneas, incluindo argumento de dano indevido, causaram somente 12 pontos (120 → 108). O servidor ignora argumentos e impõe 2,4 s de intervalo, alcance 7 e cone frontal. Impacto atrasado 0,22 s; chefe não recebe lentidão.
- Gesto inicialmente ausente: mensagem do chute não continha posição, exigida pelo filtro de distância dos efeitos. Corrigido payload; reteste visual necessário.
- Encontro travou com criaturas sobrepostas: raios de visibilidade atingiam Root de outro inimigo, inclusive para o alvo mais próximo. Confirmado por raycasts no servidor. Filtro agora exclui a pasta de criaturas e personagens aliados, mantendo terreno/props/paredes como cobertura. Reteste necessário antes de aprovar a rodada.

## Reteste em nova sessão com seis clientes

- Corrigido filtro de visibilidade e posição do evento de chute. Caminhada por pathfinding/MoveTo e ataques pelos RemoteEvents normais; sem conceder HP, dano, progresso ou moedas artificialmente.
- Sentinela e três reforços chegaram a HP 0. Quatro jogadores avançaram imediatamente; dois reapareceram no início e recuperaram a etapa conversando com Ilyra.
- Resultado final dos seis: QuestIndex=3, Coins=25. Conversa adicional manteve 25. Criaturas continuaram mortas nas consultas seguintes, sem novas levas.
- Chute disparado no cliente: PortalKickStarted registrado e transformação do RightHip mudou durante o golpe (componente de rotação ~1,16 rad em 0,25 s). Isso comprova acionamento da articulação, **não aprovação estética final**.
- Nenhum MessageError no servidor e em cada um dos seis clientes na consulta final.
- UI inclui CHUTAR [C] e botão touch 100×48; teclado Espaço continua sendo salto nativo. Revisão visual em tela pequena e teste de obstáculos/alcance do chute ainda necessários.
