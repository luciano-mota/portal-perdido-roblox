# Plano até o lançamento — Capítulo 1: A Travessia

Atualizado em 03/11/2026. Fonte de verdade do andamento: commits/PR #30 e `DEVELOPMENT_STATUS.md`. Este arquivo ordena o que falta e quem precisa agir.

## Onde estamos

| Área | Estado |
| --- | --- |
| Ciclo jogável (G0) | **Aprovado no Studio** para as três classes. |
| Capítulo completo (G3) | **Concluível solo** no Studio com Guardião humanizado e chefe gerado (missões, inscrições, selos, chefe 2 fases, fragmento, conclusão). Dupla testada antes da arte nova. |
| Personagens | Ilyra, três classes e **todas as sete criaturas** humanizadas/geradas (03/11). |
| Abertura | Sem avatar padrão nem bonecos antigos (corrigido hoje). |
| Persistência (G1) | Protocolo testado com adapter; **sem DataStore real** (lugar não publicado). |
| Mobile / desempenho (G4) | Emulador e desktop medidos; **sem aparelho físico**. |
| Monetização (G5) | Modelo definido em `MONETIZATION_DESIGN.md`; **sem código de compra nem produtos criados**. |

## Prioridades

### P0 — sem isso não lança

| # | Item | Quem | Depende de |
| --- | --- | --- | --- |
| 1 | ~~Predador de Espinhos e Eco do Vazio gerados e articulados~~ **feito 03/11** | Claude | — |
| 2 | Equilíbrio do chefe: automação morreu 2–3 vezes; revisar dano da fase 2, aviso das marcas e lembrete da fonte do templo antes do limiar | Claude + teste humano | 1 |
| 3 | Passagem completa jogada por pessoa (desktop) com anotação de tempo, mortes e pontos confusos | **Usuário** | 1–2 |
| 4 | Cooperação 2+ jogadores com os modelos novos (Studio: Test → Clients and Servers) | **Usuário** abre; Claude analisa | 1 |
| 5 | Publicar como **experiência privada** (sem acesso público) para habilitar DataStore real, compras de teste e telemetria | **Usuário** (decisão de conta) | — |
| 6 | Persistência real: salvar/recarregar classe, missão, moedas e conclusão em duas sessões; falha de rede | Claude | 5 |
| 7 | Aparelho móvel físico: FPS, memória, toque, legibilidade | **Usuário** (aparelho) + Claude (ajustes) | 5 |
| 8 | Página da experiência: ícone, 3 thumbnails, descrição, questionário de maturidade, gêneros; Game Settings → Avatar **R15 Only** (taxa DevEx 18+) | Claude prepara; **usuário** envia | 5 |

### P1 — monetização e retenção (pode avançar em paralelo ao P0, vendas desligadas)

| # | Item | Quem |
| --- | --- | --- |
| 9 | `MonetizationService` no servidor: posse de passes, `ProcessReceipt` idempotente com registro de `PurchaseId`, direitos no perfil | Claude |
| 10 | Ateliê na vila: vitrine com manequins, prévia 3D giratória e provador temporário | Claude |
| 11 | Arte dos três Conjuntos Lendários e do Companheiro Lumen | Claude gera; **usuário** aprova |
| 12 | Criar passes/produtos na conta e definir preços finais | **Usuário** (Robux/conta) |
| 13 | Insígnias gratuitas (concluir capítulo, derrotar chefe sem cair, explorador de segredos) | Claude prepara; **usuário** cria |
| 14 | Telemetria de funil (início, classe, cada missão, chefe, conclusão, loja) via AnalyticsService | Claude |
| 15 | Servidor privado pago + convite ao Roblox Plus (até 750 R$ por novo assinante) | Claude implementa; **usuário** define preço |
| 16 | Ativar Managed Pricing no Creator Hub (preço regional automático) | **Usuário** |

### P2 — depois do beta

- Passe de temporada (trilha gratuita + premium) quando houver Capítulo 2.
- Presentear conjuntos (produto de desenvolvedor com recibo durável).
- Capítulo 2 e trailer (CPP-028/029).

## Sequência proposta

1. **Agora:** itens 1 e 2 (arte e equilíbrio) + 9 e 10 com `SalesEnabled=false`.
2. **Assim que o usuário publicar em privado:** 6, 7, 8 e compras de teste.
3. **Beta privado (#32):** amigos/família, 2–6 jogadores, métricas de funil e loja; ajustar preços.
4. **Lançamento público:** somente com P0 completo e aprovação explícita do usuário.

## Regras que continuam valendo

- Nada de publicar publicamente, criar produtos pagos ou gastar Robux sem confirmação.
- Servidor concede tudo; cliente nunca concede itens.
- Monetização apenas cosmética/conveniência social; o capítulo é concluível de graça.
