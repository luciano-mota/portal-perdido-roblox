# Operação do Roblox Studio via MCP — Primeiro ciclo jogável

Este guia é para o **agente de IA conectado localmente** ao Roblox Studio no computador do desenvolvedor. Não confundir a conexão MCP local com o conector GitHub disponível em outras conversas.

## Contexto

- Projeto: As Crônicas do Portal Perdido (LCM Dev Tech)
- Repositório privado: `luciano-mota/portal-perdido-roblox`
- Branch de trabalho: `feature/cpp-001-003-bootstrap`
- PR: #30
- Bloqueador P0: #31 (movimentação)
- Checklist de beta: #32
- Fonte de verdade dos scripts: arquivos do Git sincronizados pelo Rojo.
- Editor 3D: Roblox Studio; Rojo 7.7.1 em `C:\tools\rojo\rojo.exe`.

## Preparação (Windows PowerShell)

**Pare o Play Test antes de atualizar arquivos e mantenha o lugar privado.**

```powershell
cd "$HOME\Projetos\portal-perdido-roblox"
git switch feature/cpp-001-003-bootstrap
git pull --ff-only
C:\tools\rojo\rojo.exe serve
```

Deixe `rojo serve` ativo. No Roblox Studio, conecte o plugin Rojo ao servidor local, geralmente `localhost:34872`. Evite editar arquivos sincronizados diretamente no Explorer do Studio; salve alterações de código via Git para não perdê-las.

## Prompt de operação para agente MCP

> Assuma como engenheiro Roblox sênior no projeto As Crônicas do Portal Perdido. Leia AGENTS.md, docs/ARCHITECTURE.md e docs/MCP_OPERATOR_RUNBOOK.md. Conecte-se via MCP ao Roblox Studio aberto. Primeiro INSPECIONE sem editar. Verifique Workspace, StarterPlayer, ServerScriptService, ReplicatedStorage, logs do Output e o estado do Play Test. Reproduza o problema da issue #31 (WASD/Espaço não movem o avatar). As mensagens de diagnóstico de movimento começam com [PortalPerdido][MovementDebug] no Output e só são geradas no Studio. Teste se InputBegan chega ao cliente, se está marcado como Processed, se há TextBox com foco, e os estados do Humanoid/RootPart. Corrija a causa raiz no repositório, não apenas dentro do Studio, e sincronize pelo Rojo. Depois valide a missão com Ilyra e o combate com o Sentinela. Documente em PR a evidência do Play Test e qualquer limitação. Não publique, não ative compras, não altere conta ou preços sem autorização. Faça backup do lugar antes de mudanças 3D relevantes. 

## Plano de testes (ordem obrigatória)

1. **Diagnosticar movimentação:** executar Play (não Run), selecionar uma classe, fechar chat com Esc, focar viewport e testar WASD/Espaço. Capturar `[MovementDebug]` no Output; não inferir causa sem evidência.
2. **Verificar servidor:** `[Portal Perdido] Primeira aventura inicializada...` e ausência de infinite yields / stack traces.
3. **Missão:** conversar com Ilyra, enfrentar Sentinela, conferir HP, cooldown, retorno e 25 moedas.
4. **Multiplayer:** abrir teste local com dois jogadores, verificar mortes, respawn, crédito da missão e regressões.
5. **Mobile:** emular tela pequena; conferir HUD, botão ATACAR e alcance do ProximityPrompt.
6. **Persistência:** atualmente **não existe**; não simular que o progresso foi salvo.
7. **Segurança:** não permitir danos ou moedas enviados pelo cliente; não duplicar recompensa em múltiplos ProximityPrompts.
8. **Evidências:** guardar screenshot, nome de cenário, versão de branch/commit, erros e resultado por caso em `docs/PLAYTEST.md` ou comentário do PR.

## Cuidados com o MCP

- Primeiro consultar ferramentas disponíveis, Studio ativo e suas capacidades. Não presumir permissões.
- Mudanças em objetos do Workspace via MCP podem não existir após fechar o Studio se não forem salvas/exportadas. Preferir geradores versionados para protótipos.
- Não executar scripts de terceiros não auditados, nem conceder autorizações amplas.
- Em conflitos entre código local e Git remoto, interromper e analisar o diff em vez de sobrescrever.
- O objetivo de lançamento rápido **não substitui** a validação dos bloqueadores P0.
