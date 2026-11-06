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
