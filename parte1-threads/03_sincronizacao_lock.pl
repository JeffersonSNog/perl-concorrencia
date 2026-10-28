#!/usr/bin/env perl
# Condição de corrida e lock()
use strict;
use warnings;
$| = 1;
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
                    lock($contador);
                    $contador = $contador + 1;
                } else {
                    my $v = $contador;
                    $v++;
                    $contador = $v;
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

# lock é recursivo
my $x :shared = 0;
sub incrementa { lock($x); $x++ }
threads->create(sub { lock($x); incrementa() for 1 .. 3 })->join;
print "lock recursivo ok, x=$x\n";
