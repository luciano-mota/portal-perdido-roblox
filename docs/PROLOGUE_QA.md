# QA — Prólogo: feira de ciências, apagão e despertar

## 06/11/2026 — nova abertura

Implementado (`src/shared/ArrivalCinematic.luau`, `Chapter.Dialogues.Arrival`/`ArrivalTitles`, título por página em `GameClient`):
- Quatro páginas de 8 s, com CONTINUAR e PULAR INTRODUÇÃO preservados. Tudo é local no cliente e destruído ao final (cena e `ColorCorrectionEffect`).
- Jovens: clones estáticos dos rigs das classes. Na escola, sem equipamento, sem a gola do traje e com a textura de roupa trocada por uniforme (camiseta clara, calça escura, tênis, mochila em três). Braços baixados do pose A para ~18° pelo ombro.
- Apagão: arcos de faísca (8 segmentos neon reutilizados), tremor de câmera, luzes piscando, blecaute e queda dos seis (de costas ou de lado).
- Despertar: seis aventureiros deitados em roda a z 20, ao lado da Entrada de Lúmen, com altura do chão por raycast. Levantam-se em sequência enquanto a câmera revela o vale.

Evidência no Play (Studio, desktop, solo):
- Introdução real: títulos A FEIRA DE CIÊNCIAS → O APAGÃO → O SILÊNCIO → OUTRA REALIDADE; terminou sozinha, câmera voltou a Custom e a seleção de classe ficou visível.
- Instância roteirizada: páginas 1,2,3,4 e fim; jovens com vetor vertical 1,00 antes do apagão e 0,22/0,00 no fim da página 2 (caídos); luminárias desligadas; aventureiros 0,00 deitados → 1,00 em pé no fim da página 4; cena e efeito removidos.
- Braços: mão a (±0,55; −1,70) do ombro no espaço do tronco (antes ±1,1; −1,39).
- Capturas inspecionadas das quatro cenas. Zero erros Luau (aviso externo 203785492 continua).

Não aprovado / pendente:
- Cabeça do rig Guardião mantém a faixa azul/dourada na textura do rosto, também na cena escolar.
- Jovens estáticos (sem respiração/andar); som de faísca e apagão ainda não existe.
- Legenda sobrepõe parte dos personagens na cena 1; avaliar layout em celular.
- Sem teste em aparelho móvel físico nem com vários jogadores simultâneos.

## 06/11/2026 — público na feira, despertar humanizado e closes de confusão

Pedido do proprietário: mais pessoas assistindo na escola; ao acordar, levantar de forma mais humana e câmera focada na confusão do grupo.

Implementado:
- `src/shared/CinematicBody.luau`: pose por articulação para clones estáticos (cadeia R15 pelos RigAttachments, cada peça guardada no espaço do quadril, corpo apoiado no chão pelo ponto visível mais baixo, `BulkMoveTo`). `relaxArms` deixa os braços retos e iguais nos três rigs, então os mesmos ângulos servem a todos. Ângulos de mão na testa, mãos à frente do peito e mão no joelho foram calibrados por busca numérica nos três rigs (erro ≤ 0,06 stud no pulso).
- Escola: mais 14 pessoas (8 alunos de uniforme, 5 pais e professor de jaleco operando a bobina no palco), com altura variada e balanço leve. 620 peças na cena.
- Prólogo com 5 páginas (8/8/7/11/11 s). Página 4, O DESPERTAR: cada um, no seu tempo, sai de deitado, se mexe, apoia nos cotovelos, senta tonto com a mão na cabeça, ajoelha e levanta. A câmera baixa contorna o grupo pelo lado sul, com o vale ao fundo. Página 5, OUTRA REALIDADE: o grupo se vira para o centro e alterna gestos (olhar em volta, mão na testa, olhar as mãos, olhar a roupa, "não sei"). Há dois closes de rosto e depois a câmera revela o vale e Ilyra.
- No despertar, as armas presas às mãos ficam penduradas na cintura (mãos livres). Capuz/rosto rígidos seguem a cabeça.

Evidência no Play (Studio, desktop, solo):
- Introdução real: 5 títulos na ordem, 39 s medidos após a cena aparecer, 59,9 FPS médios, pior quadro 19 ms. Câmera voltou a Custom e a seleção de classe apareceu.
- Instância roteirizada: tronco dos seis em −0,02…0,00 deitados → 0,34–0,99 no meio (fases diferentes) → 1,00 no fim da página 4. Folga dos pés no chão 0,00 de pé. Distância rosto/capuz → cabeça constante em todas as fases.
- Capturas inspecionadas: ginásio cheio com professor no palco; grupo em fases diferentes (sentado com mão no rosto, apoiado, ajoelhado com mão na cabeça); close do Guardião com mão na testa; close do Explorador com outro olhando as mãos ao fundo; plano final com o grupo em roda, Ilyra e o vale.
- Zero erros Luau (aviso externo 203785492 continua).

Não aprovado / pendente:
- O balanço lateral na página 5 afundava um pé 0,23 stud; foi reduzido de 1,6° para 0,6° e ainda não foi medido de novo.
- O público repete os 3 rostos dos rigs das classes, e dois viajantes iguais aparecem lado a lado no close. Falta variação de rosto e cabelo.
- O professor não gesticula; a queda na escola ainda é do corpo inteiro (sem dobrar joelhos).
- Sem som; sem aparelho móvel físico; sem teste com vários jogadores.
