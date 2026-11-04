# Orientação inicial — 03/11/2026

ObjectiveGuide usa um único BillboardGui local, atualizado a cada 0,5 segundo, com alcance visual de 220 studs. Missão 1 aponta Ilyra; missão 2 aponta FirstSentinel; missão 3 seleciona a inscrição não coletada mais próxima. Não concede progresso nem altera alvos/dano no servidor. Missões posteriores mantêm sua orientação existente no HUD.

Play no Studio: seleção real de Explorador, marcador em Village.Ilyra.Root; conversa pelo ProximityPrompt mudou marcador para PortalEnemies.FirstSentinel.Root; navegação por MoveTo e ataques reais Q/R venceram Sentinela, concederam 25 moedas e avançaram para missão 3. Após o intervalo de atualização, marcador mudou para Runes.Dawn.Core, texto Inscrição da Aurora. Nenhuma alteração manual de progresso ou HP. Play encerrado.

Rojo confirmou módulo e chamada no cliente sincronizados. Build passou antes do teste. Ainda falta avaliar sobreposição dos marcadores em celular físico e validar os demais objetivos com público real.

Geração de Ilyra humanizada iniciada nesta sessão. A chamada expirou aos 300 segundos; nenhuma nova instância apareceu até a última inspeção. Não há integração nova de Ilyra nesta revisão. Conferir eventual conclusão tardia antes de repetir o pedido.

## Extensão ao templo e conclusão — 03/11/2026

Após a passagem registrada em CHAPTER_COMPLETION_REGRESSION.md, ObjectiveGuide foi estendido às missões 4–6. Selo atual usa SealProgress; antes da arena, vida abaixo de 70% aponta a fonte do templo; com vida recuperada aponta o limiar. Na arena aponta chefe, depois fragmento e, após conclusão, pedra de retorno. Ao voltar à vila o marcador de conclusão desaparece. Personagem morto não recebe marcador. Mantido um BillboardGui, alcance 220 e intervalo 0,5 s.

Teste de interface no Play com Explorador selecionado: atributos de apresentação, posição e vida foram preparados **localmente no cliente**, sem usar o teste como prova de progressão. Alvos confirmados: Ilyra; Dawn/Core, Root/Core, Star/Core; RestShrines/Temple/Core; ArenaGate; RootGuardian/Root; AuroraFragment; ReturnStone; desativado na vila após conclusão. Nenhum MessageError no cliente. Sessão encerrada, descartando os estados preparados. Build Rojo aprovado. Ainda falta revisão visual em celular físico e percurso humano com os marcadores novos.
