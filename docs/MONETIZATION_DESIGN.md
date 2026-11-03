# Monetização — proposta de implementação

Pedido do proprietário: desenvolver monetização atraente, mantendo aprovação explícita antes de ativar vendas. Catálogo inicial em Config/Cosmetics.luau; vendas desligadas, itens não prontos e IDs zero. Não existe loja funcional nem produto comercial criado nesta etapa.

## Oferta inicial

Três conjuntos permanentes de classe: Explorador do Bosque Vivo, Guardião da Aurora e Artífice Celeste. As seis pranchas recebidas definem a qualidade do elenco base, que deve ser bonito gratuitamente; não transformar a correção dos personagens atuais em compra obrigatória. Conjuntos pagos serão variações adicionais com acabamento e identidade próprios.

Valor a demonstrar: vestir o conjunto numa prévia 3D, girar o personagem, ver o efeito da arma e comparar com o traje atual antes de decidir. Informar claramente quais peças e efeitos pertencem ao conjunto. Sem aumento de dano, obrigação de compra para concluir história ou promessa de vantagem inexistente.

Loja acessível pela vila e menu, sem interromper combate, morte ou diálogo com ofertas. Exibir preço real retornado pela plataforma; não inventar desconto, contagem regressiva ou escassez. Após compra confirmada, equipar pelo inventário e permitir voltar ao visual anterior.

## Implementação pendente

1. Prévia e inventário de cosméticos, com controles touch e avaliação de desempenho.
2. Serviço do servidor para consultar propriedade de passes e validar equipamento. Passes são permanentes, não consumíveis; não confiar no cliente para conceder propriedade.
3. Recuperação após reconexão e falha de consulta: mostrar tentativa pendente, não incentivar recompra de item já adquirido.
4. Se produtos repetíveis forem acrescentados, implementar ProcessReceipt com recibo e concessão duráveis/idempotentes antes de disponibilizá-los. Não conceder por fechamento da janela de compra.
5. Preços, itens finais, publicação privada para testes e ativação sujeitos à aprovação do proprietário. Nenhuma mudança automática de conta ou visibilidade.

## Avaliação comercial

Medir visualizações da loja, prévias, pedidos de compra, propriedade confirmada, falhas de entrega e retenção. Escolher preços após revisar arte e testar interesse; não há receita garantida. Priorizar uma aventura que os jogadores queiram concluir e recomendar.

Referências oficiais consultadas em 02/11/2026:
- https://create.roblox.com/docs/production/monetization/passes
- https://create.roblox.com/docs/production/monetization/developer-products
- https://create.roblox.com/docs/production/analytics/monetization
