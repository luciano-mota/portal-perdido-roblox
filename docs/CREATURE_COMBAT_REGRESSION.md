# Regressão de combate das criaturas — 03/11/2026

Base: 534a1e2, branch feature/cpp-001-003-bootstrap, PR #30. Studio local Primeira Fase - As Cronicas do Portal Perdido.rbxl, PlaceId 0.

## Falha reproduzida e correção

O cipó escolhia a vítima antes do voo e a puxava depois de aguardar o trajeto, sem conferir novamente sua posição, esquiva ou personagem. No teste real com Guardião, uma esquiva lateral enviada ao receber o lançamento ainda terminava em captura e danos de 4 + 10: HP 150 → 136.

EnemyService agora revalida o personagem, elegibilidade, faixa do cipó, esquiva e linha de visão na chegada. Durante o puxão, verifica morte, troca de personagem, esquiva e obstáculos antes de cada deslocamento. Só aplica dano e encadeia raízes se o puxão terminar. Não altera alcance, dano ou cooldown.

## Evidências após a correção

Guardião selecionado pela interface, caminhando do spawn ao primeiro Sentinela. Cada cenário abaixo começou em uma nova sessão:

| Cenário | Resultado |
| --- | --- |
| Esquiva lateral após lançamento | Evento de lançamento observado; sem captura/dano; HP 150. |
| Esquiva ao começar o puxão | Eventos vine e snare observados; esquiva interrompeu o puxão; sem dano; HP 150; WalkSpeed 16. |
| Sem esquiva | Cipó capturou, causou 4 de dano e encadeou raízes com 10; HP 136. |

As esquivas foram acionadas pelo RemoteEvent real a partir de um observador temporário de eventos no cliente para reproduzir o instante exato. Não alteramos vida, dano, cooldown ou progressão para aprovar os resultados. Não é teste humano de tempo de reação.

## Outros encontros

Posicionamento controlado por PivotTo em Play, sem alterar HP ou progressão, para isolar os inimigos:

- ForestThorn: sequência observada bite → claw → bite; danos 12, 10 e 12. O Predador continuou se movendo em torno do jogador.
- TempleWisp: teleporte observado pelo evento real, distância 11 studs; ataque à distância também produziu dano 13. O jogador morreu durante a permanência nos encontros e reapareceu como Guardião com 150 HP antes do teste final do teleporte.
- LogService ao final: nenhum MessageError no cliente ou servidor. Play encerrado.
- Build Rojo e git diff --check concluídos.

## Limites

Esta revisão valida resposta funcional do cipó, mordida/garras e teleporte; não aprova aparência final das animações, desempenho mobile, equilíbrio humano ou passagem integral. Parede durante puxão e troca de personagem durante voo têm proteção implementada, mas ainda precisam de cenários dedicados. Não houve publicação nem ativação de compras.
