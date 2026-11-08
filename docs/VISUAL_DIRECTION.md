# Registro visual e continuidade narrativa — Capítulo 1: A Travessia

Este registro complementa a [direção de arte semirrealista vigente](ART_DIRECTION_SEMIREALISTIC.md) e o [plano técnico](TECHNICAL_PLAN_CHAPTER_01.md). Esses documentos continuam sendo as referências de direção e produção; as notas abaixo registram somente esta implementação incremental. Os critérios completos de arte e desempenho ainda não estão aprovados.

## Referência narrativa

A sequência abaixo vem de [STORY_CHAPTER_01.md](STORY_CHAPTER_01.md), que continua sendo a fonte narrativa do projeto. Este documento não substitui nem amplia os acontecimentos combinados.

1. **O acidente:** a demonstração de uma tecnologia de realidade imersiva falha; os viajantes atravessam uma fenda.
2. **O despertar:** chegada ao **Vale de Lúmen**, vila de acolhimento e seleção entre **Guardião Astral, Explorador e Artífice**.
3. **A Floresta Esquecida:** primeiros combates e descoberta de **três inscrições** para acessar o templo.
4. **O Guardião de Raízes:** chefe com duas fases e ataques telegrafados.
5. **O primeiro Fragmento da Aurora:** conquista, visão das outras regiões e gancho do **Regente do Vazio**; investigar por que o Portal Primordial está selado.

Aetherion é um mundo original de ilhas flutuantes, máquinas arcanas e portais fraturados. Manter o tom de descoberta, aventura cooperativa e fantasia. Não copiar personagens, diálogos, cenários ou elementos de universos protegidos.

## O que existe no jogo hoje

O trecho jogável é o **Vale de Lúmen**: escolha da classe, encontro com Ilyra, missão contra um Sentinela de Musgo e retorno por 25 moedas temporárias. O mapa ainda é um blockout procedural. O acidente, a floresta, as inscrições, o templo, o chefe e o fragmento são etapas planejadas, ainda não entregues.

## Direção artística desta sessão

Aplicar **fantasia semirrealista legível**: luz e materiais legíveis/naturais, preservando formas simples e a identidade fantástica de Aetherion. Efeitos gráficos não substituem cenografia, narrativa ou gameplay.

| Etapa | Direção visual de referência | Estado |
| --- | --- | --- |
| Vale de Lúmen | Luz clara de fim de tarde, verdes naturais, pedra de contraste moderado, portal ciano como ponto de interesse. Entrada e Ilyra devem ser fáceis de localizar. | Iluminação aplicada; cenário ainda provisório. |
| Floresta Esquecida | Transição para verdes mais frios, umidade e raízes; inscrições devem se destacar sem depender apenas da cor. | Direção proposta; cenário não construído. |
| Templo / Guardião de Raízes | Pedra antiga e natureza entrelaçadas; silhueta do chefe e sinais de ataque legíveis em tela pequena. | Direção proposta; conteúdo não construído. |
| Fragmento da Aurora | Luz de destaque ligada à conquista e à descoberta das outras regiões. | Direção proposta; sequência não construída. |

As propostas visuais para as etapas futuras não alteram a ordem ou os eventos do roteiro. Novos diálogos, cenas e objetivos devem ser registrados no roteiro antes da implementação.

## Perfil gráfico implementado

- `WorldBuilder` configura horário 15,6, luz ambiente suave, reflexos moderados, uma atmosfera de densidade 0,24 e correção de cor discreta.
- Reaproveita a atmosfera do template, em vez de empilhar atmosferas. Desliga bloom, raios solares, desfoque e profundidade de campo herdados do template antes de aplicar o perfil.
- Cliente adiciona apenas um bloom discreto do projeto no perfil teclado/mouse; desliga esse bloom quando a entrada preferida é touch.
- Sem novas texturas remotas, luzes por árvore, partículas, motion blur ou geometria adicional nesta alteração.
- Deixar os ajustes de qualidade do Roblox sob controle do jogador/engine. Sem alegação de FPS ou memória até medir em aparelhos reais.

## Validação

Ver [PLAYTEST.md](PLAYTEST.md) e as capturas de [desktop](evidence/2026-11-02/semireal-desktop.jpg) e [celular](evidence/2026-11-02/semireal-mobile.jpg). Os efeitos e a direção narrativa foram versionados; nada foi publicado e nenhuma compra foi ativada.
