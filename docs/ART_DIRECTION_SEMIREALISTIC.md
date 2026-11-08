# Direção de Arte — Fantasia Semirrealista
**Projeto:** As Crônicas do Portal Perdido | **Capítulo:** 1 — A Travessia  
**Estúdio:** LCM Dev Tech | **Revisão:** 2.0 (02/11/2026) | **Status:** proposta aprovada como direção, assets ainda não produzidos

## Norte criativo

**Fantasia semirrealista legível e performática**, não fotorealismo extremo. Aetherion combina natureza crível, ruínas com peso e desgaste, tecnologia arcana sutil e magia de contraste. A primeira imagem jogável deve mostrar um caminho seguro entre o spawn e o portal, sem árvore ou UI bloqueando a visão.

Três palavras-chave: **mistério, descoberta e cooperação**.

### Linguagem visual

| Pilar | Regra | Evitar |
| --- | --- | --- |
| Terreno | relevo natural, pedras e vegetação distribuída por bioma | piso plano ilimitado |
| Arquitetura | ruínas modulares com escala humana, rachaduras e musgo | peças repetidas sem variação |
| Portal | núcleo turquesa com aura violeta e silhueta memorável | brilho sólido que ofusca HUD |
| Personagens | rigs compatíveis com Roblox, volumes e materiais coerentes | avatares hiper-realistas dissonantes |
| Monstros | silhuetas identificáveis e animações que anunciam ataques | detalhes que escondem hitboxes |
| UI | placas discretas, tipografia nítida, alto contraste | HUD com fontes pequenas ou excessos |
| Som | ambiência original e pistas direcionais | faixas e efeitos de franquias existentes |

## Paleta de referência (não obrigação rígida)

- Floresta: verde musgo **#365944**, verde profundo **#263C31**, terra **#77634E**.
- Ruínas: pedra fria **#85848B**, bronze envelhecido **#A17D55**.
- Magia: turquesa **#4CC9CD**, âmbar **#E6B96E**, violeta **#7561A8**.
- Interface: fundo escuro **#152535**, texto claro **#F1F3F5**, sinais de alerta **#D47B69**.

## Qualidade visual por sistema

### Terreno e mundo
- Começar com **Terrain Editor** do Studio para o Vale de Lúmen; usar módulos 3D separados para ponte, portal, ruínas e props.
- Proteger o caminho jogável e garantir colisões simplificadas. A NPC Ilyra e o Sentinela devem continuar nos mesmos pontos lógicos ou ter spawns configuráveis.
- A primeira versão semirrealista cobrirá **somente o Vale de Lúmen**, não as seis regiões.

