#!/usr/bin/env perl
# Produtor/consumidor com Thread::Queue
use strict;
use warnings;
$| = 1;
use threads;
use Thread::Queue;

my $fila       = Thread::Queue->new();
my $resultados = Thread::Queue->new();
my $N_WORKERS  = 3;

# workers
my @workers = map {
    my $id = $_;
    threads->create(sub {
        while (defined(my $n = $fila->dequeue)) {
            $resultados->enqueue([$id, $n, $n * $n]);
        }
    });
} 1 .. $N_WORKERS;

# produtor
$fila->enqueue($_) for 1 .. 10;
$fila->end;

$_->join for @workers;
$resultados->end;

while (defined(my $r = $resultados->dequeue)) {
    printf "worker %d calculou %2d^2 = %3d\n", @$r;
}

# fila com limite
my $limitada = Thread::Queue->new();
$limitada->limit = 2;
my $prod = threads->create(sub { $limitada->enqueue($_) for 1 .. 5; $limitada->end });
while (defined(my $x = $limitada->dequeue)) { print "consumi $x (pendentes: ", $limitada->pending // 0, ")\n" }
$prod->join;
