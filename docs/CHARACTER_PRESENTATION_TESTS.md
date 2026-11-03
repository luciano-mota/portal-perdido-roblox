# Apresentação dos personagens — 02/11/2026

Alterações posteriores a 547fee7, registradas na mesma branch de PR #30.

## Implementação

- Ilyra: cabeça proporcional, botas, articulações de cabeça e braços; acompanhamento do jogador, piscadas e gestos durante diálogo.
- Inimigos: articulações locais para caminhada, flutuação do Eco e preparação/impacto dos golpes. O servidor continua decidindo dano e progressão.
- Explorador: sinal das poses corrigido, empunhadura presa à mão, arco orientado verticalmente e duas metades da corda ligadas à mão de puxada. Rotação temporária para o alvo confirmado e flecha visual partindo do arco.
- Rosto original do Explorador: prévia de imagem local restrita ao Studio, com fallback se indisponível. Não existe asset publicado aprovado.

## Evidências coletadas no Studio

- Antes da correção, a pose do ombro colocava a mão 1,705 studs atrás do personagem. Após a correção, seis amostras de disparo mostraram a mão pelo menos 1,745 studs à frente, empunhadura sem distância da mão e dois segmentos de corda ativos.
- Disparo após virar de costas: alinhamento com o alvo passou de -0,9704 para 0,9999997. AutoRotate voltou a true após o ataque.
- Ilyra: três motores; erro de posição das articulações igual a zero; braço variou entre -0,389 e -0,171 rad durante conversa.
- Sentinela/chefe: cinco motores; Predador: cinco; Eco: um. Foram observadas variações de passada, preparação dos braços e flutuação.
- Passagem solo com Explorador após articulação dos atores: cinco missões concluídas, chefe nas duas fases, fragmento e 200 moedas. Houve uma morte na segunda fase e retorno pelo checkpoint da arena. Navegação do chefe usou MoveTo de teste e ataques pelas entradas Q/R; isso não mede dificuldade humana.
- A prévia de rosto apareceu no personagem e em retrato no Studio. Ainda há cabeça/cabelo procedurais provisórios; não equivale à qualidade das referências.
- Dois erros em sondas de teste foram corrigidos: nomes de pernas repetidos e variável local sombreada. Não foram defeitos dos módulos do jogo. Falhas HTTP 403 de assets externos continuaram presentes.

## Limitações e próximos critérios

Revisão visual contínua do disparo, arte final, seis jogadores e desempenho em smartphone físico permanecem pendentes. O build Rojo passou; build não substitui teste de gameplay. Geração de avatar falhou e upload de imagem retornou `User is moderated`. Não houve mudança de conta, segurança, publicação ou compras.

As novas referências e critérios visuais estão em CHARACTER_TARGETS.md. PNGs de referência locais ainda não são assets distribuídos pelo jogo.

## Nova tentativa de upload

O upload seguinte foi aceito, retornando `rbxassetid://77141053762926`. Entretanto, PreloadAsync no cliente do Studio retornou `Failure` (a chamada pcall concluiu sem exceção). Portanto, upload aceito não significa carregamento aprovado. FacePresentation verifica o resultado antes de substituir a apresentação: mantém prévia local no Studio ou geometria existente quando o asset falha. Build Rojo passou após a mudança. A causa da falha de entrega ainda não foi determinada.
