# Cenários das seis fases e conexões — 06/11/2026

Base: [CAMPAIGN_SIX_PHASES.md](CAMPAIGN_SIX_PHASES.md). Etapa pedida pelo proprietário: fechar todos os cenários e a ligação entre eles antes de voltar a personagens e jogabilidade.

## Arquitetura

- Um único lugar com as seis regiões afastadas 3000 studs (`src/shared/Config/Campaign.luau`). Com StreamingEnabled (raio 1024), o cliente só recebe a região em que está.
- `src/server/services/Regions.luau` monta as regiões 2–6 depois do Vale e dos serviços; cada construtor fica em `src/server/services/regions/`. Como no Vale, as peças sobem +2 depois de montadas, porque a superfície dos voxels fica 2 studs acima do topo preenchido.
- `src/server/services/RegionKit.luau` reúne as peças procedurais originais: pontes em arco, arcos de passagem, escadas maciças, ilhas flutuantes em cone invertido, cristais, agulhas góticas, estandartes, quedas d'água/areia/energia, anéis e portais de travessia.
- `src/server/services/TravelService.luau` cuida das viagens:
  - Portais (`ExitGate` com ProximityPrompt), validados pelo servidor e com destino pela rota A ou B.
  - Ponto seguro por região, queda no vazio com retorno ao último ponto seguro e renascimento dentro da região (`ClassService.spawnResolver`).
  - Os ramos da Rota B chegam ao terraço correspondente da Convergência.
- `src/shared/RegionAtmosphere.luau` (cliente) aplica luz, névoa, nuvens e cor de cada região, conforme a posição da câmera. Também cria o céu de cada região (eclipse, galáxia, lua, aurora) e mostra o nome dela ao entrar.
- Marcadores para a jogabilidade futura (`Slots`): `Encounter`, `Objective`, `BossArena`, `Gathering`, `SafePoint` e `FinalPortal`. Ainda não há inimigos, missões ou chefes nas regiões 2–6.

## Regiões

| Fase | Região | Percurso |
| --- | --- | --- |
| 1 | Vale de Lúmen | Existente. Ganhou o portal **Passagem da Aurora** na arena, que só abre depois do Fragmento da Aurora. |
| 2 | Abismo de Cristal (ref. 3) | Penhasco com arcos rúnicos e glicínias → ponte em arcos → ilha-pilar → ilha das ruínas → passarela em anel ao redor do Cristal-Mãe → ilha oeste → escadaria → terraço da catedral (arena) → portal. |
| 3 | Deserto das Horas (ref. 4) | Portal em ruína com estandarte → estrada entre aquedutos → relógio de sol inclinado (objetivo) → roda de relógio enterrada, ampulhetas e colunata → platô redondo com templo escalonado e grande ampulheta (arena) → portal. No céu: arco de pedra, anéis de relógio, fitas do tempo e galáxia. |
| 4 | Cidadela do Eclipse (ref. 7) | Estrada com tochas → muralha e portão com torres e estandartes → cidade baixa (casas góticas, praça com fonte) → ponte sobre a ravina com rio e cascatas → barbacã → pátio (arena) → fachada com o Selo do Eclipse e a passagem oculta no átrio. Eclipse no céu. |
| 5 | Limiar da Convergência (**cenário novo, proposta para aprovação**) | Nexo flutuante sobre um mar de nuvens, com quatro terraços de chegada temáticos (Vale, Abismo, Deserto, Cidadela), pontes até a arena circular da prova e escadaria monumental até o Portão do Vazio. |
| 6 | Domínio do Vazio (ref. 5) | Varanda com balaustrada e lanternas de cristal → ponte quebrada com fissuras → ilha do santuário → pedras de salto → ilha da âncora (objetivo) → escadaria e ponte → Átrio do Regente (arena final) diante da fachada com o sigilo e o **Portal Primordial**. Abaixo, vórtice com arcos partidos e bastiões flutuantes. |

## Testado no Studio (desktop, solo)

- As cinco regiões são construídas sem erro de Luau. Peças por região: Abismo 2188, Deserto 1842, Cidadela 2307, Convergência 1438, Domínio 2138. O Vale tem cerca de 2,5 mil.
- **Rota A pelos prompts reais:**
  - O portal do Vale recusa sem o Fragmento ("A passagem só desperta…").
  - Com o Vale concluído (fixture `setQuest`), a sequência Vale → Abismo → Deserto → Cidadela → Convergência (terraço da Cidadela) → Domínio → Portal Primordial (volta ao Vale) funcionou.
- **Rota B:** com `CampaignRoute=B`, Deserto → terraço do Deserto na Convergência.
- **Queda no vazio** na Convergência devolve ao último ponto seguro com a mensagem. **Renascimento** após morte acontece na própria região.
- **Pathfinding da chegada até o portal de saída:**
  - Sucesso no Abismo (116 pontos), no Deserto (92), na Cidadela (84, depois de abrir o corredor entre a ponte e a barbacã) e na Convergência (81).
  - No Domínio, os trechos antes e depois das pedras de salto têm sucesso. As pedras têm vãos de 2,6 a 5,8 studs com subida de 1,14, dentro do salto padrão. O pathfinding não liga essas ilhas soltas, e o salto real não foi testado.
- Piso alinhado ao terreno nas chegadas: Abismo 102,25 contra terreno 102,00; Deserto 2,00.
- **FPS no desktop**, 3 s por região: 60 em todas, com pior quadro entre 20 e 40 ms. **Não vale como aprovação mobile.**
- Capturas inspecionadas de todas as regiões. Correções feitas a partir delas:
  - Paredes do abismo, que eram caixas.
  - Grama de voxel cobrindo pisos.
  - Platô do deserto retangular e relógio de sol enterrado.
  - Cidadela escura demais.
  - Ilhas com cara de caldeirão.
  - Névoa clareando o eclipse.
  - Faixa com o nome da região sobreposta ao painel de missão.

## Pendente

- Aprovação do proprietário para o visual da **Convergência** (sem arte de referência) e para a fidelidade das demais às referências.
- Teste em celular físico, com 2–6 jogadores e com a Rota B real (sorteio e distribuição ainda não existem; hoje a rota vem do atributo `CampaignRoute`).
- Progresso de campanha persistente, travas das regiões 2–6 por conclusão (hoje abertas, porque ainda não há jogabilidade nelas) e rota congelada no início da expedição.
- Salto real nas pedras do Domínio, com um personagem controlado.
- Pendências do Vale continuam em [BACKLOG_CHAPTER_01.md](BACKLOG_CHAPTER_01.md).
