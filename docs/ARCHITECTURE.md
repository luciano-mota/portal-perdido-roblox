# Arquitetura do Portal Perdido — protótipo inicial

## Objetivo

Validar uma **vertical slice**: escolher classe, atravessar o Vale de Lúmen, iniciar a primeira missão com Ilyra, derrotar um Sentinela de Musgo e voltar para receber moedas.

## Runtime

- **Cliente:** interface, botão de ataque, tecla Q e apresentação de objetivos. Envia apenas pedidos por `RemoteEvent`.
- **Servidor:** valida classe, distância, cooldown, vida do inimigo, derrota, estados da missão e pagamento de moedas de teste.
- **Shared:** configurações legíveis pelo cliente.
- **DataStoreService:** planejado para CPP-004, **não implementado**.
- **MarketplaceService:** planejado para CPP-019 e CPP-020, **não implementado**.

## Serviços

- `ClassService`: allowlist de classes, escolha fixa por sessão e saúde inicial.
- `WorldBuilder`: monta blockout provisório, remove apenas Baseplate e SpawnLocation padrões, cria um spawn no Vale.
- `QuestService`: estados NOT_STARTED → ACTIVE → READY → COMPLETED. Define moedas somente no servidor.
- `EnemyService`: 1 inimigo compartilhado, perseguição simples, ataque ao Humanoid e combate validado pelo servidor.

## Contratos remotos

- `GameRemotes.ChooseClass(classId: string)`: valida o valor no servidor, permite uma escolha por sessão.
- `GameRemotes.AttackEnemy()`: o servidor identifica o personagem, verifica classe, alcance, cooldown e calcula o dano, sem confiar em parâmetros de alvo/dano enviados pelo cliente.

## Segurança

Nunca confiar em preço, dano, inventário, experiência, moeda ou conclusão de missão enviados pelo cliente. Os remotes têm controle de frequência e as moedas são concedidas somente na transição READY → COMPLETED.

**Limites desta versão:** nenhuma proteção anti-exploit está completa; é preciso validar line-of-sight, IA, PVP, persistência e ferramentas de telemetria em entregas futuras.

## Evolução priorizada

1. **Play Test com Studio e Rojo**: validar seleção, diálogo, Q/touch, vida, respawn e recompensa.
2. **CPP-004**: persistência versionada com proteção para save e retry.
3. **CPP-011/012/013**: classes com habilidades, animações, mais criaturas e indicadores de combate.
4. **CPP-009/014**: cinco missões e chefão do capítulo.
5. **CPP-019/020**: monetização opcional, somente com concessão durável e `ProcessReceipt` idempotente para consumíveis.

## Definição de pronto

O GitHub Actions testa apenas estrutura e construção do arquivo Roblox via Rojo. A aprovação de gameplay requer testes dentro do Studio. Não declarar tarefa concluída antes desses testes.
