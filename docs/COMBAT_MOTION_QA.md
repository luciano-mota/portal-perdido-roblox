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

## Revisão 2 — combate realista, defesa funcional e colisões (03/11/2026)

Pedido do usuário: espada com golpes reais, escudo que protege de verdade, flash de luz da Artífice, arqueiro de lado tirando a flecha das costas, nada atravessando nada e correias no verso do escudo.

### Sistema de animação
`CharacterMotion` passou a usar **poses-chave + sequências** (`Motion.Poses`, `Motion.Clips`) interpoladas com suavização, somadas à animação nativa (incluindo avanço do corpo e flexão de joelhos). Cada pose foi **calibrada no Play** com busca numérica sobre `PoseOverride_<articulação>`, medindo: centro e normal do escudo, posição da mão, direção da lâmina e uma **penalidade para a lâmina dentro do volume do escudo**. Um erro de sinal na medição da normal do escudo (o `LookVector` já aponta para −Z) foi encontrado e corrigido no processo.

### Guardião
- **Combo de 3 golpes** (alterna se o próximo ataque vier em até 1,3 s): corte diagonal de cima para baixo, corte horizontal de volta e estocada com avanço. Preparação, impacto e acompanhamento; giro do tronco e passo à frente. Rastro na lâmina só na fase de corte.
- **Repouso:** espada abaixada ao lado, sem tocar o chão; mão do escudo fechada na alça.
- **Escudo real:** preso ao antebraço (sem pivô solto), com verso de couro de borda dourada, **duas correias com fivela** que abraçam a manopla (raio medido por raycast: ≈0,25) e **alça** onde a mão fecha. A mão foi calibrada para a alça (erro 0,01 stud) e não entra mais no escudo.
- **DEFENDER (segurar F / botão no toque):** o servidor valida classe e vida, reduz a velocidade para 9 e **reduz o dano a 15% para golpes vindos da frente** (cone ~140°). Enquanto defende, o Guardião gira para encarar a ameaça mais próxima. Atacar abaixa o escudo. Faíscas douradas no escudo a cada golpe aparado.
- Teste: começando de costas para o Sentinela, segurar F → girou para ele (alinhamento 1,00) e os golpes caíram de 10 para **1 (bloqueado)**, com faíscas. Antes da correção do giro, o Sentinela contornava e acertava com dano cheio.

### Explorador
- **Postura de lado** (ombro esquerdo para o alvo) durante o disparo.
- Sequência: a mão sobe por cima do ombro até a **aljava** (calibrada no topo dela), **tira uma flecha visível** (segurada pelas penas), encaixa atrás da empunhadura, puxa até a bochecha e solta; a flecha da mão some e a flecha em voo sai do arco.
- Ritmo: ataque 0,5 s → 0,7 s com dano 24 → 33 (dano por segundo praticamente igual: 48 → 47), para o gesto completo caber.

### Artífice
- **Flash de luz** no cristal ao lançar: núcleo branco, halo colorido, oito raios e luz forte que se apaga em ~0,3 s (intensidade reduzida após a primeira captura). Também no Pulso (R).

### Colisões
- Corpo lógico das criaturas agora é **sólido** para jogadores (a malha visual continua sem colisão) e elas param antes de encostar. Ilyra também é sólida.
- Equipamentos não colidem com o próprio personagem; a geometria do escudo/espada foi ajustada para não atravessar mãos e braços nas poses calibradas.

### Regressão
Artífice contra o Sentinela 120 → 92 → 16 → 0; zero erros no cliente e no servidor; efeitos limpos (5 restantes no contêiner). Build Rojo OK.

### Limitações
- O corte horizontal termina rente à borda do escudo; não há colisão física entre membros (o Roblox não oferece isso para Motor/AnimationConstraint): a ausência de interpenetração vem da calibração das poses.
- Calibração feita sobre a animação nativa ociosa; durante corrida as poses somam-se ao balanço dos braços.
