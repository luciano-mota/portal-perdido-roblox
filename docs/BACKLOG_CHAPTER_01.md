# Backlog — Capítulo 1: A Travessia (V2.0)

Backlog vivo das **29 issues CPP-001…CPP-029** já existentes, mais **5 issues CPP-030…CPP-034** criadas para a mudança de estilo para **fantasia semirrealista**. São **34 cards CPP** no total, além de issues operacionais (bug e release).

**Não recriar nem fechar** as issues originais: o sistema já possui código funcional em avaliação no PR #30.

## Ordem de trabalho (gates)

| Marco | Prioridade | Issues | Saída verificável |
| --- | --- | --- | --- |
| G0 — Regressão da vertical slice | P0 | [#31](../issues/31), [CPP-003](../issues/3), [CPP-011](../issues/11), [CPP-012](../issues/12), [CPP-013](../issues/13), [CPP-016](../issues/16) | movimento + classes + ataque + Ilyra e Sentinela sem bugs bloqueadores |
| G1 — Persistência segura | P0 | [CPP-004](../issues/4), [CPP-017](../issues/17), [CPP-024](../issues/24) | salvar/recarregar classe, missão, moedas; falhas tratadas |
| G2 — Direção de arte | P0 | [CPP-030](../issues/33), [CPP-031](../issues/34), [CPP-032](../issues/35), [CPP-033](../issues/36), [CPP-006](../issues/6) | caminho spawn → Ilyra → portal com look semirrealista e assets rastreados |
| G3 — Capítulo completo | P0 | [CPP-007](../issues/7), [CPP-008](../issues/8), [CPP-009](../issues/9), [CPP-010](../issues/10), [CPP-014](../issues/14), [CPP-015](../issues/15) | cinco missões, templo, boss, recompensa e solo/co-op concluíveis |
| G4 — Quality & beta | P0 | [CPP-022](../issues/22), [CPP-023](../issues/23), [CPP-025](../issues/25), [CPP-026](../issues/26), [CPP-027](../issues/27), [#32](../issues/32) | FPS e memória medidos, testes reais, publicação privada e autorização |
| G5 — Comercial | P0 após gates | [CPP-018](../issues/18), [CPP-019](../issues/19), [CPP-020](../issues/20), [CPP-021](../issues/21) | cosméticos opcionais, compras verificadas no servidor, sem perda de saldo |
| Futuro / polimento | P1/P2 | [CPP-028](../issues/28), [CPP-029](../issues/29), [CPP-034](../issues/37) | trailer, capítulo 2 e animações de acabamento |

## Novos cards gráficos

- **CPP-030 / #33 / P0** — Bíblia visual, paleta, composição e cena-piloto comparável.
- **CPP-031 / #34 / P0** — Pipeline FBX/GLB, originais Blender, materiais PBR e manifesto de direitos.
- **CPP-032 / #35 / P0** — Atmosfera, iluminação e VFX, com qualidade escalável.
- **CPP-033 / #36 / P0** — Kit modular de Vale de Lúmen (ruínas, vegetação, portal, terreno).
- **CPP-034 / #37 / P1** — Rigs e animações semirrealistas originais de NPC e inimigos.

## Notas operacionais

- **CPP-006** permanece dona da entrega do mapa completo; CPP-033 é uma dependência de assets/modularidade, não duplicata.
- **CPP-023** permanece dona da aprovação de desempenho; CPP-032 depende de suas métricas.
- **#31** teve movimentação validada em Play Test MCP, mas o bug original não foi explicado; manter aberto até teste de regressão conclusivo.
- **#32** é uma meta de beta privado e não prova de elegibilidade para lançamento público; data deve ser reavaliada com qualidade visual e P0.
- **Monetização** só entra após persistência, proteção de recibos e aprovação explícita.
- Fonte de verdade do estado: **GitHub Issues + PRs**, não esta cópia estática.

Veja \`docs/TECHNICAL_PLAN_CHAPTER_01.md\` e \`docs/ART_DIRECTION_SEMIREALISTIC.md\` para critérios detalhados.
