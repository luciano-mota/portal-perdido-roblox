# Explorador humanizado — integração local

Modelo original gerado pelo Roblox a partir da direção textual do usuário, preservado via SerializationService em assets/characters/models/explorer-generated-v1.rbxm. Contém 16 MeshParts e 15 AnimationConstraints, sem scripts embutidos. O arquivo ainda depende dos IDs de malhas e texturas entregues pelo Roblox.

ClassService troca o personagem da classe Explorer pelo template R15. Preserva controles/câmera, aplica saúde e equipamento e reconstrói no respawn. A peça solta RBX_RIGID_neck é removida do clone; arquivo original permanece intacto. Peças de roupa procedurais sobrepostas ao traje foram removidas para esse rig. Se o template estiver ausente, o avatar normal permanece. AvatarFallback permite movimento procedural quando o novo rig não tem animações carregadas.

Validação no Studio em 02/11/2026:
- Seleção real de Explorer: PortalGeneratedRig=true, 110 HP, BowGrip presente e câmera no Humanoid.
- Entrada W por 1,2 segundos deslocou de z=32 para z=11,96; Espaço produziu elevação para y=9,02.
- Conversa com Ilyra, ataques Q/R: QuestIndex=3, Coins=25, HP=110.
- Morte induzida para QA e espera de sete segundos: novo rig=true, HP=110, arco=true, QuestIndex=3, Coins=25, retorno à região Forest.
- Build Rojo aprovado, incluindo o arquivo binário mapeado em ServerStorage.ExplorerTemplate.

Limitação: character_navigation permaneceu ativo de forma irregular durante o ensaio e houve deslocamento maior que o solicitado. Não usar esse percurso como evidência de naturalidade ou controle manual contínuo. Play encerrado após QA. Revisão de animação de arco quadro a quadro, cooperação, cabeça/capa finais e desempenho mobile ainda pendentes.

Direção aprovada pelo usuário: estender proporções mais humanas, materiais e roupas modeladas ao Guardião, Artífice e Ilyra; criaturas preservam anatomia fantástica com maior credibilidade. Os modelos dessas outras classes ainda não foram substituídos.

Revisão posterior: captura confirmou Explorador sem Mantle procedural sobreposto, 15 articulações, 110 HP e calçamento Cobblestone da vila. Fachadas com vigas/molduras visíveis. Consulta de erros de ClassService/AvatarFallback/WorldBuilder no cliente não retornou ocorrências; não equivale a Output global sem erros. Início da contingência de animação dos rigs gerados reduzido de cinco segundos para 0,1 segundo. Integração aceita templates opcionais das três classes, mantendo avatar normal quando inexistentes.

Tentativa de gerar Guardião Astral retornou `AvatarGen: 2D preview failed: MODERATION_BLOCKED`. Nenhum Guardião novo entregue, nenhuma tentativa de contornar a restrição. Arte final das outras classes permanece pendente.
