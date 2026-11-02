# Plano técnico — Capítulo 1: A Travessia (V2.0)

**Produto:** As Crônicas do Portal Perdido  
**Proprietária:** LCM Dev Tech  
**Direção de arte:** fantasia semirrealista 3D com escalabilidade mobile  
**Modelo:** free-to-play, cosméticos opcionais somente após validação de compras e persistência  
**Situação real:** protótipo jogável em branch de PR; NÃO é capítulo completo nem produto monetizado

## Escopo do primeiro capítulo

A narrativa é uma jornada curta: acidente no portal → despertar em Aetherion → encontro com Ilyra → floresta e três inscrições → templo → Guardião de Raízes → Fragmento da Aurora.

**MVP comercial desejado:** 20–35 minutos na primeira jornada, três classes, um vale com vila/floresta/templo/arena, cinco missões encadeadas, três inimigos comuns, um chefão com duas fases, até seis jogadores por servidor. É uma meta de produto — atualmente só uma missão, um sentinela e um blockout estão implementados.

### Prioridades e critérios

| Corte | Entrega | Bloqueador |
| --- | --- | --- |
| P0 / Vertical slice | movimento, classe, Ilyra, sentinela, combate, HUD, um caminho visual | nenhum bug que impeça terminar a missão |
| P0 / Persistência | dados versionados por jogador e proteção contra falha de save | não perder progressos ou duplicar moedas |
| P0 / Capítulo | cinco missões, templo, enigmas e boss | solo + multiplayer concluíveis |
| P0 / Gráfico | Vale semirrealista navegável e qualidade baixa/média/alta testadas | tempo de entrada, FPS e memória aceitáveis |
| P0 / Beta privado | teste presencial/remoto com público pequeno, requisitos de publicação | segurança, idade/classificação e aprovação humana |
| P1 / Comercial | passes cosméticos, consumo idempotente e telemetria | testes econômicos e regras Roblox cumpridas |

## Arquitetura (monolito Roblox modular, servidor autoritativo)

