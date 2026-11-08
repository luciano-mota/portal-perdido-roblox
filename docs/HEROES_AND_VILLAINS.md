# Heróis 4–6, vilões e visões do Regente — 07/11/2026

Pedido do proprietário:
- Criar os três heróis restantes. O masculino é um lutador que ganhou poderes ao cair em Aetherion, inspirado na referência do guerreiro com martelo, mas sem martelo e com estilo de artes marciais acrobático.
- O vilão da fase 5 precisa ser forte e difícil, a ponto de parecer o último; só então o Regente do Vazio é revelado.
- Depois de cada chefe final, os jogadores têm uma visão do Regente. Na fase 5, uma fenda se abre e mostra o Regente encapuzado lá dentro.

## Heróis (`src/shared/Config/Classes.luau`)

| Herói | Referência | Kit | Desbloqueio na Rota A |
| --- | --- | --- | --- |
| **Lutador Solar** (`Brawler`) | warrior-reference-v1, sem martelo | O poder dele é lutar: golpes mais fortes que os das outras classes (36 por soco). Combo de 4 (jab, direto, gancho e **Punho Solar** em área, 2×), **Martelo Solar** (pular + atacar, área e atordoamento), **Gancho Ascendente** (agachado + atacar, 1,9×), chutes com o dobro de dano e recarga de 1 s. **Chute Sombra**: avança até 22 studs e atinge todos no caminho (75). | Concluir o Vale de Lúmen |
| **Arcanista** (`Arcanist`) | mage-reference-v1 | Cajado com orbe solar e esferas de fogo à distância. **Sol Nascente**: um sol cai sobre o inimigo e explode em 14 studs (60). | Concluir o Abismo de Cristal |
| **Véu** (`Shade`) | veil-reference-v1 | Duas adagas em cortes rápidos. **Passo do Véu**: reaparece atrás do inimigo mais próximo (até 40 studs), golpe crítico (70) e fica velado por 2 s (translúcida, os inimigos a perdem de vista). | Concluir o Deserto das Horas |

- Na Rota B (4–6 jogadores) os seis ficam disponíveis na expedição, sem desbloqueio permanente.
- O perfil ganhou `heroes`, com migração compatível.
- O Lutador é desbloqueado de forma permanente ao recolher o Fragmento da Aurora.
- A tela de seleção virou uma grade 2×3 com o estado "BLOQUEADO · conclua …". O servidor recusa heróis indisponíveis.
- Modelos gerados pelo gerador de avatar do Studio a partir de descrições originais. Ficam em `ServerStorage.BrawlerTemplate`, `ArcanistTemplate` e `ShadeTemplate`, com as fontes em `ServerStorage.GeneratedReferences`.

## Vilões

- **Regente do Vazio** (referência 09): modelo gerado com capuz, coroa dourada de pontas, olhos violeta, barba, ombreiras douradas e manoplas com garras. Fica em `ServerStorage.RegentTemplate` e é publicado para o cliente em `ReplicatedStorage.VillainPreviews.Regent`. Há também uma figura procedural de reserva em `src/shared/VillainArt.luau`.
- **Arauto Partido** (fase 5, criação original):
  - Visual: um colosso feito de pedaços dos quatro mundos. Ombro de cristal do Abismo, armadura do eclipse da Cidadela, ampulheta no peito do Deserto, raízes do Vale nas pernas e um halo partido.
  - Vida: 2600 + 1500 por participante a partir do segundo. Um jogador sozinho consegue vencer.
  - Ataques, todos telegrafados e evitáveis com esquiva ou saindo da área:
    - **Golpe Quádruplo**: áreas sob o alvo e ao redor dele, em sequência.
    - **Anel do Eclipse**: onda de 17–20 studs ao redor do Arauto.
  - Fases: a 60% chama ecos dos quatro mundos à arena; a 25% entra em **Fúria da Convergência**, com tempo de ataque reduzido para 55%.
  - O modelo procedural está pronto. A geração de um modelo melhor (`HeraldTemplate`) foi pedida ao Studio e é usada automaticamente quando existir.
- **Ilusão de "última fase":** o portal de saída da Convergência fica invisível, sem colisão e sem prompt até o Arauto e os ecos caírem. Depois da fenda ele surge, com o aviso "O verdadeiro inimigo espera além dele".

## Visões (`src/shared/RegentVision.luau`)

- **Flashback** depois do chefe final de cada região (Vale, Abismo, Deserto, Cidadela): a tela escurece e mostra o Regente no espaço do vazio, com uma frase própria de cada região. O Guardião de Raízes já dispara a visão do Vale.
- **Fenda** depois do Arauto: um rasgo elíptico se abre no alto da arena, com o Regente encapuzado flutuando lá dentro e a câmera aproximando do rosto. Fala: "O Arauto era só uma porta. E vocês acabaram de abri-la para mim. Venham. O Domínio do Vazio espera."
- O HUD some durante a visão, e no fim a câmera volta para o jogador.

## Testado no Studio (desktop, solo)

- Seleção 2×3: na Rota A aparecem 3 disponíveis e 3 bloqueados com dica; na Rota B, os seis.
- **Lutador**: 135 de vida, rig gerado e faixas dos punhos. Três socos causaram 72 de dano no Sentinela.
- **Arcanista**: 95 de vida e cajado com orbe. Três esferas e o Sol Nascente causaram 153 no Arauto.
- **Véu**: teleporte de 26 studs para trás do Sentinela, 70 de dano e translucidez de 0,65 por 2 s.
- **Arauto** no piso da arena (y 159):
  - Revida: deixou a Arcanista com 9/95 de vida.
  - Telegrafia do Anel do Eclipse visível e barra "ARAUTO PARTIDO · FASE N".
  - As fases 2 (60%) e 3 (25%) dispararam com ecos.
  - A derrota abre a fenda.
- **Flashback e fenda** com o Regente gerado, capturados e inspecionados.

## Pendente

- **Versionar os modelos gerados.** O Studio passou a bloquear o envio do Assistente para o receptor local. Em `ServerStorage`, clique com o botão direito em `BrawlerTemplate`, `ArcanistTemplate`, `ShadeTemplate` e `RegentTemplate` (e `HeraldTemplate`, quando existir) → **Save to File...** → `assets/characters/models/<nome>-generated-v1.rbxm`. Depois é só mapear no `default.project.json`. Até lá eles existem apenas no lugar salvo do Studio.
- Ajuste fino dos gestos de combate dos heróis novos (ângulos reaproveitados das poses calibradas, sem nova calibração).
- Chefes finais do Abismo, Deserto e Cidadela: **implementados em versão procedural** (Colosso de Cristal, Guardião das Horas, Cavaleiro do Eclipse; ver DEVELOPMENT_STATUS 07/11). Falta arte gerada/final e inimigos comuns no percurso dessas regiões.
- ~~A luta contra o Regente na fase 6.~~ Feita em 07/11 (ver DEVELOPMENT_STATUS).
- Teste com vários jogadores e em celular.
