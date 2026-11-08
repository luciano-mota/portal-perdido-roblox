# Predador de Espinhos e Eco do Vazio gerados — QA de 03/11/2026

Com isso, **todas as sete criaturas do capítulo** usam modelos gerados e articulados (Sentinela ×2, Predador ×2, Eco ×2, Guardião de Raízes). Lógica de combate inalterada no servidor.

## Geração

| Criatura | publishedAssetId | generationId | Partes | Arquivo |
| --- | --- | --- | --- | --- |
| Eco do Vazio | 84974235239917 | 786e344d-5c61-4a4a-8b50-12be3d4aebd6 | corpo, cabeça, 2 mãos | `void-echo-generated-v1.rbxm` |
| Predador de Espinhos (v2) | 119361576906500 | adab51fa-60d4-4812-adc3-689ce709c757 | corpo, cabeça, 4 patas | `thorn-stalker-generated-v1.rbxm` |

A primeira versão do Predador (83730749552372) saiu praticamente como um lobo comum, sem identidade de espinhos; foi rejeitada e arquivada em `ServerStorage.ReviewArchive`. A v2 tem crânio de madeira, dentes e grandes espinhos curvos nas costas, musgo e garras.

O Predador veio girado ~21° no próprio espaço; o template foi alinhado pela linha patas traseiras → dianteiras para a frente ficar em −Z.

## Integração

`Art.enemy` agora usa uma tabela `GENERATED` (Boss, Wisp, Thorn) e `buildGenerated`: escala, altura em relação ao chão medida por raycast só no cenário, Motor6D por peça (com peça-base opcional), peças neon e luzes.
- Eco: escala 1,15, flutua 0,7 stud; o corpo oscila no motor `SpiritCore` e leva cabeça e mãos; luz violeta suave.
- Predador: escala 1,25, quadris `Left/Right` + `Front/Rear` (nomes que a `ActorPresentation` já anima); luz âmbar no peito.

## Problema encontrado: sincronização ao vivo do Rojo e malhas

O Eco apareceu como **caixas brancas** no cliente: `MeshId` vazio no template do Studio. O arquivo estava correto (convertido para XML com `rojo build`, cada peça tem `MeshContent` com o ID: chefe 6, Eco 4, Predador 6). A causa é a **sincronização ao vivo do Rojo, que não consegue preencher a malha de MeshParts** (plugins não escrevem essa propriedade). Os templates das classes e do Sentinela funcionavam porque estavam salvos no lugar.

Medidas:
- Templates com malha mantidos no lugar salvo (uma cópia cada; duplicatas sem malha removidas).
- `Art.templateReady`: se um template tiver MeshPart sem malha, avisa no Output (`[PortalPerdido][Template]`) e usa a contingência (procedural ou avatar padrão) em vez de caixas brancas. Aplicado a classes, Ilyra, Sentinela e criaturas geradas.
- **Salvar o lugar no Studio após esta sessão** para persistir os templates novos.

## Evidência (Play)

- Sete inimigos com `GeneratedCreature=true` e motores (5/5/5/4/5/4/5); chefe com base afundada (y 1,75, piso 2,6), Ecos 0,7 acima do chão, Predadores apoiados.
- Guardião contra ForestThorn: 100 → 70 → 40 → 10 → 0; contra TempleWisp: 85 → 55 → 25 → 0. Zero erros Luau; único aviso externo é o já conhecido 203785492.
- Captura: Predador em combate corpo a corpo com o Guardião.
