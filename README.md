# Concorrência em Perl - Parte 3

Exemplos de código para a análise de concorrência na linguagem **Perl 5**.

Trabalho da disciplina Paradigmas de Programação.

**Integrantes:** Jefferson Santana Nogueira, João Pedro Ferreira da Rocha e Lucas de Pinho Ribeiro dos Santos.


## Requisitos

- Perl 5.10+ compilado com threads (`perl -V:useithreads` deve mostrar `'define'`).
  Testado com Perl 5.42.3 (`x86_64-cygwin-thread-multi`, o perl do Git for Windows).
- Parte 1 e os exemplos `02`, `06`, `08` da Parte 2 usam **só módulos core**.
- Os outros exemplos da Parte 2 usam módulos do CPAN:

```bash
cpanm --installdeps .
```

## Estrutura

| Arquivo | Assunto |
|---|---|
| `parte1-threads/01_criando_threads.pl` | `threads->create`, `async`, `join`, `detach`, retorno de valores |
| `parte1-threads/02_memoria_compartilhada.pl` | Cópia por padrão × `:shared`, `shared_clone`, `is_shared` |
| `parte1-threads/03_sincronizacao_lock.pl` | Condição de corrida e `lock()` (recursivo, por escopo) |
| `parte1-threads/04_semaforo_e_condicao.pl` | `Thread::Semaphore`, `cond_wait`, `cond_broadcast`, `cond_timedwait` |
| `parte1-threads/05_fila_produtor_consumidor.pl` | `Thread::Queue`: pool de workers, fila limitada |
| `parte2-modelos/01_corrotinas_coro.pl` | Corrotinas reais com **Coro** (`async`, `cede`, `Coro::Channel`) |
| `parte2-modelos/02_corrotinas_closures.pl` | Geradores e escalonador cooperativo com closures (Perl puro) |
| `parte2-modelos/03_event_loop_anyevent.pl` | Event loop **AnyEvent**: timers, `condvar`, `begin/end` |
| `parte2-modelos/04_promises_mojo.pl` | **Mojo::IOLoop** + **Mojo::Promise** (`then/catch/finally`, `all`, `race`) |
| `parte2-modelos/05_future.pl` | **Future**: `then/else`, `needs_all`, `wait_any` |
| `parte2-modelos/06_atores_threads.pl` | Modelo de atores com threads + `Thread::Queue` como mailbox |
| `parte2-modelos/07_atores_poe.pl` | Sessões do **POE** como atores (mensagens via `post`) |
| `parte2-modelos/08_fork_processos.pl` | Multiprocesso com `fork`, `pipe`, `waitpid` |

## Como executar

```bash
perl parte1-threads/03_sincronizacao_lock.pl
```

Saída esperada (o valor "sem lock" muda a cada execução):

```
sem lock:  31814 (esperado 80000)  <- condição de corrida
com lock:  80000 (esperado 80000)
```

## Resumo da análise

- **Threads (ithreads):** cada thread é uma cópia do interpretador. Nada é
  compartilhado por padrão; compartilhar exige `threads::shared`. São pesadas
  e a própria documentação as marca como "discouraged" para uso geral.
- **Sincronização:** `lock`, `cond_*`, `Thread::Semaphore`, `Thread::Queue`.
- **Corrotinas:** não existem na linguagem; o módulo **Coro** adiciona.
- **Event loop / Promises:** não existe na linguagem; bibliotecas: AnyEvent, EV,
  Mojo::IOLoop, IO::Async, POE. Promises: Mojo::Promise, Future, Promises.
  `async/await` via Future::AsyncAwait.
- **Atores:** sem biblioteca dominante; POE e Reflex têm sessões no estilo ator,
  e o modelo se monta facilmente com threads + filas.
- **Outras formas:** `fork` (a mais tradicional), Parallel::ForkManager, MCE.

## Referências

Documentação oficial do Perl (perldoc):

- perlthrtut, tutorial de threads: https://perldoc.perl.org/perlthrtut
- threads: https://perldoc.perl.org/threads
- threads::shared: https://perldoc.perl.org/threads::shared
- Thread::Queue: https://perldoc.perl.org/Thread::Queue
- Thread::Semaphore: https://perldoc.perl.org/Thread::Semaphore
- fork: https://perldoc.perl.org/functions/fork
- perlipc, comunicação entre processos: https://perldoc.perl.org/perlipc
- perlfork, emulação de fork no Windows: https://perldoc.perl.org/perlfork

Módulos do CPAN e especificações:

- Coro: https://metacpan.org/pod/Coro
- AnyEvent: https://metacpan.org/pod/AnyEvent
- Mojo::Promise / Mojo::IOLoop: https://docs.mojolicious.org/Mojo/Promise
- Future: https://metacpan.org/pod/Future
- Future::AsyncAwait: https://metacpan.org/pod/Future::AsyncAwait
- POE: https://metacpan.org/pod/POE
- Parallel::ForkManager: https://metacpan.org/pod/Parallel::ForkManager
- MCE: https://metacpan.org/pod/MCE
- Promises/A+: https://promisesaplus.com

Acesso em 28/10/2026.
