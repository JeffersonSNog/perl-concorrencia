#!/usr/bin/env perl
# Parte 1.1 - Como gerar threads em Perl
#
# Perl usa "ithreads" (interpreter threads): cada thread recebe uma CÓPIA
# do interpretador inteiro. Só funciona se o perl foi compilado com
# useithreads (perl -V:useithreads => 'define').
use strict;
use warnings;
$| = 1;   # sem buffer no STDOUT: mostra a ordem real das mensagens
use Config;
BEGIN { die "Este perl não tem suporte a threads\n" unless $Config{useithreads} }
use threads;

sub trabalho {
    my ($nome, $n) = @_;
    my $tid = threads->tid();                # id da thread atual
    for my $i (1 .. $n) {
        print "[thread $tid - $nome] passo $i\n";
        select(undef, undef, undef, 0.1);    # sleep de 100 ms
    }
    return "$nome terminou ($n passos)";     # valor de retorno
}

# 1) threads->create(\&sub, args...)
my $t1 = threads->create(\&trabalho, 'A', 3);

# 2) threads->new(...) é sinônimo de create
my $t2 = threads->new(\&trabalho, 'B', 2);

# 3) async { ... } cria uma thread a partir de um bloco anônimo
my $t3 = async { trabalho('C', 2) };

# 4) contexto de lista: o retorno é uma lista
my ($t4) = threads->create({ context => 'list' }, sub { return (1, 2, 3) });

# join() espera a thread terminar e devolve seu valor de retorno
print "join t1: ", $t1->join, "\n";
print "join t2: ", $t2->join, "\n";
print "join t3: ", $t3->join, "\n";
print "join t4: ", join(',', $t4->join), "\n";

# detach(): thread "solta"; ninguém espera por ela nem recebe retorno
my $d = threads->create(sub { select(undef, undef, undef, 0.05) });
$d->detach;

# Listagem / estado
printf "threads ainda rodando: %d\n", scalar threads->list(threads::running);
sleep 1;
print "main (tid ", threads->tid, ") encerrando\n";
