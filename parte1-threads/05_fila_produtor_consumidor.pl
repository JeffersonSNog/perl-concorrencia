#!/usr/bin/env perl
# Parte 1.5 - Comunicação por fila: Thread::Queue (produtor/consumidor)
#
# Thread::Queue é uma fila thread-safe (já faz lock internamente).
# É a forma idiomática de passar dados entre threads em Perl, em vez de
# compartilhar muitas variáveis.
use strict;
use warnings;
$| = 1;   # sem buffer no STDOUT: mostra a ordem real das mensagens
use threads;
use Thread::Queue;

my $fila       = Thread::Queue->new();
my $resultados = Thread::Queue->new();
my $N_WORKERS  = 3;

# Consumidores (pool de workers)
my @workers = map {
    my $id = $_;
    threads->create(sub {
        # dequeue bloqueia até ter item; retorna undef quando a fila é finalizada
        while (defined(my $n = $fila->dequeue)) {
            $resultados->enqueue([$id, $n, $n * $n]);
        }
    });
} 1 .. $N_WORKERS;

# Produtor
$fila->enqueue($_) for 1 .. 10;
$fila->end;                       # sinaliza que não haverá mais itens

$_->join for @workers;
$resultados->end;

while (defined(my $r = $resultados->dequeue)) {
    printf "worker %d calculou %2d^2 = %3d\n", @$r;
}

# Fila limitada: enqueue bloqueia quando cheia (back-pressure)
my $limitada = Thread::Queue->new();
$limitada->limit = 2;
my $prod = threads->create(sub { $limitada->enqueue($_) for 1 .. 5; $limitada->end });
while (defined(my $x = $limitada->dequeue)) { print "consumi $x (pendentes: ", $limitada->pending // 0, ")\n" }
$prod->join;
