# Desenvolvimento em andamento — Capítulo 1

Objetivo autorizado: completar o primeiro capítulo jogável da ideia inicial, preservando o roteiro, sem publicação e sem compras.

## Já implementado nesta expansão

- Prólogo, cinco missões encadeadas, três inscrições, puzzle do templo, Guardião de Raízes em duas fases e Fragmento da Aurora com epílogo.
- Três classes com armas visíveis, ataques distintos, habilidades e esquiva; servidor valida ações, dano, alcance, cooldown e recompensas.
- Vale com vila, floresta, trilhas laterais, santuário e arena; Ilyra e três espécies de criaturas com modelos procedurais originais.
- HUD, retratos, diário, telas de seleção e conclusão, controles touch e áudio local com opção de silenciar.
- Checkpoints, fontes de recuperação e crédito cooperativo por participação/apoio.
- Perfil versionado com lease de sessão e proteção contra falhas. No Studio, modo temporário explícito: não se alegou salvamento real em DataStore.
- Contingência visual/animação quando ContentProvider confirma falha de assets, sem substituir controles ou assets que carregaram.

## Evidência obtida

- Uma passagem inteira com Explorador: Ilyra → Sentinela → três guardas/inscrições → selos (erro e sequência correta) → fase 2 do chefe → fragmento → conclusão. QuestIndex=6, HasFragment=true e Coins=200. Repetir fragmento manteve 200.
- Guardião: missão inicial e redução real de dano 10 → 3 durante Égide.
- Oito testes do protocolo de armazenamento executados no Luau do Studio: perfil novo, snapshot, sessão concorrente, lease expirada, sessão antiga bloqueada, liberação/recarga, corrupção/saldos inválidos e falha de rede.
- Medição inicial de 180 frames na arena: média 60,02 FPS, mediana 60,00 e percentil de frames lentos equivalente a 56,38 FPS no desktop atual. Não é benchmark mobile. Memória total informada pelo processo do Studio: 2715 MB; não confundir com memória em celular.

## Em validação / a concluir antes de declarar pronto

- Regressão após o acabamento visual, novas rotas de obstáculos, fontes de recuperação e aumento da vida do chefe (a primeira passagem usou 700 HP; a versão atual usa 1800 e escala cooperativa).
- Artífice, habilidades, mortes/checkpoints, cooperação do capítulo inteiro e rejeição de pedidos inválidos.
- Emulador em telas pequenas, qualidade gráfica, medidas sob combate, poses/armas e revisão de Output.
- Documentação/manifesto finais e evidências no PR #30.

## Limites externos conhecidos

- O Studio está recebendo HTTP 403 para assets do avatar/animações e alguns componentes nativos. A contingência mantém o avatar visível e animado; não foi alterada a conta nem automatizado login.
- PlaceId=0 e GameId=0: a versão local não permite comprovar persistência real publicada. O protocolo foi testado com adapter determinístico, sem tocar dados reais.
- Falta aparelho móvel físico e avaliação visual humana. Não declarar desempenho mobile aprovado apenas pela emulação.

## Correção de passadas e uso de armas — 02/11/2026

Causa reproduzida: o rig local usa 15 `AnimationConstraint` e nenhum `Motor6D`. A contingência anterior procurava apenas Motor6D, coletando zero articulações. O problema se somava ao HTTP 403 das animações nativas. Agora ambos os tipos são reconhecidos, e `Transform` é aplicado em PreSimulation conforme a documentação oficial, sem alterar attachments, raiz, controles ou dano.

Implementado `CharacterMotion`: passada proporcional à velocidade, flexão alternada de joelhos/tornozelos, balanço dos braços, tronco, transições suaves, salto e sequências originais de espada, arco e lançamento arcano. Os eventos aprovados pelo servidor acionam os movimentos nos clientes próximos. Trajes receberam couro, ombreiras/peitoral, capa curta e bandoleira ou estola/grimório.

Evidência no Play do Studio, classe Artífice:
- 31 amostras em movimento: LeftKnee entre 0,050 e 0,870 rad; RightShoulder entre -0,546 e 0,458 rad.
- Ataques reais por Q, 200 amostras: RightShoulder entre -1,348 e -0,039 rad; evento confirmou classe Artificer.
- Três previews instanciados sem colisões: Guardian 22 partes, Explorer 24, Artificer 20.
- Poses das três classes verificadas para valores finitos; ainda falta aprovação visual dos três movimentos em combate e avaliação em celular.
- Erros remanescentes consultados no LogService são falhas de carregamento externo; não foi encontrado erro Luau nesta sessão.

Referência: https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint (suporte a Transform e migração Motor6D).

Esta é uma melhoria funcional de animação, não aprovação de qualidade humana final. Modelagem/realismo final, cooperação e regressão do capítulo continuam em desenvolvimento.
