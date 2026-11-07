# Guia de instalação — Windows 11

**Projeto:** As Crônicas do Portal Perdido — Capítulo 1: A Travessia  
**Repositório:** https://github.com/luciano-mota/portal-perdido-roblox  
**Branch inicial:** `feature/cpp-001-003-bootstrap`

> Fluxo recomendado: **GitHub + VS Code + Rojo + Roblox Studio + MCP (ChatGPT Desktop/Codex)**.
> Acesso ao GitHub não equivale a acesso ao Roblox Studio local. O MCP funciona entre um cliente de IA instalado na sua máquina e o Studio aberto nela.

## 1. Preparar Windows e instalar Git / VS Code

Usar Windows 11 com drivers gráficos atualizados. No PowerShell:

```powershell
winget install --id Git.Git -e
winget install --id Microsoft.VisualStudioCode -e
```

Reabrir o PowerShell, depois verificar:

```powershell
git --version
code --version
```

Se `winget` não estiver disponível, instalar pelos sites oficiais:
- https://git-scm.com/download/win
- https://code.visualstudio.com/download

## 2. Instalar Roblox Studio

1. https://create.roblox.com/docs/studio/setup
2. Baixar e executar o instalador no Windows.
3. Entrar com a própria conta Roblox, **sem compartilhar a senha**.
4. Abrir um projeto vazio (Baseplate) e manter a experiência **privada** durante os testes.

## 3. Clonar o código

No PowerShell:

```powershell
mkdir "$HOME\Projetos" -ErrorAction SilentlyContinue
cd "$HOME\Projetos"
git clone https://github.com/luciano-mota/portal-perdido-roblox.git
cd portal-perdido-roblox
git switch feature/cpp-001-003-bootstrap
code .
```

O Git poderá pedir login via navegador ou credenciais do Git Credential Manager.

## 4. Instalar Rojo CLI e plugin do Studio

1. Acessar https://github.com/rojo-rbx/rojo/releases e baixar o executável Windows correspondente à arquitetura do computador (normalmente x64). Preferir a versão **7** estável.
2. Extrair `rojo.exe` para uma pasta permanente, por exemplo `C:\tools\rojo\`.
3. Adicionar essa pasta à variável de ambiente de usuário `Path` no Windows (Sistema > Configurações avançadas > Variáveis de ambiente).
4. Reabrir PowerShell e executar:

```powershell
rojo --version
rojo plugin install
```

5. Fechar e reabrir Roblox Studio. Confirmar que o plugin Rojo aparece na aba de plugins.
6. Na raiz deste repositório, executar:

```powershell
rojo serve
```

7. No Roblox Studio com o **Baseplate** aberto, abrir o plugin **Rojo** e clicar **Connect** para conectar ao servidor local (normalmente porta 34872).
8. A sincronização deve popular `ReplicatedStorage.Shared`, `ServerScriptService` e `StarterPlayerScripts`.
9. Clicar em **Play** para verificar a ilha temporária e a seleção de classes. **O mundo gerado via script aparece durante a execução, não necessariamente na visualização de edição.**

Fonte: https://rojo.space/docs/v7/getting-started/installation/

## 5. Conectar assistente ao Studio via MCP (recomendado)

O **MCP server já vem integrado** no Roblox Studio atualizado. Não é necessário baixar um servidor MCP de terceiros.

### ChatGPT Desktop

1. Instalar o aplicativo ChatGPT para Windows: https://chatgpt.com/download/
2. No aplicativo ChatGPT, abrir **Plugins**, encontrar **Roblox Studio**, instalar e iniciar **nova conversa**.
3. No Roblox Studio, abrir **Assistant** > menu `...` > **Manage MCP Servers** (ou Settings > MCP Servers).
4. Habilitar **Enable Studio as MCP server**.
5. Em **Quick Connect**, habilitar **ChatGPT (codex)**, se disponível.
6. Reiniciar o ChatGPT Desktop ou iniciar uma nova conversa e testar: `Liste minhas janelas abertas do Roblox Studio e identifique o lugar aberto.`
7. O indicador verde em MCP Servers deve confirmar a conexão com cliente compatível.

### Alternativa: Codex CLI

Se preferir terminal e editor, consultar o plugin oficial:
https://github.com/Roblox/roblox-studio-agent-plugin

Após instalar o Codex CLI, executar:

```powershell
codex plugin marketplace add Roblox/roblox-studio-agent-plugin
codex
```

Dentro do Codex, usar `/plugins`, instalar o plugin Roblox Studio e iniciar nova conversa com `/new`. O Studio deve estar aberto e o MCP habilitado. Para verificar o registro do MCP, usar `codex mcp list` no terminal. **Não é necessário instalar as duas opções**, ChatGPT Desktop e Codex CLI, para começar.

Fontes:
- https://create.roblox.com/docs/studio/mcp
- https://github.com/Roblox/roblox-studio-agent-plugin

## 6. Orientação para o agente com o Studio conectado

Colar na conversa do cliente com MCP:

> Estou desenvolvendo "As Crônicas do Portal Perdido" (LCM Dev Tech), repositório luciano-mota/portal-perdido-roblox, branch feature/cpp-001-003-bootstrap. Leia AGENTS.md e docs/ARCHITECTURE.md. Use o Roblox Studio via MCP para inspecionar a experiência atual e o Rojo para sincronizar o código. Valide a interface de seleção das três classes e o blockout Vale de Lúmen com Play Test; confira Output e retorne erros encontrados. Não publique o jogo nem edite scripts sincronizados exclusivamente no Studio sem refletir as mudanças no Git. Antes de mudanças grandes, salve uma versão do lugar.

## 7. Diagnóstico

- **rojo não reconhecido:** verificar `Path`, reiniciar terminal e testar `rojo --version`.
- **Plugin Rojo ausente:** repetir `rojo plugin install`, conferir versão major do CLI e reiniciar Studio.
- **Rojo não conecta:** deixar `rojo serve` rodando, verificar firewall/localhost e se a porta mostrada pelo terminal é a mesma do plugin.
- **IA não enxerga o Studio:** confirmar **Enable Studio as MCP server**, quick connect, indicador verde e reiniciar Studio + cliente.
- **Cena não apareceu:** usar **Play** e verificar `Output` porque o mapa é gerado em runtime.
- **Conflito de scripts:** não editar simultaneamente o mesmo arquivo pelo Rojo e por um agente MCP sem sincronizar alterações de volta ao Git.

## 8. Segurança e publicação

- Manter a experiência privada durante desenvolvimento e beta.
- Não enviar senha, cookies `.ROBLOSECURITY`, tokens nem arquivos de credenciais.
- Salvar versão do lugar antes de modificações grandes via MCP.
- Não inserir modelos gratuitos com scripts desconhecidos sem auditoria.
- Nunca publicar automaticamente sem revisão humana.

Atualizado em 02/11/2026.
