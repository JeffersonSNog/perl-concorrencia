#!/usr/bin/env perl
# Parte 1.3 - Sincronização: condição de corrida e lock()
#
# lock() é um lock consultivo (advisory) e RECURSIVO sobre uma variável
# shared. Ele é liberado automaticamente ao sair do escopo léxico
# (não existe unlock).
use strict;
use warnings;
$| = 1;   # sem buffer no STDOUT: mostra a ordem real das mensagens
use threads;
use threads::shared;

my $THREADS = 4;
my $ITER    = 20_000;

sub roda {
    my ($com_lock) = @_;
    my $contador :shared = 0;
    my @ts = map {
        threads->create(sub {
            for (1 .. $ITER) {
                if ($com_lock) {
                    lock($contador);          # seção crítica
                    $contador = $contador + 1;
                } else {
                    my $v = $contador;        # lê
                    $v++;                     # modifica
                    $contador = $v;           # escreve -> outra thread pode ter escrito no meio!
                }
            }
        });
    } 1 .. $THREADS;
    $_->join for @ts;
    return $contador;
}

my $esperado = $THREADS * $ITER;
printf "sem lock: %6d (esperado %d)  <- condição de corrida\n", roda(0), $esperado;
printf "com lock: %6d (esperado %d)\n", roda(1), $esperado;

# lock é recursivo: a mesma thread pode travar de novo sem deadlock
my $x :shared = 0;
sub incrementa { lock($x); $x++ }
threads->create(sub { lock($x); incrementa() for 1 .. 3 })->join;
print "lock recursivo ok, x=$x\n";