### Materiais e texturas
- Usar **MeshPart** e **SurfaceAppearance** somente onde o detalhe for perceptível; alternativas de MaterialService / materiais de engine em objetos distantes.
- Reusar texturas, atlas/trim sheets e materiais; adotar resoluções proporcionais ao tamanho na tela, sem forçar 4K em props pequenos.
- Modelos importados precisam de licença/documentação de origem e colisões otimizadas.
- \`MeshPart.RenderFidelity = Automatic/Performance\` quando fizer sentido; verificar aparência em diferentes níveis gráficos.

### Iluminação
- Definir um look de **fim de tarde mágico**, com sombras suaves, neblina leve e luz do portal.
- Usar \`Lighting\`, \`Atmosphere\` e pós-processamento **com moderação**, sem exigir todos os efeitos em dispositivos modestos.
- Evitar muitas fontes dinâmicas com sombras. Criar variantes simples por redução de VFX, sem ignorar as configurações gráficas do jogador.

### Personagens
- Três classes jogáveis no primeiro corte: Guardião Astral, Explorador e Artífice.
- Aparência diferenciada via acessórios/efeitos originais; não impor troca do avatar Roblox em toda a experiência.
- Animações provisórias podem permanecer durante desenvolvimento do gameplay; arte final só entra após validação do rig e hitbox.
- Inimigos devem telegrafar ataques de forma compreensível e acessível.

## Orçamento de desempenho — objetivos de validação, não garantias

| Plataforma | Meta | Procedimento |
| --- | --- | --- |
| Celular Android intermediário definido para benchmark | **30 FPS estáveis** no caminho spawn → templo | capturar mediana, quedas, memória e tempo de entrada |
| Notebook com GPU integrada Intel | **30 FPS ou mais** em qualidade moderada | reproduzir combate com dois jogadores |
| Lenovo Ryzen AI 7 / Radeon 860M | **60 FPS desejáveis** em qualidade mais alta | observar variação durante boss e VFX |
| Mobile touch | HUD sem sobreposição e seleção clara | verificar emulação + ao menos um aparelho físico |

Metas são internas e dependem de testes. Sem aparelho físico de referência e resultados medidos, **não marcar desempenho como aprovado**.

### Técnicas recomendadas
1. Conferir \`Workspace.StreamingEnabled\` nas **Properties do Studio** — não é propriedade configurável por script em runtime.
2. Avaliar SLIM/LevelOfDetail em modelos estáticos e RenderFidelity de MeshParts.
3. Minimizar partículas, sombras desnecessárias, objetos com colisão e excesso de componentes no ReplicatedStorage.
4. Medir com ferramentas de desempenho do Studio, em cliente real quando possível; não usar apenas FPS do desktop de desenvolvimento.
5. Assets de alto custo devem ter versão simplificada ou remoção segura para baixo desempenho.

Referências técnicas: https://create.roblox.com/docs/performance-optimization/improve e https://create.roblox.com/docs/environment

## Fluxo de produção

1. **Art bible**: confirmar esta identidade e produzir uma captura-alvo do spawn, Ilyra e portal.
2. **Greybox navegável**: manter combate e missão funcionando durante a troca visual.
3. **Vertical slice**: substituir primeiro caminho, terreno, portal e duas árvores, comparando antes/depois no Studio.
4. **Kit modular**: ampliar vila/ruínas e arena do primeiro chefão.
5. **Polimento**: animações, efeitos, áudio e otimização.
6. **Verificação de direitos**: nenhuma marca, personagem, música, enredo, voz ou desenho protegido de Caverna do Dragão.

## Critérios de aceite da direção artística

- [ ] Pelo menos uma sequência capturada em qualidade alta e baixa, com mesmos pontos de câmera.
- [ ] Visual reconhecível como fantasia semirrealista, sem perder legibilidade de objetivo, NPC e telegráficos.
- [ ] Spawn sem obstruções e caminho com orientação visual até Ilyra/portal.
- [ ] Assets com proveniência, licença e versão em manifesto.
- [ ] Performance aferida em desktop e mobile; regressão visual comparada ao blockout.

## Refinamento solicitado — personagens e realismo (02/11/2026)

Direção atual: buscar o maior realismo sustentável em PC e smartphone, também no elenco. A inspiração em Caverna do Dragão está na aventura de um grupo deslocado, na cooperação, na fantasia e no drama; a identidade visual, personagens e diálogos de Aetherion permanecem originais.

- Guardião Astral: proteção de metal com acabamento usado, ombreiras, couro e emblema astral; silhueta firme e protetora.
- Explorador: tecidos de viagem, capa curta verde, bandoleira de couro, arco e aljava; silhueta ágil.
- Artífice: estola tecida, fechos de bronze, grimório e foco arcano; magia contida e curiosidade visual.
- Ilyra: expressão acolhedora e experiente, vestes em camadas, tranças e cajado; manter continuidade com sua função narrativa de guardiã.
- Preservar o avatar do jogador e as articulações nativas. Acessórios sem colisão, massa ou scripts externos; detalhes compartilhados entre preview e jogo.

Produção nesta sessão: camadas procedurais dos trajes implementadas; ainda exigem revisão visual em Play. Tentativas de geração nativa de árvore e Ilyra falharam com `Unable to trigger model generation`; material também falhou no serviço. Nenhum asset gerado foi aprovado ou integrado. Realismo final e desempenho em aparelho físico permanecem pendentes.
