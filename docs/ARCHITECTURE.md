# Arquitetura — Capítulo 1: A Travessia

## Autoridade e fluxo

O cliente apresenta interface, controles, poses e efeitos. O servidor decide classe, alvos válidos, dano, cooldown, inscrições, missão, checkpoints e recompensas. `src` sincronizado por Rojo é a fonte de verdade; não editar módulos sincronizados só na memória do Studio.

`GameServer` constrói o mundo e conecta serviços/remotes. Perfis carregam antes de registrar classe e missão. O prólogo e a seleção são apresentados ao cliente quando QuestIndex está disponível.

## Módulos

| Módulo | Responsabilidade |
| --- | --- |
| WorldBuilder | Geração determinística de vila, floresta, templo, arena e terreno limitado; Ready sinaliza construção concluída. |
| ClassService | Allowlist, escolha persistida, saúde, equipamento e retorno ao checkpoint no respawn. |
| PlayerDataService | Sessões, atributos replicados, mutações no servidor, recompensas por chave, autosave/release. Studio usa memória temporária. |
| ProfileStore | Schema v2, sanitização e adapter UpdateAsync com lease; perfil corrompido ou sessão concorrente não é sobrescrito. |
| QuestService | Cinco etapas, ProximityPrompt com validação de vida/distância, inscrições/selos, descanso, fragmento e epílogo. |
| EnemyService | Sete encontros compartilhados, LOS, busca de rotas, leash, telegráficos, dano, apoio/crédito e chefe em duas fases. |
| GameClient | Prólogo/câmera, seleção, HUD/diário/diálogo, pedidos de combate e layout de toque. |
| Art | Geometria original reproduzível, acessórios, NPCs, inimigos e previews. |
| AvatarFallback / CharacterMotion | Contingência local para meshes/animações com falha confirmada; suporte aos dois tipos de articulação; poses sem alterar raiz ou hitboxes. |
| VisualEffects / Audio | Apresentação local limitada; telegráficos críticos e gestos independem do limite de decoração. |

## Contratos remotos

- `ChooseClass(classId)`: aceita apenas string em allowlist; escolha existente não muda por novo pedido.
- `AttackEnemy()`: servidor escolhe alvo por alcance e linha de visão; parâmetros extras não concedem dano.
- `UseSkill()` e `Dash()`: classe, personagem vivo e cooldown verificados no servidor.
- `Notify`: servidor envia apresentação, mensagens e eventos de combate; cliente não concede moedas ou progressão.

Prompts de inscrições/selos/fragmento verificam distância e fase. Recompensas usam chaves por missão. Uma repetição não paga novamente. O inventário e a progressão pertencem ao perfil do servidor, não aos atributos alteráveis localmente.

## Cooperação e limites

Inimigos são compartilhados. Crédito de derrota exige contribuição recente, personagem vivo e proximidade; Égide pode registrar apoio de seu conjurador. Vida do chefe escala no primeiro dano com participantes elegíveis, até seis. Ausência de alvo por 12 segundos reinicia o encontro. Essa implementação ainda exige teste cooperativo completo da revisão atual.

O protocolo de perfil foi testado com adapter determinístico, mas a integração real de DataStore permanece não comprovada: este lugar tem PlaceId=0. Falhas de carregamento não autorizam substituir perfis bons por vazios; o cliente informa progresso temporário.

Não há MarketplaceService nem compras. Publicação e monetização dependem de aprovação do usuário.

## Validação

Consulte DEVELOPMENT_STATUS.md e PLAYTEST.md para versão, cenários e limites. CI verifica estrutura/JSON/build, não simula gameplay nem garante segurança completa. Testes no emulador não substituem aparelho físico.
