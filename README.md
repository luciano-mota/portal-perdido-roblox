# As Crônicas do Portal Perdido

Aventura cooperativa original de fantasia estilizada 3D para Roblox, desenvolvida pela LCM Dev Tech.

**Capítulo 1 — A Travessia** · **Status: protótipo técnico em evolução**.

## Começar no Windows

1. Instale Roblox Studio e Rojo 7.7.1.
2. Abra uma experiência **Baseplate** no Studio, preferencialmente privada.
3. No diretório do repositório, execute `C:\tools\rojo\rojo.exe serve`.
4. No Studio, abra o plugin Rojo, conecte ao servidor local (porta 34872) e pressione **Play**.
5. Escolha Guardião, Explorador ou Artífice, procure a mentora Ilyra, aceite a missão, derrote o Sentinela de Musgo pressionando **Q** ou **ATACAR** e retorne para receber 25 moedas de teste.

Veja [o roteiro de testes](docs/PLAYTEST.md) e [o guia de instalação](docs/SETUP_WINDOWS.md).

## Funcionalidades desta versão (não validadas no Studio)

- Blockout gerado por script do Vale de Lúmen: ilha, árvores, ruínas, portal e spawn.
- Interface de seleção de 3 classes e atributo replicado.
- NPC Ilyra com ProximityPrompt, missão de combate e recompensa.
- Sentinela de Musgo, perseguição simples, ataques e ressurgimento.
- Combate autoritativo no servidor com alcance, classe e cooldown.
- HUD simplificado, ataque por tecla **Q** ou botão touch.
- Validação estrutural e de build Rojo via GitHub Actions.

## Limitações importantes

- **Ainda não há persistência**. Moedas, classe e progresso reiniciam ao sair do servidor.
- Esta é uma **vertical slice em desenvolvimento**, não o jogo final nem uma experiência publicada.
- NPCs e inimigos são objetos provisórios gerados por código; assets 3D finais virão depois.
- Combate, multiplayer, ergonomia mobile e interface **ainda exigem testes reais no Roblox Studio**.
- Compras em Robux **não foram implementadas**. Nada é vendido nesta versão.

## Arquitetura

- `src/shared`: configurações compartilhadas.
- `src/server`: serviços autoritativos, missão, inimigos e cenário de teste.
- `src/client`: interface e comandos de gameplay.
- `default.project.json`: mapeamento Rojo.

Backlog completo: [GitHub Issues](../../issues). PR inicial: [#30](../../pull/30).

## Propriedade intelectual

O projeto é um universo próprio e não incorpora conteúdo protegido da animação Caverna do Dragão.

Direitos reservados à LCM Dev Tech. Sem licença pública de reutilização.
