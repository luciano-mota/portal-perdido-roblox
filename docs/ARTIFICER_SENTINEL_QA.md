# Artífice e Sentinela — novo tratamento

02/11/2026: Artífice gerada pelo Roblox a partir de descrição original baseada na referência ruiva/violeta do usuário. A chamada excedeu 300 segundos, mas o modelo apareceu posteriormente. Exportado sem perda via SerializationService em assets/characters/models/artificer-generated-v1.rbxm, mapeado em ServerStorage.ArtificerTemplate. Fonte original guardada em ServerStorage.GeneratedReferences no lugar de trabalho.

Seleção real de Artificer no Play: PortalGeneratedRig=true, 100 HP e ArcaneFocus presente. Entrada W deslocou de z=32 para z=23,71. Capturas ficaram brancas e não permitem aprovar acabamento visual; ainda faltam revisão de rosto/traje, combate e respawn desta classe. O tratamento de roupas sobrepostas remove estola, fechos e faixa procedurais quando o modelo já traz traje.

Sentinela gerado pelo serviço mesh: publishedAssetId=92616377959692; generationId=9cfaa8af-be4b-4bf6-a1a2-7d2c684e394f. Pedido limitado a 6000 triângulos, não medição do resultado. Seis segmentos (tronco, cabeça, dois braços, duas pernas), preservados em sentinel-generated-v1.rbxm. Art.enemy usa o template apenas para Moss, cria cinco motores e mantém raiz lógica de combate. FirstSentinel e RuneMoss confirmaram GeneratedCreature=true e 120 HP no servidor. Combate após esta substituição ainda pendente; chefe, Predador e Eco não foram substituídos.

A primeira inspeção mostrou código antigo no Studio (Art sem GeneratedCreature); arquivos do repositório foram sincronizados explicitamente em Edit, após o que os novos modelos foram instanciados. Verificar conexão Rojo antes de próximas alterações. Backups de apresentação foram movidos para ServerStorage para não duplicar figuras no mapa. Play encerrado e objetos temporários de exportação removidos.

Guardião: tentativa anterior bloqueada com MODERATION_BLOCKED. Ilyra: modelo final ainda não gerado. Não declarar todo o elenco concluído.

## Validação de 03/11/2026

Studio reaberto com Rojo e os três templates presentes. Seleção real de Artificer: modelo gerado, 100 HP. Navegação por Humanoid.MoveTo, conversa via prompt com Ilyra e ataques reais Q/R contra FirstSentinel gerado: vida do inimigo 120 → 8 → 0, QuestIndex=3, Coins=25, HP=100. Nenhuma alteração manual de dano, vida do inimigo ou progresso nesse combate.

Morte induzida somente após a recompensa para testar respawn: modelo gerado e foco arcano preservados, HP=100, QuestIndex=3, Coins=25, posição próxima de (0,3,-145), checkpoint Forest. Captura frontal confirmou rosto, cabelo castanho-avermelhado, casaco violeta, botas e foco; o resultado ainda difere da referência, especialmente cabelo/cacheados e óculos. Não declarar fidelidade final.

Captura MCP inicialmente branca apesar de HUD visível. Inspeção da janela real via Computer Use confirmou renderização normal; após ativar Studio, captura MCP frontal válida. Isso não era evidência de cenário branco para o jogador. A primeira tentativa de clicar a introdução antecedeu a criação da interface; aguardar PortalPerdidoHUD corrigiu a sonda. Play encerrado ao final.
