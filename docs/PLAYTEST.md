# Teste manual — Primeira aventura (CPP-003/009/012/013/016/017)

**Ambiente:** Roblox Studio no Windows 11, Rojo 7.7.1, experiência Baseplate privada.

## Preparação

Após uma reinicialização do Windows, o processo `rojo serve` precisa ser iniciado novamente:

```powershell
cd "$HOME\Projetos\portal-perdido-roblox"
git switch feature/cpp-001-003-bootstrap
git pull --ff-only
C:\tools\rojo\rojo.exe serve
```

No Roblox Studio, abrir o projeto Baseplate, plugin Rojo > **Connect** > **Play**. Conferir o **Output**.

## Sequência principal

- [ ] O Baseplate padrão é substituído por terreno verde, árvores, ruínas, portal luminoso e um ponto de spawn.
- [ ] Ao entrar, aparece o painel com **Guardião**, **Explorador** e **Artífice**.
- [ ] Ao escolher classe, o painel desaparece e surge o painel de missão e botão **ATACAR [Q]**.
- [ ] Caminhar até a mentora **Ilyra**, perto da entrada, e pressionar **E** (ProximityPrompt).
- [ ] A missão passa para **A PRIMEIRA AMEAÇA**.
- [ ] Aproximar-se do **Sentinela de Musgo**, mais adiante em direção ao portal.
- [ ] Apertar **Q** ou o botão **ATACAR** três a quatro vezes, respeitando o cooldown; o HP do inimigo diminui.
- [ ] Sentinela persegue jogador, causa dano a curta distância e ressurge após ~7 segundos de ser derrotado.
- [ ] A missão muda para **Volte para Ilyra**.
- [ ] Conversar com Ilyra e receber **25 moedas**; repetir o diálogo não dá moedas extras.
- [ ] Ao sair do servidor e voltar, moedas recomeçam em 0 (comportamento provisório até CPP-004).

## Testes de segurança/robustez

- [ ] Atacar longe do inimigo não causa dano.
- [ ] Disparar ataques repetidamente não supera o limite do servidor.
- [ ] Atacar antes de escolher a classe não causa dano.
- [ ] Não é possível receber recompensa sem derrotar o sentinela com a missão ativa.
- [ ] Repetir conversa com NPC após recompensa não gera moedas duplicadas.
- [ ] Morrer ou reiniciar avatar não desconfigura a classe durante a sessão.
- [ ] Testar com 2 jogadores: o inimigo é compartilhado e o crédito da missão vai para quem dá o golpe final (limitação do protótipo).

## Erros comuns

- **Cena não aparece:** confira se o plugin Rojo está conectado; clique Play. O mapa é criado em tempo de execução.
- **Interface não aparece:** verifique StarterPlayer > StarterPlayerScripts > GameClient.
- **Infinite yield:** conferir GameRemotes, ReplicatedStorage.Shared.Config.Classes e módulos em ServerScriptService.Services.
- **Não ataca:** precisa escolher classe, estar vivo e a até 18 studs do Sentinela; aguardar 0,65 s entre golpes.
- **Desconexão do Rojo:** o PowerShell com `rojo serve` precisa permanecer aberto.

## Evidências

Registrar capturas do mapa, HUD, NPC, HP do Sentinela, estado de missão concluída e erros do Output. **Não fechar cards sem validar no Studio.**

## Verificação de interface (02/11/2026)

- [ ] Modal exibe **título**, depois descrição, depois os botões **Guardião / Explorador / Artífice**, nessa ordem.
- [ ] Em tela desktop de cerca de 1136×628, modal fica à direita do chat nativo aberto, sem sobreposição importante.
- [ ] HUD da missão não cobre o chat nativo no desktop.
- [ ] No celular, modal permanece centralizado e sem botões cortados.
- [ ] Ao iniciar, a câmera não fica colada em tronco de árvore; caminho, mentora e portal devem ficar visíveis.
- [ ] Moedas só aparecem após escolha de classe.

Se o Rojo já estiver em execução, atualize o Git **fora do modo Play**, pare e reinicie o Play Test para gerar novamente o cenário via `WorldBuilder`. Se o servidor Rojo ficar com arquivos antigos, reinicie `rojo serve` e reconecte o plugin.
