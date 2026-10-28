#!/usr/bin/env perl
# Parte 2.2 - "Corrotinas" em Perl puro: geradores com closures
#
# Sem Coro, a linguagem não consegue suspender uma sub no meio e voltar
# depois (não há yield). O que dá para fazer é guardar o estado numa
# closure e simular um gerador / máquina de estados. É o mesmo truque
# que muitas bibliotecas usam por baixo dos panos.
use strict;
use warnings;
$| = 1;   # sem buffer no STDOUT: mostra a ordem real das mensagens

# Gerador: cada chamada "retoma" de onde parou
sub gerador_fib {
    my ($a, $b) = (0, 1);
    return sub { my $r = $a; ($a, $b) = ($b, $a + $b); return $r };
}
my $fib = gerador_fib();
print "fib: ", join(' ', map { $fib->() } 1 .. 10), "\n";

# Escalonador round-robin cooperativo: cada tarefa é uma closure que
# executa UM passo e devolve falso quando terminou.
sub tarefa {
    my ($nome, $passos) = @_;
    my $i = 0;
    return sub {
        $i++;
        print "[$nome] passo $i/$passos\n";
        return $i < $passos;          # true = ainda tem trabalho
    };
}

my @fila = (tarefa('A', 3), tarefa('B', 2), tarefa('C', 4));
while (my $t = shift @fila) {
    push @fila, $t if $t->();         # "cede": volta pro fim da fila
}
print "todas as tarefas terminaram\n";
