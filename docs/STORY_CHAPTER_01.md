# Capítulo 1 — A Travessia

Atualização 06/11: abertura trocada por feira de ciências → apagão → despertar (ver seção "Nova abertura"). Registro anterior, 03/11: abertura passa a mostrar a demonstração imersiva, a ruptura e a chegada em três cenas 3D locais. Elenco de seis viajantes na encenação; objetivo de expedição solicitado pelo usuário: mínimo 3 jogadores, ideal 6. Direção e referências: [Aetherion](AETHERION_VISUAL_ROADMAP.md). A primeira encenação usa os avatares de fantasia como projeções da demonstração; atuação, som e acabamento cinematográfico ainda precisam de revisão.

**Aetherion:** mundo de ilhas flutuantes, máquinas arcanas e portais fraturados.
**Objetivo dramático:** obter o primeiro Fragmento da Aurora e entender por que o Portal Primordial está selado.

## Nova abertura — 06/11/2026 (substitui a demonstração imersiva)

Pedido do proprietário: os seis jovens estão num evento escolar assistindo a um experimento; acontece um apagão, eles desmaiam e, ao acordar, estão em outra realidade vestidos como aventureiros.

Prólogo (atualizado no mesmo dia para cinco cenas, ver `docs/PROLOGUE_QA.md`) (`src/shared/ArrivalCinematic.luau`; textos e títulos em `Chapter.Dialogues.Arrival` / `ArrivalTitles`):

1. **A feira de ciências:** ginásio da escola, faixa "FEIRA DE CIÊNCIAS", bancadas de projetos. O ginásio está cheio de alunos, pais e o professor que opera o experimento. Os seis jovens, de uniforme escolar (camiseta clara, calça escura, tênis, algumas mochilas), assistem a uma bobina com esfera condutora soltando faíscas.
2. **O apagão:** a bobina sobrecarrega, a câmera treme, as luzes piscam e apagam, a esfera dá um último clarão e escurece. Os seis desmaiam.
3. **O silêncio:** tela escura; a luz volta devagar e mostra o grupo deitado na grama do Vale de Lúmen, já com os trajes das classes.
4. **O despertar:** um a um, eles se mexem, sentam tontos com a mão na cabeça, apoiam um joelho e se levantam.
5. **Outra realidade:** confusos, olham em volta, uns para os outros e para as roupas novas ("Onde... a gente está?"); a câmera revela a vila, Ilyra e o portal.

O motivo do apagão e a ligação do experimento com o Portal Primordial ficam em aberto, como mistério da campanha.

## Sequência planejada

1. **O apagão:** um experimento numa feira de ciências escolar provoca um apagão; os seis jovens desmaiam e acordam em Aetherion. *(Antes: demonstração de realidade imersiva com fenda — substituída em 06/11/2026.)*
2. **O despertar:** Vale de Lúmen, vila de acolhimento e seleção de classe.
3. **A floresta esquecida:** primeiros combates e três inscrições para a passagem do templo.
4. **Guardião de Raízes:** boss de duas fases com ataques telegrafados.
5. **O primeiro fragmento:** conquista, visão das outras regiões e gancho do Regente do Vazio.

## Premissas

- Grupo de até 6 jogadores.
- Classes iniciais: Guardião Astral, Explorador, Artífice.
- Versão 1: um único cenário, três inimigos comuns, cinco missões, um chefe e 20–35 minutos de campanha.
- Nenhum elemento visual, musical ou narrativo da série Caverna do Dragão deve ser copiado.

## Implementação autorizada do capítulo completo — 02/11/2026

A sequência canônica acima é preservada. O roteiro de gameplay passa a ter cinco missões: (1) Um mundo além — despertar e conhecer Ilyra; (2) A primeira ameaça — liberar o caminho contra o Sentinela; (3) Vozes da floresta — recuperar as inscrições da Aurora, da Raiz e da Estrela; (4) O limiar do templo — ativar os selos nessa ordem; (5) O Guardião de Raízes — vencer as duas fases e recolher o Fragmento da Aurora.

As novas falas originais estão em `src/shared/Config/Chapter.luau`. Ilyra situa o viajante e orienta a busca; as inscrições ensinam a ordem dos selos; o Guardião anuncia golpes por marcas no chão. O fragmento revela outras ilhas e uma voz ligada ao Regente do Vazio. O Portal Primordial continua selado ao final: resolução do mistério e regiões posteriores pertencem à continuação, não a conteúdo ficticiamente entregue neste capítulo.

Classes mantêm o avatar Roblox com equipamento original: Guardião Astral com espada/escudo e Égide; Explorador com arco/quiver e Rajada; Artífice com foco arcano e Pulso. Os três inimigos comuns são Sentinela de Musgo, Predador de Espinhos e Eco do Vazio. A duração de 20–35 minutos é uma meta, a medir após testes; não será artificialmente garantida por texto ou espera.
