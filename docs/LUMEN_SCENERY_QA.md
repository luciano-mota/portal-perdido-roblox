# Vale de Lúmen — primeira implementação pelas referências

03/11/2026; base 1c88d98, PR #30. [Catálogo de imagens](../assets/world/references/README.md), [plano](AETHERION_VISUAL_ROADMAP.md).

## Implementado

- Dez originais preservados, com nomes por região e aplicação no plano. Imagens 6/8 são cópias idênticas, ambas mantidas.
- LumenScenery integrado ao gerador: rio em terreno nativo, ponte, cascata lateral, elevações, montanhas, portal maior com patamar/escadaria, arco de entrada, flores, cristais e ilhas distantes. Referência principal 2. É primeira composição, **não equivalência visual à ilustração nem arte final**.
- Placas com colisão. Esferas internas adicionais nas pedras elipsoidais: o SpecialMesh esticava o desenho, mas o collider Ball usava só o menor eixo.
- Encontros derrotados não renascem por temporizador nesta sessão. Quem alcança a etapa depois acompanha o Sentinela já vencido; limiar reconhece chefe já derrotado. Reinício formal de expedição e matchmaking 3–6 ainda pendentes.
- Fragmento coletado some e desativa prompt/rótulo apenas para o jogador que coletou. Não destrói o objeto compartilhado.
- Prólogo 3D de 24 s, com avanço e pular: demonstração em sala, grupo atraído ao portal e câmera de chegada ao vale. Clones dos avatares de classe representam projeções da simulação; não são ainda trajes civis finais. Limpa cenário local e restaura câmera ao terminar.

## Evidências reais

- Play: cenário criado e Ready=true; seis placas sólidas, 404 colliders auxiliares de pedra, 2376 BaseParts no mundo durante medição (inclui cenário e personagens do mundo, não custo de terreno).
- Rio inicialmente seco por preenchimento menor que resolução de voxel. Corrigido leito/água; leitura de região confirmou 84 voxels Water; captura mostrou água e ponte.
- Capturas reais do Vale e primeira cena do prólogo inspecionadas. Abertura terminou automaticamente, apagou PortalArrivalCinematic, mostrou seleção e restaurou CameraType.Custom. Pular também limpou a cena.
- Artífice derrotou Sentinela antes de conversar com Ilyra; conversa posterior avançou até missão 3 com 25 moedas, evitando bloqueio na expedição já limpa. Sentinela permaneceu com Health=0 e EncounterCompleted=true após o intervalo em que antes renascia.
- Apresentação de coleta: HasFragment preparado **apenas no cliente** escondeu malha/prompt/rótulo e restaurou ao desfazer. Servidor permaneceu HasFragment=false. É teste de apresentação, não nova comprovação de coleta real ou multiplayer.
- 300 frames no desktop: média 60,016 FPS; percentil 95 de tempo de frame 17,877 ms. Não aprova aparelho físico. Servidor sem MessageError na consulta final.
- Build Rojo aprovado. Nenhuma publicação da experiência nem compra ativada.

## Ainda em desenvolvimento

Qualidade de árvores/ruínas e composição natural; abertura com atuação/efeitos/áudio mais elaborados; revisão artística do chefe; chutes/outras ações; reforços finitos, patrulhas e grupos obrigatórios 3–6; testes reais multiplayer/mobile. Geração de árvore e ruína detalhadas iniciada para substituir peças provisórias, resultados ainda não aprovados neste registro inicial.

## Ruína detalhada e controle de qualidade

- Arco gerado: asset 117808560108743, generation e000113c-8480-497f-9e78-04f9617e79f5; três MeshParts, pedido de até 5000 triângulos (não medição). Exportado por SerializationService para assets/world/models/lumen-arch-v1.rbxm (45.862 bytes), mapeado em ServerStorage.LumenArchTemplate. Originais preservados em GeneratedReferences.
- Captura inspecionada: pedra clara com desgaste, colunas e vegetação. Integrado em seis arcos com colisões simples nos pilares/coroamento, mantendo passagem aberta. No Play, GeneratedLandmark em seis instâncias; caminhada pelo arco de entrada até Z 85 e retorno ao spawn testada; nenhum erro no cliente.
- Árvore asset 124848821691123, generation 1236bc84-94b6-4d70-8463-6560d5b2efbc: **rejeitada visualmente** por copa ausente e fragmentos desconectados. Preservada no Studio para revisão, não usada pelo gerador nem apresentada como arte entregue.
- Modelos gerados dependem de meshes/texturas do Roblox. Art.templateReady mantém contingência se o template chegar sem MeshId durante sincronização do Rojo. Abrir o build ou lugar salvo preserva as meshes.
