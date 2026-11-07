# Instruções para agentes — Portal Perdido

## Identidade e objetivo

Projeto privado da LCM Dev Tech: **As Crônicas do Portal Perdido**, aventura cooperativa original de fantasia semirrealista 3D para Roblox. Capítulo 1: A Travessia, em Vale de Lúmen.

## Escopo imediato

Construir a menor **vertical slice** que possa ser testada: entrada no mapa, seleção de classe, um inimigo, combate simples e uma missão com recompensa. Não criar sistemas grandes sem demonstrar o ciclo jogável primeiro.

## Fluxo técnico

- `default.project.json` mapeia `src/shared`, `src/server` e `src/client` com Rojo.
- Arquivos Luau versionados em `src/` são a **fonte de verdade**. Modificações de scripts Rojo sincronizados devem ser feitas no repositório e sincronizadas para o Studio, não apenas no DataModel em memória.
- Usar MCP do Roblox Studio para explorar Workspace, criar protótipos de mapa/modelos, ler Output, executar testes de jogo e identificar erros visuais/funcionais.
- Antes de mexer em scripts via MCP, confirmar se estão sob sincronização Rojo; evitar mudanças perdidas por sobrescrita.
- Registrar no Git estratégias de geração de mapas via código; mudanças feitas somente na cena do Studio exigem exportação e controle de versão do arquivo de lugar/asset.
- Servidor valida classe, dano, cooldown, progressão, moedas e compras. Cliente nunca concede itens ou recompensas.
- Não implementar monetização sem ProcessReceipt idempotente (quando aplicável).
- Priorizar otimização mobile, UI touch e acessibilidade de controles.

## GitHub

- `main`: estável. Não alterar diretamente sem pedido explícito.
- Desenvolvimento em `feature/*` com pull request e descrição dos testes.
- Referenciar issues por `CPP-###` e por link quando possível.
- Não fechar issues enquanto testes necessários no Roblox Studio estiverem pendentes.
- Workflow atual valida apenas estrutura/JSON; não afirmar testes end-to-end sem Studio.

## Segurança operacional

- Não publicar experiência publicamente, não gastar Robux, não criar ofertas pagas nem alterar conta Roblox sem confirmação.
- Nunca solicitar ou exibir senha, cookie Roblox ou chaves.
- Backup/salvar versão antes de alterações grandes no Studio.
- Assets externos devem ter direitos de uso apropriados e scripts auditados.
- Sem copiar personagens, diálogos, logos ou elementos protegidos de Caverna do Dragão; este é universo próprio.

## Contexto

Ler `docs/TECHNICAL_PLAN_CHAPTER_01.md`, `docs/ART_DIRECTION_SEMIREALISTIC.md`, `docs/ARCHITECTURE.md`, `docs/STORY_CHAPTER_01.md` e `docs/SETUP_WINDOWS.md` antes das ações. A prioridade artística é melhorar visuais sem quebrar a vertical slice já testada, com desempenho mobile mensurado. Comunicar claramente o que foi **implementado**, **testado no Studio** e **apenas planejado**.
