# Ilyra — revisão de 03/11/2026

O modelo chegou depois do timeout de geração e foi preservado em ilyra-generated-v1.rbxm. Template mapeado em ServerStorage. Integração de NPC prepara raiz ancorada, remove scripts, preserva diálogo e usa ActorPresentation com AnimationConstraint.

Teste no Studio: GeneratedNPC=true; ProximityPrompt abriu a fala inicial de Ilyra e avançou para missão 2. Captura real mostrou defeitos visuais: manchas cinzentas no rosto e braços em pose aberta. ColorMap da cabeça estava em Success, portanto não atribuir o defeito automaticamente a download. Ajustada pose de ombros/cotovelos para rig gerado, ainda requer nova revisão.

Tentativa de corrigir textura em cópia isolada da cabeça falhou com `TextureGeneration.getTextureGenerationStatusAsync failed: Bad Request`. Fonte original preservada. Novo modelo NÃO aprovado: Art.npc exige atributo ArtApproved=true no template e usa a Ilyra provisória caso contrário. Não habilitar o atributo sem revisão visual e exportação da versão aprovada. Nenhuma publicação de experiência ou venda.

Pendências reais: corrigir rosto/material, revisar pose e altura, revisar retrato e repetir diálogo antes de trocar definitivamente a NPC. O modelo gerado não é arte final entregue.

## Aprovação — 03/11/2026

Pedido do usuário: personagens com aspecto humanizado. Nova revisão no Studio:

- Captura frontal do template isolado mostrou rosto, tranças, túnica e botas com texturas corretas; as manchas cinzentas da revisão anterior não se repetiram com os assets carregados (ColorMap/Roughness/Metalness presentes).
- Defeito confirmado e corrigido: o código anterior girava os ombros no sentido errado (Z −0,5 no esquerdo), abrindo ainda mais a A-pose. Teste ao vivo de `Transform` no cliente: Z +1,12 no ombro esquerdo e −1,12 no direito deixam os braços ao lado do corpo; cotovelo X positivo dobra o antebraço para frente. `ActorPresentation` agora usa esses valores, com respiração sutil em repouso e gesto acolhedor ao falar.
- Aprovação versionada em código: `Art.ApprovedTemplates = {IlyraTemplate = true}`. O atributo `ArtApproved` do .rbxm continua aceito, mas não é mais necessário editar o binário.
- Retrato do diálogo agora enquadra a cabeça (`Head`) em vez do corpo inteiro; funciona para a Ilyra gerada e para a provisória.
- Play com Explorador e Artífice: prompt da Ilyra abriu o diálogo, missão 1 → 2, gesto de fala visível. Sem erros Luau.
- Modelos de revisão que estavam soltos no Workspace (cabeça e duas cópias da Ilyra em T-pose no caminho do spawn) e um `IlyraTemplate` duplicado sem atributos foram movidos para `ServerStorage.ReviewArchive` (não apagados).

Pendente: avaliação humana do rosto em celular e iluminação noturna.
