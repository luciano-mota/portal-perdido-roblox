# As Crônicas do Portal Perdido

Jogo cooperativo de fantasia estilizada 3D para Roblox, desenvolvido pela LCM Dev Tech.

**Capítulo 1:** A Travessia · **Status:** pré-produção / desenvolvimento inicial.

## Começar

1. Instale [Roblox Studio](https://create.roblox.com/docs/studio/setup) no Windows/macOS e [Rojo](https://rojo.space/).
2. Abra uma experiência vazia no Studio.
3. Na raiz do repositório, execute `rojo serve`. No Studio, use o plugin Rojo para conectar.
4. Pressione **Play**. O protótipo cria uma ilha temporária com ruínas, árvores e um portal e apresenta a seleção de classe.
5. Escolha Guardião, Explorador ou Artífice. A classe é validada pelo servidor e sincronizada pelo atributo do Player.

### Importante

O código da primeira entrega é um **protótipo técnico**: ainda não há combate, missões, progresso salvo, loja ou experiência publicada. O cenário gerado via código é apenas um blockout para teste e será substituído por assets próprios no Roblox Studio.

## Arquitetura

- `src/shared`: contratos e configurações replicadas.
- `src/server`: bootstrap, serviços autoritativos e mundo temporário.
- `src/client`: interface e solicitações de ações ao servidor.
- `docs`: decisões arquiteturais e escopo narrativo.
- `default.project.json`: mapeamento Rojo para o DataModel Roblox.

**Segurança:** seleção de classe usa `RemoteEvent` com allowlist e controle de frequência no servidor; atributos do jogador são definidos exclusivamente no servidor.

## Backlog

Todas as tarefas estão em [issues](../../issues), identificadas por CPP-001 a CPP-029. Desenvolvimento em pull requests; `main` estável.

## Requisitos

Roblox Studio: Windows 10+ ou macOS 10.14+ (veja a recomendação atual na documentação oficial). Rojo e editor externo podem rodar fora do Studio, mas validação do jogo exige Roblox Studio.

## Licença

Direitos reservados à LCM Dev Tech. Nenhuma licença de reutilização é concedida até definição expressa do titular.
