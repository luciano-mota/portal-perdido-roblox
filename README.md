# As Crônicas do Portal Perdido

Aventura cooperativa original de fantasia 3D para Roblox, desenvolvida pela LCM Dev Tech.

**Capítulo 1 — A Travessia · versão jogável em desenvolvimento, não publicada.**

## Começar no Windows

1. Instale Roblox Studio e Rojo 7.7.1.
2. Abra uma experiência Baseplate local ou privada.
3. Execute `C:\tools\rojo\rojo.exe serve` neste repositório.
4. Conecte o plugin Rojo à porta 34872 e pressione Play.
5. Assista ou pule o prólogo, escolha Guardião Astral, Explorador ou Artífice e converse com Ilyra.
6. Derrote o Sentinela, recupere três inscrições, ative os selos Aurora → Raiz → Estrela e atravesse o limiar. Vença as duas fases do Guardião e recolha o Fragmento da Aurora.

Q / ATACAR: ataque. R / habilidade: poder de classe. Shift / ESQUIVA: deslocamento. J / DIÁRIO: progresso e áudio. WASD e salto usam os controles nativos do Roblox; no celular, use joystick e botões de toque.

## Implementado

- Prólogo, cinco missões encadeadas, diálogos, puzzle e epílogo. Recompensa total do capítulo: 200 moedas; concessões validadas e idempotentes no servidor.
- Três classes, armas visíveis, habilidades, esquiva, poses de ataque e contingência de passadas compatível com Motor6D e AnimationConstraint.
- Vila, floresta, inscrições, templo, arena, fontes de recuperação, checkpoints e sete encontros de três espécies mais o chefe em duas fases.
- Interface adaptada ao toque, diário, retratos e áudio local com opção de silenciar.
- Perfil versionado, retries e lease de sessão. **No Studio, usa memória temporária explicitamente; persistência real ainda não foi comprovada em experiência publicada.**

## Validação e limites

Uma passagem completa com Artífice na revisão de gameplay de 02/11/2026 chegou a QuestIndex=6, fragmento=true e 200 moedas, sem duplicação ao repetir a coleta. As três classes, passadas, ataques, salto e respawn foram exercitados no Studio. A vegetação e o HUD receberam alterações posteriores; veja o escopo exato em [DEVELOPMENT_STATUS](docs/DEVELOPMENT_STATUS.md) e [PLAYTEST](docs/PLAYTEST.md).

O aspecto atual ainda é procedural e provisório. Realismo final, cooperação completa, duração do capítulo e desempenho em aparelho móvel físico continuam pendentes. HTTP 403 do serviço de assets está afetando avatares/animações nativas; a contingência é visual, sem alterar controles ou conta. Emulação no desktop não comprova desempenho de celular.

Nada foi publicado. Compras não foram implementadas nem ativadas.

## Documentação

[Arquitetura](docs/ARCHITECTURE.md) · [Operação MCP](docs/MCP_OPERATOR_RUNBOOK.md) · [História](docs/STORY_CHAPTER_01.md) · [Direção artística](docs/ART_DIRECTION_SEMIREALISTIC.md) · [Manifesto](docs/ASSET_MANIFEST.md) · [Plano técnico](docs/TECHNICAL_PLAN_CHAPTER_01.md).

GitHub Actions valida estrutura, JSON e build Rojo; não executa os testes de gameplay no Studio.

Universo próprio: inspiração de aventura, fantasia e drama, com personagens e narrativa originais. Direitos reservados à LCM Dev Tech; sem licença pública de reutilização.
