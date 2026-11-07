# Salas, convites e matchmaking — design aprovado V1
Definição de arquitetura (NÃO implementação pronta). Ligação à Bíblia definitiva: CAMPAIGN_SIX_PHASES.md.

## Modos de entrada
- **Solo:** iniciar imediatamente com 1 jogador; Vale de Lúmen, rota sequencial, sem esperar.
- **Com amigos:** criar sala gratuita privada de 1 a 6; mostrar código temporário para compartilhar dentro da experiência e opção de convite nativo do Roblox. O dono inicia quando quiser; tamanho confirmado define rota A (1–3) ou B (4–6).
- **Online aleatório:** usar fila de pareamento própria, permitindo escolher Jornada 1–3 ou Expedição 4–6 antes de entrar, sem transformar a escolha do usuário silenciosamente. Jogadores em grupo podem ser pareados juntos sem exceder seis; cancelar fila, lidar com abandono e exibir salas disponíveis quando adequado.
- O máximo de cada expedição é SEIS, nunca interpretar seis heróis como exigência de seis pessoas. Não permitir substitutos na partida iniciada; reconexão só de membro elegível.

## Roblox: melhor abordagem
1. Interface social oficial do Roblox: SocialService/PromptGameInvite, após checar disponibilidade e privacidade. Convite é facilidade de UX; ingresso também deve funcionar por código.
2. Transportar uma sala que vai começar para um servidor reservado: TeleportService:TeleportAsync com TeleportOptions.ReservedServerId (novo identificador GUID gerado via HttpService:GenerateGUID(false), persistido no controle temporário da sala). Reutilizar o mesmo ID para reconectar elegíveis. NÃO confundir ReservedServerId com código humano.
3. Não usar a implementação nova baseada nos legados ReserveServerAsync, ShouldReserveServer ou ReservedServerAccessCode; a documentação atual recomenda ReservedServerId: https://create.roblox.com/docs/projects/teleport-private-servers e https://create.roblox.com/docs/reference/engine/classes/TeleportOptions.
4. MemoryStoreService para salas, códigos de ingresso, filas e reservas de vagas com TTL e acesso atômico. DataStoreService apenas para heróis, conquistas e progresso durável. MessagingService pode notificar outros servidores, mas não deve ser autoridade de estado.
5. Separar lobby aberto de fase de jogo. Estados OPEN, STARTING, IN_PROGRESS, CLOSED; limitar a 6 UserIds distintos, validar anfitrião e ingresso; impedir colisão de código, excedente de capacidade e ataques de adivinhação (expiração, rate-limit).
6. No START congelar UserIds, rota e seed; o servidor de destino verifica a lista de elegíveis e estado da sala. TeleportData não deve conceder classe, moedas nem autorização. Tratar falhas de teleporte, retry e reconexão; TeleportInitFailed é sinal importante.
7. Testar transporte com experiência PRIVADA publicada com aprovação humana; ele não roda de verdade no Play Test local do Studio. Não publicar nem ativar compras automaticamente.
8. Separar a partida 4–6 em quatro regiões com distribuição definida no arquivo canônico; unificar sobreviventes na fase 5, depois enviar à fase 6.

## Serviços previstos
- LobbyService: criação, códigos, membros, início e fechamento de sala.
- MatchmakingService: MemoryStore e filas separadas por rota.
- ExpeditionService: estado congelado de grupo, região, vida/morte e convergência.
- TeleportCoordinator: ReservedServerId, TeleportAsync, validação e retry.
- CampaignConfig: metadados de seis fases, três heróis base e placeholders dos demais.
- LobbyUI: Solo / Amigos / Código / Online / Cancelar.
Esses nomes são PROPOSTAS para avaliação do código Rojo existente, não módulos já criados.

## Aceite
Testes com 1–6 participantes; ingresso por código; sala cheia rejeita 7º; código expira; convidado entra e vê roster; fila online respeita escolha A/B; falha de teleporte não gera duplicação; reconexão legítima; sorteio 4 regiões ocupa todas; não permite entrada tardia; morte da partida não apaga conta; testes reais em Roblox autorizados.
