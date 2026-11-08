# Personagens — referência visual recebida em 02/11/2026

As seis pranchas fornecidas pelo proprietário definem a qualidade desejada. São referências de direção, não modelos 3D prontos, nem evidência de qualidade já alcançada no jogo. A procedência e os direitos de distribuição dos arquivos de referência não foram verificados independentemente.

## Primeiro elenco jogável

| Classe | Prancha | Elementos a traduzir para o jogo |
| --- | --- | --- |
| Explorador | 1, arqueiro verde | Rosto jovem expressivo, olhos verdes, sardas, cabelo castanho ondulado; capa verde em camadas, couro, fecho dourado, botas, aljava e arco verde. |
| Guardião Astral | 3, cavaleiro azul | Cabelo loiro, expressão confiante; armadura articulada, tecido azul, detalhes dourados, capa e escudo astral. |
| Artífice | 4, inventora violeta | Cabelo ruivo cacheado, sardas, óculos; traje violeta, bolsas, grimório, foco arcano e detalhes de bronze. |

As pranchas 2, 5 e 6 alimentam a direção do elenco futuro. Não acrescentam automaticamente classes ao Capítulo 1. Aetherion, Ilyra, o acidente do portal e a sequência floresta → templo → Guardião de Raízes → Fragmento da Aurora continuam canônicos.

## Produção e aceite

Começar pelo Explorador completo. Modelar cabeça e cabelo próprios, roupa e equipamento com silhueta coerente; produzir texturas e deformação das articulações. Preservar os controles, os sockets e as decisões do servidor. Comparar em câmera de gameplay e retrato, em iluminação equivalente, com a prancha 1. Um retrato gerado ou uma textura de rosto isolada não conclui essa etapa.

Validar caminhada sem deslizamento perceptível, corrida, salto, repouso e disparo: mão esquerda segura o arco à frente do corpo; mão direita puxa a corda; flecha parte do arco em direção ao alvo. Rever joelhos, cotovelos, mãos e interferência da capa/aljava durante o movimento. Testar as três classes e repetir o combate após substituir o rig.

Usar atlas compartilhados, geometria simplificada à distância e colisão independente do detalhe cosmético. Medir custo com seis personagens visíveis e combate; qualidade de desktop não comprova desempenho de smartphone. Não fixar uma promessa de fidelidade idêntica às ilustrações em todos os aparelhos.

## Estado real

- O elenco atual continua sendo uma apresentação procedural provisória, distante das pranchas.
- A correção de orientação do arco foi testada localmente: o personagem vira para o alvo e a mão do arco permanece à frente. A revisão visual do ciclo completo ainda está pendente.
- Uma textura original de rosto do Explorador tem prévia local via EditableImage, exclusivamente no Studio. Foi criada antes destas pranchas e ainda precisa convergir para a expressão da referência.
- Geração nativa de avatar falhou (`AvatarCreation submit job failed`). Upload da textura recebeu HTTP 403, `User is moderated`. Nenhum ID de asset foi obtido; não houve publicação, alteração de segurança nem tentativa de contornar a restrição.
- A integração definitiva exige arquivos 3D e texturas permitidos pela plataforma, revisão visual e testes de desempenho. Não está concluída.
