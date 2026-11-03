# Monetização — modelo proposto

Atualizado em 03/11/2026 a partir da proposta de 02/11. **Estado: modelo para aprovação.** Nenhum produto foi criado, nenhuma venda está ativa (`Config/Cosmetics.luau` → `SalesEnabled=false`).

## Princípio

O jogador compra **identidade e momentos sociais**, nunca poder. O capítulo é completo e bonito de graça; as compras fazem o seu herói ficar inesquecível aos olhos do grupo. Em aventura cooperativa, o que mais vende é o que os amigos veem: traje, efeito do golpe, companheiro, título.

## Ofertas

| Oferta | Tipo Roblox | O que entrega | Por que atrai | Preço sugerido* |
| --- | --- | --- | --- | --- |
| **Conjunto Lendário** (um por classe: Guardião da Aurora, Explorador do Bosque Vivo, Artífice Celeste) | Passe (permanente) | Rig alternativo com traje próprio, arma com brilho/rastro exclusivo, som de impacto e moldura do retrato | É o herói "versão capa de livro"; aparece em toda luta em grupo | 249 R$ cada |
| **Coleção das Três Classes** | Passe | Os três conjuntos | Desconto real para quem joga com todas as classes | 599 R$ |
| **Companheiro Lumen** | Passe | Espírito de luz que segue o jogador, reage a combate, brilha ao derrotar inimigos e "comemora" a conclusão | Mascotes são o item mais desejado em Roblox; fofo e visível | 149 R$ |
| **Pacote de Fundador** | Passe, à venda **só durante o beta e a primeira temporada** (data publicada, sem contador falso) | Título "Fundador do Vale" sobre o nome, capa de Fundador, moldura dourada no retrato e insígnia | Exclusividade honesta para os primeiros apoiadores; vira status | 399 R$ |
| **Gestos do Vale** | Passe | 6 gestos/poses (saudação, vitória, ajoelhar, ler grimório…) e modo foto | Social, compartilhável em capturas | 99 R$ |
| **Servidor privado** | Nativo da plataforma | Grupo fechado para jogar a história com amigos | Combina com cooperação; custo baixo e recorrente | 50 R$/mês |
| **Presentear conjunto** (P2) | Produto de desenvolvedor | Compra um conjunto para outro jogador do servidor | Viraliza no grupo | igual ao conjunto |

\* Preços são sugestões para validar no beta; a decisão final é do proprietário. Exibir sempre o preço retornado pela plataforma.

**Não recomendado no lançamento:** reviver pago no chefe, venda de moedas, aumento de dano/vida, caixas aleatórias. Prejudicam confiança, avaliação e risco de regras.

**Gratuito que puxa a loja:** moedas da história compram tinturas e pequenos adereços no Ateliê; o jogador visita a loja por motivo gratuito e vê os conjuntos nos manequins. Roblox Premium paga por engajamento (Premium Payouts) sem ação do jogador.

## Onde a oferta aparece (sem empurrar)

1. **Ateliê da vila** — tecelã original perto da Ilyra, com três manequins vestindo os Conjuntos Lendários. Prompt "Experimentar" veste o conjunto por 60 s (provador real no mundo); "Ver detalhes" abre a prévia 3D giratória.
2. **Seleção de classe** — selo discreto "conjunto disponível" no card.
3. **Tela de conclusão** — após vencer, mostra o herói com o conjunto da classe e o botão "Ver no Ateliê". É o momento de maior satisfação.
4. **Outros jogadores** — conjuntos e companheiros visíveis no grupo são a melhor vitrine.
5. **Nunca** durante combate, diálogo, morte ou prólogo; sem pop-up automático; sem desconto ou escassez inventados.

## Implementação técnica (P1)

- `MonetizationService` (servidor): `UserOwnsGamePassAsync` com cache e nova checagem após `PromptGamePassPurchaseFinished`; nada é concedido pelo cliente.
- `ProcessReceipt` só para produtos repetíveis (presentes): registro durável do `PurchaseId` no perfil antes de retornar `PurchaseGranted`; idempotente em reentrada e reconexão.
- Perfil ganha `entitlements` e `equipped`; o servidor valida equipar/desequipar.
- Ateliê: manequins com os rigs dos conjuntos, prompt de provador (temporário, só visual), UI com `ViewportFrame` giratório e botões touch ≥ 44 px.
- IDs em `Config/Cosmetics.luau`; `SalesEnabled=false` até o proprietário criar os passes e aprovar.
- Telemetria: `shop_open`, `preview`, `try_on`, `prompt`, `purchase_ok`, `purchase_fail` via AnalyticsService.

## Métricas do beta

Conversão do funil (visitou Ateliê → experimentou → abriu compra → comprou), receita por usuário pagante, taxa de conclusão do capítulo, retenção D1/D7. Ajustar preço/oferta pelos dados, não por suposição.

Referências oficiais (consultadas em 02/11/2026):
- https://create.roblox.com/docs/production/monetization/passes
- https://create.roblox.com/docs/production/monetization/developer-products
- https://create.roblox.com/docs/production/analytics/monetization
