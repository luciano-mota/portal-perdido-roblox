# Estado de salvamento — 02/11/2026

Defeito: Data.mutate incrementava revision, mas não invalidava DataStatus=Saved. Além disso, Data.save marcava Saved após gravar um snapshot mesmo se o perfil tivesse sido alterado durante a operação.

Correção: mutações persistíveis marcam Pending. Cada gravação captura a revisão do snapshot e só marca Saved se essa revisão ainda for atual. O diário informa que aguarda salvamento automático. StudioMemory não muda para Pending, pois nesse modo não há persistência real.

Validação no runtime Luau do Studio: clone temporário do módulo real com injeção de sessão e adapter em memória. Quatro verificações aprovadas: mutação invalida Saved; snapshot atual marca Saved; mutação dentro da chamada ao adapter mantém Pending e preserva o saldo novo; sessão temporária mantém StudioMemory. Clone removido ao final. A primeira sonda tentou criar Player e foi rejeitada por WritePlayer; a sonda corrigida usa objeto de teste com atributos, sem jogador real.

Build Rojo e diff check aprovados. Este ensaio não valida DataStore remoto, reconexão real ou persistência publicada.
