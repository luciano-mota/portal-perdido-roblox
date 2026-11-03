# Movimentos de combate e criaturas — QA de 03/11/2026

Pedido do usuário: melhorar os movimentos dos monstros e dos personagens jogáveis (lançar flecha, usar poderes etc.).

## Personagens (`CharacterMotion`, `AvatarFallback`, `VisualEffects`)

- **Sincronia gesto → efeito:** cada classe tem duração e instante de soltura (`Motion.Timing`). Flecha, esfera e corte saem quando a pose solta, não no clique.
- **Guardião:** preparação acima do ombro, corte diagonal com giro do tronco e rastro de luz na lâmina (só na fase de corte). Escudo preso ao antebraço por um motor (`ShieldOrientation`): em repouso fica ao lado do corpo com a face para fora; em combate gira suavemente para a guarda, com o escudo azul e a estrela de frente. **Égide (R):** escudo à frente, espada erguida e cúpula de energia que cresce até o alcance real (22 studs).
- **Explorador:** arco estendido à frente, mão puxa a corda até a bochecha, solta e abre a mão. Flecha com ponta, penas e rastro, em arco leve, com clarão no impacto. **Rajada (R):** a mesma puxada mirando o céu; três flechas sobem e caem quatro sobre cada alvo atingido.
- **Artífice:** concentra o cristal junto ao peito (que cresce e brilha mais) e empurra com as duas mãos; esfera luminosa com rastro e luz, explosão no alvo. **Pulso (R):** braços sobem e golpeiam o chão; onda translúcida no alcance real (26 studs).
- **Esquiva:** inclinação do tronco durante o impulso.
- O servidor agora envia `skillCast` (classe, autor, posição, alvos atingidos) para animar a habilidade de quem a usou. Dano e escudo continuam decididos no servidor.

**Como os ângulos foram obtidos:** o rig gerado parte de uma pose em A e soma a animação nativa, então os eixos não são intuitivos. No Studio, `AvatarFallback` aceita o atributo `PoseOverride_<articulação>` (CFrame); uma busca numérica mediu a posição das mãos relativa à raiz até atingir o alvo (ex.: mão da corda junto à bochecha). Valores em `Motion.BOW_ARM`, `DRAW_HAND`, `RELEASE_HAND`, `CHARGE_*`, `PUSH_*`. O ajuste do escudo usou a orientação medida do antebraço em guarda.

## Criaturas (`ActorPresentation`, `Art`)

- Novas articulações: `Waist` no Sentinela, no Predador e no chefe (tronco com cabeça e braços acompanhando).
- Andar com balanço e sobe-desce do tronco; respiração parado; cabeça segue o jogador próximo.
- Ataque: Sentinela/chefe inclinam para trás ao erguer os braços e golpeiam para a frente; Predador agacha e dá o bote; Eco sobe e estende as mãos.
- Recuo curto ao levar dano; queda com o tronco tombando ao morrer.

## Evidência no Studio (capturas)

Guardião: preparação, guarda com escudo de frente, repouso com escudo ao lado, pose e cúpula da Égide. Explorador: puxada calibrada e flecha atingindo o Sentinela. Artífice: empurrão com cristal ampliado e Sentinela erguendo os braços no golpe; Pulso (deixado mais translúcido após a primeira captura).

Regressão: Guardião com Q, R e esquiva → Sentinela e Predador derrotados, missão 3, 25 moedas, zero erros no cliente e no servidor.

## Equilíbrio do chefe (passo 1)

Ao cruzar o limiar com menos de 70% de vida, o jogador recebe um aviso sobre a Fonte de Lúmen e fica do lado de fora na primeira vez; apertar de novo atravessa. **Carregado sem erros, mas não exercitado em jogo** (exige chegar à missão 5). Dano do chefe não foi alterado sem teste humano.

## Limitações

- Os ângulos foram calibrados por classe sobre a animação nativa ociosa; com a contingência de animação (HTTP 403) a aparência pode variar.
- Sem medição de desempenho dedicada aos novos efeitos (limite de 60 efeitos simultâneos continua valendo).
