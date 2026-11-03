# Monetização — modelo aprovado para implementação

Atualizado em 03/11/2026 com pesquisa de mercado (fontes no fim). O proprietário autorizou seguir com o modelo; **preços finais, criação de passes/produtos e ativação de vendas continuam dependendo dele.** Até lá, `Config/Cosmetics.luau` fica com `SalesEnabled=false`.

## Como o dinheiro chega até você

1. O jogador compra **Robux** com dinheiro real (loja do Roblox, cartão, cartão-presente) ou recebe Robux mensais por assinatura.
2. Ele gasta Robux **dentro do jogo** (passe, produto, servidor privado). O Roblox fica com **30%**; você recebe **70% em "Earned Robux"**.
   - Exceção: assinaturas do jogo vendidas em **moeda local** (US$ 2,99–14,99) pagam em Robux à taxa de US$ 0,01 = 1 Robux após taxas das lojas; 70% no 1º mês e 100% a partir do 2º.
3. Os Earned Robux viram dólares pelo **DevEx**: **US$ 0,0038 por Robux** (desde 05/09/2025). Requisitos: 13+ anos, e-mail verificado, **mínimo de 30.000 Earned Robux (≈ US$ 114)**, conta no portal DevEx e formulário fiscal **W-8BEN** (não residente nos EUA). Gastos de jogadores dos EUA verificados 18+ convertem a **US$ 0,0054** se o jogo cumprir as regras de avatar (abaixo).
4. **Brasil:** não há tratado tributário Brasil–EUA para esses rendimentos; pode haver retenção na fonte nos EUA e tributação no Brasil (carnê-leão/IRPF). **Consultar contador antes do primeiro saque.**

**Conta realista:** um passe de 199 R$ rende 139 Earned Robux ≈ **US$ 0,53**. A receita vem de **volume**. Exemplo ilustrativo (não é previsão): 20.000 jogadores/mês, 2% compram, gasto médio 250 R$ → 70.000 Earned Robux ≈ US$ 266/mês. Por isso a prioridade é um capítulo que as pessoas terminem, recomendem e joguem em grupo.

## Fontes de receita e o que usamos

| Fonte | Como paga | Uso no Portal Perdido |
| --- | --- | --- |
| **Passes** (compra única) | 70% em Robux | Oferta principal: cosméticos permanentes |
| **Produtos de desenvolvedor** (repetíveis) | 70% | Só para presentes (P2); exige `ProcessReceipt` idempotente |
| **Servidor privado pago** | 70% da mensalidade | Sim — grupo fechado para cooperar |
| **Roblox Plus** (substituiu o Premium em 30/04/2026) | Até **750 R$ por novo assinante** trazido pelo prompt do jogo (250/mês por 3 meses); até **100 R$/mês** por assinante que passa 60+ min no seu servidor privado pago (assinantes Plus entram de graça nos servidores privados) | Sim — convite ao Plus no menu de servidor privado e na conclusão |
| **Managed Pricing** (preço regional + teste automático de preço) | Roblox informa +4–10% em gasto médio e +43–52% em compras de passes em regiões com desconto | Ativar no lançamento; exige **não fixar preço no código** |
| **Assinatura do jogo** | Ver item 2 acima; passe de batalha pode ser assinatura | P2, quando houver Capítulo 2 e conteúdo mensal |
| **Anúncios em vídeo recompensado** | Receita de anúncios (criadores elegíveis) | P2, opcional: assistir para ganhar tintura cosmética |

## Ofertas da primeira versão

| Oferta | Tipo | Conteúdo | Preço inicial* |
| --- | --- | --- | --- |
| **Conjunto Lendário** ×3 (Guardião da Aurora, Explorador do Bosque Vivo, Artífice Celeste) | Passe | Rig alternativo, arma com brilho/rastro e som próprios, moldura do retrato | **199 R$** cada |
| **Coleção das Três Classes** | Passe | Os três conjuntos | **449 R$** |
| **Companheiro Lumen** | Passe | Espírito de luz que segue, reage ao combate e comemora | **99 R$** |
| **Pacote de Fundador** | Passe, à venda só no beta e na 1ª temporada (data publicada) | Título "Fundador do Vale", capa, moldura dourada | **349 R$** |
| **Servidor privado** | Nativo | Grupo fechado | **50 R$/mês** |

\* Faixas de mercado em 2026: compra por impulso 25–75 R$, compra pensada 100–250 R$, compra de compromisso 400–1.000+ R$ (só para jogos com tração). Começamos na faixa pensada, porque o jogo é novo; o Managed Pricing ajusta por região e testa preços a cada ~90 dias.

**Ficam para depois:** Gestos e modo foto (com o Capítulo 2), passe de temporada como assinatura, presentes, vídeo recompensado.
**Não usamos:** reviver pago, venda de moedas, aumento de dano/vida, caixas aleatórias, contador falso, pop-up automático. Prejudicam confiança, avaliação e regras da plataforma.

## Onde a oferta aparece

1. **Ateliê da vila:** tecelã original perto da Ilyra e três manequins com os conjuntos. "Experimentar" veste por 60 s (só visual); "Ver detalhes" abre a prévia 3D giratória.
2. **Seleção de classe:** selo discreto "conjunto disponível".
3. **Tela de conclusão:** o herói com o conjunto da classe e "Ver no Ateliê"; convite ao servidor privado para jogar de novo com amigos.
4. **Outros jogadores** usando conjuntos e companheiros: a melhor vitrine.
5. **Nunca** durante combate, diálogo, morte ou prólogo.

## Regras técnicas

- Servidor decide posse: `UserOwnsGamePassAsync` com cache e nova checagem após `PromptGamePassPurchaseFinished`. Cliente nunca concede.
- Preço exibido vem de `MarketplaceService:GetProductInfoAsync` (regional) — nunca texto fixo, requisito do Managed Pricing.
- Produtos repetíveis: `ProcessReceipt` grava o `PurchaseId` no perfil antes de `PurchaseGranted`.
- Avatar: rigs R15 humanos (elegível à taxa 18+); ao publicar, Game Settings → Avatar → **R15 Only**.
- Telemetria de funil: `shop_open`, `preview`, `try_on`, `prompt`, `purchase_ok`, `purchase_fail`, `plus_prompt`.

## Fontes

- [Developer Exchange (Creator Hub)](https://create.roblox.com/docs/production/monetization/developer-exchange) · [Ajuda DevEx](https://en.help.roblox.com/hc/en-us/articles/13061189551124-Developer-Exchange-Help-and-Information-Page) · [Informação fiscal](https://create.roblox.com/docs/production/monetization/tax-information)
- [Taxa US 18+](https://create.roblox.com/docs/production/monetization/18-plus-devex-rate)
- [Taxa de marketplace 30% em passes/produtos](https://devforum.roblox.com/t/unified-marketplace-fee-for-dev-products-and-game-passes/507109)
- [Managed Pricing (anúncio de 15/06/2026)](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738)
- [Assinaturas do jogo](https://create.roblox.com/docs/production/monetization/subscriptions)
- [Roblox Plus para criadores](https://create.roblox.com/docs/en-us/production/monetization/roblox-plus.md) · [anúncio (Business Wire)](https://www.businesswire.com/news/home/20260410099173/en)
- [Vídeo recompensado aberto a criadores elegíveis](https://devforum.roblox.com/t/rewarded-video-ads-are-now-available-to-all-ads-eligible-creators/4063278)
- [Faixas de preço de passes (guia de terceiros, 2026)](https://generalistprogrammer.com/tutorials/roblox-game-pass-pricing-guide)
