# Arquitetura inicial

## Objetivo

Construir uma vertical slice enxuta do Capítulo 1 com segurança básica e evolução modular.

## Runtime

- **Cliente**: apresentação, controles e pedidos de ações.
- **Servidor**: única autoridade para classes, estados, progressão, inventário, dano e compras.
- **Shared**: configurações e tipos públicos.
- **DataStoreService**: previsto para CPP-004, ainda não implementado.
- **MarketplaceService**: previsto para CPP-019/020, ainda não implementado.

## MVP executável atual

Ao executar Play no Roblox Studio com a sincronização Rojo, o servidor monta um *blockout* de Vale de Lúmen e a interface permite selecionar 3 classes. A escolha chega por RemoteEvent, passa por allowlist e cooldown e vira um atributo replicado do Player.

Os arquivos de mundo temporário existem para teste de integração. A versão final terá assets e cenários construídos no Studio.

## Evolução planejada

1. CPP-004: dados versionados, carregamento e UpdateAsync.
2. CPP-011/012: serviços de classe e combate com validação de alcance/cooldown.
3. CPP-009: máquina de estados de missões e eventos de objetivo.
4. CPP-020: ProcessReceipt com idempotência durável.
5. CPP-023/024: testes mobile e cenários adversariais de RemoteEvents.

## Segurança

Nunca confiar em preço, dano, inventário, experiência, moeda ou conclusões de missão enviados pelo cliente. Não usar RemoteEvents para aceitar recompensas arbitrárias. Evitar dependências e modelos livres não auditados.
