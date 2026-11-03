# Retorno à etapa final — 02/11/2026

Defeito de orientação corrigido: após vitória registrada contra o Guardião, o objetivo e a conversa de Ilyra ainda orientavam combater. Agora indicam a coleta do Fragmento da Aurora.

Teste de estado no Studio, sem DataStore real: Script temporário no servidor do jogo chama o serviço real de dados para preparar quest=5 e bossDefeated=true. O cliente recebeu esses atributos e exibiu `Recolha o Fragmento da Aurora no altar do santuário.` Após pular o prólogo, selecionar Explorador, navegar até Ilyra e acionar o ProximityPrompt, o diálogo exibiu `O Guardião reconheceu sua vitória. O Fragmento da Aurora espera no altar do santuário.`

As sondas anteriores eram inconclusivas porque require executado diretamente pelo MCP não compartilhava a sessão do serviço em execução. A primeira tentativa de diálogo também manteve a introdução aberta; repetição com seleção normal confirmou a fala. Os scripts temporários se destruíram e o Play foi encerrado, descartando o estado artificial. Não apresentar isso como nova passagem completa nem teste de reconexão com DataStore.

Adicionalmente, ProfileStore agora rejeita progresso inválido dos selos (incluindo NaN, que antes era aceito e impediria comparação da sequência). Nove casos do teste de armazenamento passaram no runtime Luau, preservando estágios válidos 0–3 e compatibilidade com campo ausente.

Pendências externas continuam abertas: seis clientes reais, dispositivo móvel físico, persistência real autorizada e avaliação humana de duração/dificuldade. Nenhuma publicação ou compra ativada.
