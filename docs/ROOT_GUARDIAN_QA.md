# Guardião de Raízes gerado — QA de 03/11/2026

Substitui o chefe procedural (esferas e galhos) por uma criatura original gerada, mantendo toda a lógica de combate no servidor.

## Geração

- `generate_mesh` com segmentação explícita (torso, cabeça, dois braços, duas pernas), limite de 10.000 triângulos (pedido, não medição), caixa 10×12×6.
- Descrição original: colosso curvado de raízes de carvalho, placas de pedra com musgo e líquen, cavidade no peito com coração de cristal, máscara de pedra com órbitas fundas e coroa de raízes em forma de chifres.
- `publishedAssetId=121786440857497`, `generationId=5f05d68f-952c-4b58-a3e8-d887b32c6a91`. Malhas: Torso 81817381632035, Head 126345328455564, LeftArm 135119847564329, RightArm 72414481763624, LeftLeg 93501913058896, RightLeg 85260163051575.
- Template: partes renomeadas, frente girada para −Z, pivô no centro da caixa. Exportado via `SerializationService` → receptor localhost (HttpEnabled ligado só durante o envio e restaurado para false) em `assets/characters/models/root-guardian-generated-v1.rbxm` (80.455 bytes), mapeado como `ServerStorage.RootGuardianTemplate`. Fonte original em `ServerStorage.GeneratedReferences.RootGuardianGenerated_Source`.

**Problema encontrado:** a primeira exportação tinha `MeshId` vazio. A malha só recebe o ID publicado algum tempo depois da geração, e a cópia foi feita antes disso. No cliente as partes apareciam como caixas brancas (`GetAssetFetchStatus=Failure`). Como `MeshId` não pode ser atribuído por script, o template foi reconstruído a partir da referência já publicada e reexportado; os IDs foram confirmados dentro do .rbxm.

## Integração (`Art.enemy`, ramo Boss)

- Escala 1,5 (≈12,4 studs). Cinco Motor6D (Neck, Left/RightShoulder, Left/RightHip) para `ActorPresentation`; torso soldado à raiz lógica invisível (hitbox e movimento continuam no servidor).
- A malha traz uma base de pedras sob os pés; ela fica 0,85 stud abaixo do piso para não deslizar quando o chefe anda. O piso é medido por raycast restrito ao cenário (`PortalChapter`/Terrain), para que um jogador parado no centro durante o reaparecimento não interfira. Primeira tentativa usava altura fixa errada (piso real em y=2,6) e enterrava as pernas — corrigido e conferido por captura.
- `Core` (neon) encaixado no coração de cristal e dois `Eye` na máscara, com offsets medidos por raycast no template. PointLight ciano no núcleo. O `EnemyService` continua recolorindo Core/Eye para âmbar na fase 2.

## Evidência no Studio

- Capturas: fase 1 (olhos e núcleo ciano) e fase 2 (âmbar, marcas de ataque múltiplas visíveis). Pernas sobre o piso (base das pernas em y=2,08 com piso em 2,6).
- Passagem completa com Guardião humanizado: Ilyra → Sentinela → 3 inscrições → selos → limiar → chefe 1800 → fase 2 em 900 → 0 (duas mortes do jogador; a automação entrou na arena com 40 HP, sem usar a fonte do templo) → fragmento (missão 6, 200 moedas) → tela de conclusão. Zero erros Luau em cliente e servidor.
- Proteção ao renascer medida no servidor: rig e 150 HP aos 3,62 s após a morte, `SpawnGrace` presente até ~7,3 s.
- Observação de teste: com a câmera de inspeção fixa apontada para o chefe, o prompt do fragmento não aparecia (fora da tela). Ao soltar a câmera, a coleta funcionou. Não é defeito do jogo.

## Limitações

- Duração/dificuldade da luta não aprovadas por automação; precisa de teste humano e em celular.
- Predador de Espinhos e Eco do Vazio continuam procedurais.
