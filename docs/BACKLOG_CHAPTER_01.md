# Backlog — Capítulo 1: A Travessia (V2.0)

Backlog vivo das **29 issues CPP-001…CPP-029** já existentes, mais **5 issues CPP-030…CPP-034** criadas para a mudança de estilo para **fantasia semirrealista**. São **34 cards CPP** no total, além de issues operacionais (bug e release).

**Não recriar nem fechar** as issues originais: o sistema já possui código funcional em avaliação no PR #30.

## Ordem de trabalho (gates)

| Marco | Prioridade | Issues | Saída verificável |
| --- | --- | --- | --- |
| G0 — Regressão da vertical slice | P0 | [#31](https://github.com/luciano-mota/portal-perdido-roblox/issues/31), [CPP-003](https://github.com/luciano-mota/portal-perdido-roblox/issues/3), [CPP-011](https://github.com/luciano-mota/portal-perdido-roblox/issues/11), [CPP-012](https://github.com/luciano-mota/portal-perdido-roblox/issues/12), [CPP-013](https://github.com/luciano-mota/portal-perdido-roblox/issues/13), [CPP-016](https://github.com/luciano-mota/portal-perdido-roblox/issues/16) | movimento + classes + ataque + Ilyra e Sentinela sem bugs bloqueadores |
| G1 — Persistência segura | P0 | [CPP-004](https://github.com/luciano-mota/portal-perdido-roblox/issues/4), [CPP-017](https://github.com/luciano-mota/portal-perdido-roblox/issues/17), [CPP-024](https://github.com/luciano-mota/portal-perdido-roblox/issues/24) | salvar/recarregar classe, missão, moedas; falhas tratadas |
| G2 — Direção de arte | P0 | [CPP-030](https://github.com/luciano-mota/portal-perdido-roblox/issues/33), [CPP-031](https://github.com/luciano-mota/portal-perdido-roblox/issues/34), [CPP-032](https://github.com/luciano-mota/portal-perdido-roblox/issues/35), [CPP-033](https://github.com/luciano-mota/portal-perdido-roblox/issues/36), [CPP-006](https://github.com/luciano-mota/portal-perdido-roblox/issues/6) | caminho spawn → Ilyra → portal com look semirrealista e assets rastreados |
| G3 — Capítulo completo | P0 | [CPP-007](https://github.com/luciano-mota/portal-perdido-roblox/issues/7), [CPP-008](https://github.com/luciano-mota/portal-perdido-roblox/issues/8), [CPP-009](https://github.com/luciano-mota/portal-perdido-roblox/issues/9), [CPP-010](https://github.com/luciano-mota/portal-perdido-roblox/issues/10), [CPP-014](https://github.com/luciano-mota/portal-perdido-roblox/issues/14), [CPP-015](https://github.com/luciano-mota/portal-perdido-roblox/issues/15) | cinco missões, templo, boss, recompensa e solo/co-op concluíveis |
| G4 — Quality & beta | P0 | [CPP-022](https://github.com/luciano-mota/portal-perdido-roblox/issues/22), [CPP-023](https://github.com/luciano-mota/portal-perdido-roblox/issues/23), [CPP-025](https://github.com/luciano-mota/portal-perdido-roblox/issues/25), [CPP-026](https://github.com/luciano-mota/portal-perdido-roblox/issues/26), [CPP-027](https://github.com/luciano-mota/portal-perdido-roblox/issues/27), [#32](https://github.com/luciano-mota/portal-perdido-roblox/issues/32) | FPS e memória medidos, testes reais, publicação privada e autorização |
| G5 — Comercial | P0 após gates | [CPP-018](https://github.com/luciano-mota/portal-perdido-roblox/issues/18), [CPP-019](https://github.com/luciano-mota/portal-perdido-roblox/issues/19), [CPP-020](https://github.com/luciano-mota/portal-perdido-roblox/issues/20), [CPP-021](https://github.com/luciano-mota/portal-perdido-roblox/issues/21) | cosméticos opcionais, compras verificadas no servidor, sem perda de saldo |
| Futuro / polimento | P1/P2 | [CPP-028](https://github.com/luciano-mota/portal-perdido-roblox/issues/28), [CPP-029](https://github.com/luciano-mota/portal-perdido-roblox/issues/29), [CPP-034](https://github.com/luciano-mota/portal-perdido-roblox/issues/37) | trailer, capítulo 2 e animações de acabamento |

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

## Cenário de Vale de Lúmen — em standby (06/11/2026)

O vale em camadas (commit `f496994`, detalhes em `docs/LUMEN_SCENERY_QA.md`) foi validado no Studio e pausado para priorizar a nova introdução da história. Pendências registradas para retomar depois (CPP-006 / CPP-033 / CPP-032 / CPP-023):

- [ ] **FPS válido** — repetir a medição com a janela do Studio em foco (a última ficou limitada a 15–20 FPS por falta de foco) e depois em aparelho móvel físico.
- [ ] **Fidelidade à referência 2** — pôr do sol rosado, montanha com arco de rocha, névoa em camadas.
- [ ] **Praça da Aurora** — ainda lê como disco; dar forma orgânica.
- [ ] **Escadarias** — muito retas; quebrar com curvas, patamares e degraus irregulares.
- [ ] **Bases das ruínas ribeirinhas** — ainda leem como blocos retos.
- [ ] **Limiar** — testar a passagem pelo ProximityPrompt real (não só teleporte de QA).
- [ ] **Regressão completa** — passagem inteira do capítulo no relevo novo, solo e com 3+ jogadores.
- [ ] **Personagens e criaturas** — etapa visual seguinte ao relevo.
