# Conclusão do capítulo após novos ataques — 03/11/2026

Base b08d291, branch feature/cpp-001-003-bootstrap, PR #30. Studio local, PlaceId 0.

## Passagem com Artífice

Seleção pela interface e movimentação por Humanoid:MoveTo/Pathfinding, contornando obstáculos quando necessário. Combate pelos RemoteEvents reais de ataque/habilidade, respeitando validação e cooldown do servidor. Interações pelos ProximityPrompts. Sem alteração de HP, vida de inimigos, moedas, flags ou etapa de missão por scripts de teste. Não é uma passagem humana nem benchmark de duração.

1. Ilyra → Sentinela: missão 3, 25 moedas, 100 HP.
2. Inscrição Aurora após derrotar RuneMoss; Artífice ficou com 46 HP. Fonte da floresta restaurou 100 HP e registrou checkpoint.
3. RuneThorn e RuneWisp derrotados; inscrições Raiz/Estrela registradas: missão 4, 65 moedas.
4. Selos Aurora → Raiz → Estrela: missão 5, 100 moedas. Dano recebido na região deixou 61 HP.
5. Primeiro acionamento do limiar com 61 HP: ThresholdWarned=true, permaneceu fora da arena e recebeu orientação da Fonte de Lúmen. Fonte do templo restaurou 100 HP. Novo acionamento levou à arena.
6. Guardião de Raízes: 1800 HP; passou para fase 2 e chegou a 0. A automação sofreu três mortes; retomou pelo checkpoint e terminou com BossDefeated=true. O chefe manteve dano entre retomadas rápidas. Isso confirma conclusão com tentativas, não vitória sem mortes nem dificuldade aprovada.
7. Fragmento recolhido: QuestIndex=6, HasFragment=true, Coins=200. Repetir coleta manteve 200. Epílogo fechado pela interface e Ending.Visible=true. Sem MessageError no cliente ao final.

## Correção de colisão após derrota

A rotina de morte desativava CanQuery e escondia a arte, mas mantinha CanCollide no corpo lógico até respawn (30/40 segundos). Corrigido para desativar CanCollide e CanTouch imediatamente. O alvo já era excluído do combate por Health=0.

Regressão em nova sessão: Artífice derrotou FirstSentinel por ataques reais; servidor confirmou Health=0 e CanCollide/CanTouch/CanQuery=false, sem MessageError. No respawn natural, o novo Sentinela voltou com 120 HP e CanCollide=true. Build Rojo e diff --check concluídos; Play encerrado em Edit. A passagem completa acima ocorreu antes desta correção pontual.

## Pendências mantidas

- Equilíbrio do chefe com jogador humano: três mortes na automação e dano persistente entre tentativas precisam ser avaliados como experiência, sem reduzir dificuldade com base só na automação.
- Cooperação com novos modelos, avaliação visual final, mobile físico, persistência real e loja.
- Caminhos tiveram contornos manuais e falhas de Pathfinding em pontos próximos às inscrições/altar. Não atribuir toda falha de rota à colisão do cadáver; outras geometrias ainda precisam de revisão visual.
- Sem publicação ou ativação de compras.
