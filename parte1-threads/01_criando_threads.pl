#!/usr/bin/env perl
# Criando threads
use strict;
use warnings;
$| = 1;
use Config;
BEGIN { die "Este perl não tem suporte a threads\n" unless $Config{useithreads} }
use threads;

sub trabalho {
    my ($nome, $n) = @_;
    my $tid = threads->tid();
    for my $i (1 .. $n) {
        print "[thread $tid - $nome] passo $i\n";
        select(undef, undef, undef, 0.1);
    }
    return "$nome terminou ($n passos)";
}

my $t1 = threads->create(\&trabalho, 'A', 3);
my $t2 = threads->new(\&trabalho, 'B', 2);
my $t3 = async { trabalho('C', 2) };

# retorno em lista
my ($t4) = threads->create({ context => 'list' }, sub { return (1, 2, 3) });

print "join t1: ", $t1->join, "\n";
print "join t2: ", $t2->join, "\n";
print "join t3: ", $t3->join, "\n";
print "join t4: ", join(',', $t4->join), "\n";

my $d = threads->create(sub { select(undef, undef, undef, 0.05) });
$d->detach;

printf "threads ainda rodando: %d\n", scalar threads->list(threads::running);
sleep 1;
print "main (tid ", threads->tid, ") encerrando\n";
