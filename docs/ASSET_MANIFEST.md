# Manifesto de assets — As Crônicas do Portal Perdido

Registrar **todos os assets que forem incluídos no jogo**, incluindo texturas, sons, efeitos, fontes e malhas. Este documento será preenchido durante a produção; **nenhum asset final foi aprovado aqui ainda**.

| Identificador | Tipo | Autor / origem / URL | Licença / permissão de uso | Arquivo fonte / versão | Roblox Asset ID | Status |
| --- | --- | --- | --- | --- | --- | --- |
| ENV-001 | Cenário, terreno e arquitetura procedural | Produção original para LCM Dev Tech, Roblox Studio/Luau, 02/11/2026 | Código do projeto; direitos reservados | src/server/services/WorldBuilder.luau, Git | Não exige asset externo | Implementado; arte provisória |
| CHAR-001 | Ilyra, criaturas e acessórios de classes | Produção original para este projeto, Luau | Código do projeto; direitos reservados | src/shared/Art.luau, Git | Não exige asset externo | Implementado; acabamento final pendente |
| ENV-002 | Árvores de Lúmen determinísticas | Produção original para este projeto, Luau | Código do projeto; direitos reservados | Art.tree em src/shared/Art.luau, Git | Não exige asset externo | Revisão de silhueta em teste |
| ANIM-001 | Passadas, salto e poses das três classes | Produção original para este projeto, Luau | Código do projeto; direitos reservados | src/shared/CharacterMotion.luau e AvatarFallback.luau | Sem upload | Testado em AnimationConstraint; qualidade final pendente |
| VFX-001 | Telegráficos, impactos, feitiços e textos | Produção original para este projeto, Luau | Código do projeto; direitos reservados | src/shared/VisualEffects.luau | Não exige asset externo | Implementado |
| AUDIO-001 | Cliques/notas e impacto locais | Recursos distribuídos com o runtime Roblox | Uso interno pelo runtime; não redistribuir arquivos de áudio | src/shared/Audio.luau | rbxasset://sounds/volume_slider.ogg; impact_explosion_03.mp3 | Provisório; não é trilha final |
| UI-001 | Interface, retratos e fontes | Layout original; fonte Gotham disponibilizada pelo runtime | Uso pelo runtime Roblox | src/client/GameClient.client.luau | Enum.Font.Gotham / GothamSemibold / GothamBold | Implementado, mobile em validação |
| GEN-001 | Tentativas de árvore, Ilyra e pedra texturizada | Geração nativa MCP Roblox Studio, 02/11/2026 | Nenhum resultado incorporado | Jobs documentados em DEVELOPMENT_STATUS | Nenhum | Falharam no serviço; não são assets aprovados |

## Regras

1. Assets criados pela LCM Dev Tech: registrar autoria, ferramenta, data, arquivo de origem e direitos.
2. Assets de terceiros: registrar fonte e licença compatível com redistribuição comercial no Roblox; **não assumir que gratuito é comercialmente livre**.
3. Asset obtido do Toolbox: auditar scripts inseridos no DataModel; nunca confiar em dependências/scripts inesperados.
4. Nomes, personagens, armas mágicas, cenários, vozes, músicas e logos do desenho Caverna do Dragão não devem ser copiados.
5. Fontes Blender/FBX/GLB e texturas grandes: avaliar Git LFS com revisão do peso do repositório, sem presumir disponibilidade. Arquivos .rbxl/.rbxlx/.rbxm estão atualmente ignorados no .gitignore; definir backup/versionamento explícito dos lugares e modelos antes de publicar.
6. O MCP do Studio pode modificar a cena local; exportar ou reproduzir as alterações versionadas e registrar Asset IDs antes de fechar as issues.

## Dependências de runtime

Avatares dos jogadores, meshes e animações nativas são fornecidos pelo Roblox e preservados quando carregam. Falhas confirmadas do ContentProvider acionam geometria local de contingência; nenhum conteúdo externo foi copiado para o repositório. Materiais de engine (Grass, Slate, Wood, Fabric, Leather, Metal etc.) usam o runtime. Não foram inseridos modelos da Toolbox nem scripts de terceiros nesta expansão.
| CRT-REG-001 | Fauna e chefões das regiões 2–4 (9 malhas) | Gerado no Roblox Studio (generate_mesh) a partir de descrições originais, 07/11/2026 | Geração da própria conta no Studio; universo original | ServerStorage: CrystalSpider, PrismBat, CrystalWyrm, SandScorpion, DuneJackal, SandSphinx, ShadowHound, EclipseGargoyle, EclipseDragon (…Template). Exportação .rbxm pendente | 92921150755555 (aranha), 139486247679548 (morcego), 126657135175606 (wyrm), 89089524681649 (escorpião), 136447674484888 (chacal), 79873037312885 (esfinge), 80351376128007 (cão), 104639087678832 (gárgula), 120558193221907 (dragão) | Integrado e testado em Play; só no lugar salvo até exportar |
| CRT-REG-002 | Arauto Partido (criatura alada com halo, fase 5) | Gerado no Roblox Studio (generate_mesh), descrição original, 07/11/2026 | Geração da própria conta no Studio; universo original | ServerStorage.HeraldTemplate (substitui o visual procedural). Exportação .rbxm pendente | — (retorno sem ID publicado) | Integrado e testado em Play |
