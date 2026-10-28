#!/usr/bin/env perl
# Simulando corrotinas com closures (sem módulos)
use strict;
use warnings;
$| = 1;

# gerador
sub gerador_fib {
    my ($a, $b) = (0, 1);
    return sub { my $r = $a; ($a, $b) = ($b, $a + $b); return $r };
}
my $fib = gerador_fib();
print "fib: ", join(' ', map { $fib->() } 1 .. 10), "\n";

# cada tarefa executa um passo por vez
sub tarefa {
    my ($nome, $passos) = @_;
    my $i = 0;
    return sub {
        $i++;
        print "[$nome] passo $i/$passos\n";
        return $i < $passos;
    };
}

my @fila = (tarefa('A', 3), tarefa('B', 2), tarefa('C', 4));
while (my $t = shift @fila) {
    push @fila, $t if $t->();
}
print "todas as tarefas terminaram\n";