\`\`\`text
Jogador (PC/mobile/gamepad)
  └─ Roblox Client: HUD / InputController / CombatController / QuestController
        │ solicita ação via RemoteEvents tipados/validados
        ▼
Roblox Server:
  ├─ ClassService / CombatService / EnemyService / QuestService
  ├─ PartyService (até 6; progressão cooperativa)
  ├─ PlayerDataService (DataStoreService + versionamento/UpdateAsync)
  ├─ PurchaseService (GamePass + ProcessReceipt idempotente)
  └─ World/Spawn/Encounter configuration
        │
        ├─ DataStoreService (dados persistentes; em desenvolvimento)
        └─ MarketplaceService (compras; ainda não implementadas)
\`\`\`

O estado decisório reside no servidor. O cliente só solicita ações, nunca escolhe dano, saldo, loot ou conclusão de missão. \`ReplicatedStorage\` armazena contratos/configurações compartilhadas, não assets volumosos desnecessários.

### Dados e persistência (CPP-004)

Proposta de perfil versionado (exemplo conceitual, ainda **não implementado**):

\`\`\`luau
{
    schemaVersion = 1,
    classId = "Guardian",
    level = 1,
    experience = 0,
    coins = 0,
    quest = { chapter = 1, currentId = "CH1_Q01", completedIds = {} },
    inventory = { cosmetics = {}, equipped = {} },
    entitlements = {}
}
\`\`\`

- Chave por UserId, proteção contra gravações concorrentes, \`UpdateAsync\` e retentativas controladas.
- Não sobrescrever dados bons com perfil inicial quando falhar o carregamento. Bloquear compras/progressão dependentes de save em falhas.
- Consumíveis: \`ProcessReceipt\` + registro durável do \`PurchaseId\` e concessão idempotente. Não usar callback de interface como prova de compra.
- Medir retries, falhas e salvamentos incompletos no Studio antes de liberar pagamentos.

## Repo e ferramentas

\`\`\`text
portal-perdido-roblox/
├── .github/workflows/validate.yml
├── AGENTS.md
├── default.project.json       # mapeamento Rojo existente
├── src/
│   ├── server/
│   │   ├── GameServer.server.luau
│   │   └── services/
│   │       ├── ClassService.luau
│   │       ├── EnemyService.luau
│   │       ├── QuestService.luau
│   │       └── WorldBuilder.luau  # blockout provisório
│   ├── client/
│   │   └── GameClient.client.luau
│   └── shared/Config/Classes.luau
├── assets/
│   ├── environment/           # modelos, materiais, texturas
│   ├── characters/            # rigs, acessórios, animações
│   ├── vfx/                   # partículas e referências
│   ├── ui/                    # ícones e telas originais
│   ├── audio/                 # ambiência e SFX originais
│   └── README.md
└── docs/
    ├── ART_DIRECTION_SEMIREALISTIC.md
    ├── TECHNICAL_PLAN_CHAPTER_01.md
    ├── BACKLOG_CHAPTER_01.md
    ├── ASSET_MANIFEST.md
    ├── STORY_CHAPTER_01.md
    ├── ARCHITECTURE.md
    ├── PLAYTEST.md
    └── MCP_OPERATOR_RUNBOOK.md
\`\`\`

Os diretórios atuais de código devem continuar intactos. \`assets/\` guarda fontes ou referências versionáveis; modelos publicados no Studio exigem rastreamento de ID/versionamento e, quando for preciso, backup do lugar. Rojo **não sincroniza automaticamente** todos os modelos 3D e objetos de terreno. Binários grandes podem exigir Git LFS (não presumir instalado).

**Ambiente local:** Windows 11, Roblox Studio, Rojo 7.7.1, Git/VS Code, MCP do Studio para agente local. O MCP atua no Studio aberto no dispositivo; acesso ao GitHub isoladamente não é acesso remoto à janela local.

## Estratégia de produção: semirrealismo progressivo

1. Manter o \`WorldBuilder\` atual enquanto valida gameplay; não inserir arte pesada antes do primeiro perfil de desempenho.
2. Construir uma **cena de referência** de spawn → Ilyra → portal com Terrain, pedra e vegetação originais.
3. Importar um kit modular de ruínas/árvores com materialização adequada; LOD e geometria de colisão simplificada.
4. Aplicar atmosfera, iluminação e pós-processamento com variantes por desempenho (efeitos opcionais).
5. Substituir modelos provisórios de NPC/inimigos, mantendo sockets, hitboxes, interações e estados.
6. Expandir de uma área navegável para templo e arena; verificar missões e luta em cada entrega.

## Releases

### Fase 0 — protótipo funcional
- Já há evidência de Play Test MCP de movimento/classe/missão e dois jogadores em \`docs/PLAYTEST.md\`.
- A issue #31 permanece aberta porque o travamento original ainda não foi explicado com segurança.
- Falta persistência e há aviso de asset em Output a investigar.

### Fase 1 — alpha privado
- Cinco missões e boss implementados; DataStore estável; HUD mobile aprovado.
- Cenário semirrealista com FPS/memória medidos em desktop e aparelho móvel real.
- Sem vendas se a economia não puder salvar e recuperar dados.

### Fase 2 — beta público/comercial, condicionado
- Classificação de conteúdo e requisitos de publicação conferidos no Creator Hub.
- Testes de recibos e permissões, ativos originais/licenciados, métricas básicas e conteúdo divulgável.
- Preços e visibilidade pública aprovados pelo proprietário; sem publicação automática.

## Cronograma indicativo

- **Sprint A (3–5 dias de desenvolvimento dedicado):** validar/regredir vertical slice; criar art bible, pipeline de assets e cena-alvo.
- **Sprint B (1–2 semanas):** Vale de Lúmen com Terrain, portal, iluminação e kit básico de vegetação.
- **Sprint C (1–2 semanas):** missões, templo, boss, rigs/efeitos e progressão cooperativa.
- **Sprint D (1–2 semanas):** persistência robusta, otimização mobile, teste multiplayer, conformidade e beta.
- **Sprint E (após gates):** monetização, observabilidade e lançamento público.

Estimativa orientativa de **4–8 semanas para o capítulo com visual semirrealista**, variando com asset pipeline, testes e pessoas disponíveis. O prazo de um dia é viável apenas para um protótipo/beta muito restrito, não para prometer o capítulo completo ou renda.

## Definição de pronto

Nenhuma issue fecha apenas com \`rojo build\`. Precisamos de testes no Studio, evidência de gameplay, review de código, verificação de direitos e desempenho mobile conforme o risco de cada funcionalidade.
