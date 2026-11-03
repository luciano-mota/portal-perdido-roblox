# Revisão de integração — 03/11/2026

Base: df5f4017fc5c2b12d13a140d274c6f39947fce41, branch feature/cpp-001-003-bootstrap, PR #30.
Após fetch, HEAD e origin estavam iguais (0 commits à frente/atrás). Havia seis arquivos de código modificados e três referências PNG locais ainda sem versionamento.

## Alterações preservadas e integradas

Movimentos locais de criaturas: raízes, cipó que puxa, mordida/garras e teleporte do Eco; efeitos e animações correspondentes; esquiva direcional. Este checkpoint preserva o trabalho existente. Não representa aprovação integral dessas mecânicas.

Correção desta revisão: o servidor rejeita direções de esquiva com NaN, infinito, tipo incorreto ou componentes fora do intervalo esperado de MoveDirection antes de consumir cooldown ou alterar a física. A normalização de Vector3 com infinito foi reproduzida gerando NaN no Studio.

## Testes executados no Studio

Lugar local: Primeira Fase - As Cronicas do Portal Perdido.rbxl, PlaceId 0.

- Seleção pela interface: Guardião gerado com 150 HP, Explorador gerado com 110 HP, Artífice gerada com 100 HP, em sessões separadas.
- Guardião: W e esquiva por LeftShift, posição Z 32 → 8,40; cooldown registrado no servidor.
- Explorador: cinco pedidos inválidos de Dash (infinito X, NaN X, infinito Y, magnitude extrema e string) rejeitados sem consumir cooldown; direção válida aceita; física permaneceu finita. Teste pelo RemoteEvent real no Play.
- Artífice: caminhada até Ilyra, interação E, missão 1 → 2, caminhada até Sentinela e ataques Q/R; Health do Sentinela 0, QuestIndex 3, Coins 25, jogador 66 HP. Sem alteração de vida ou progresso por script de teste.
- Sete encontros com GeneratedCreature=true: FirstSentinel, RuneMoss, RuneThorn, RuneWisp, ForestThorn, TempleWisp e RootGuardian.
- Última sessão: nenhum MessageError no LogService do cliente ou servidor.
- Build Rojo concluído. Play encerrado em Edit.

## Elenco e direção artística

As três classes iniciais, Ilyra e as espécies de criaturas têm modelos gerados integrados. Isso não equivale a acabamento artístico final nem a fidelidade integral às referências.

As outras três referências fornecidas (maga vermelha/dourada, guerreiro de martelo e personagem de capuz violeta) ainda não têm classes jogáveis implementadas. Preservadas localmente; ampliar o elenco exige também habilidades, equipamentos, animações e equilíbrio. A inspiração é a aventura de grupo, fantasia e drama de Caverna do Dragão, mantendo personagens e história próprios.

## Ainda pendente

Passagem completa após as novas mecânicas; testes específicos de cipó, mordida, garras e teleporte; cooperação com os modelos atuais; avaliação visual das poses em movimento; equilíbrio do chefe; persistência real e aparelho móvel físico. Não houve publicação da experiência nem ativação de compras.
