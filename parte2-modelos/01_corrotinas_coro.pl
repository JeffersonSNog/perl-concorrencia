#!/usr/bin/env perl
# Parte 2.1 - Corrotinas com Coro (CPAN)
#
# Perl NÃO tem corrotinas nativas na linguagem. O módulo Coro (XS) adiciona
# corrotinas cooperativas reais: cada "Coro" tem sua própria pilha e o
# controle só muda quando a corrotina cede (cede / schedule / bloqueio
# num Coro::Channel, Coro::Semaphore etc.). Tudo roda em UMA thread do SO,
# então não há condição de corrida entre pontos de troca.
#
# Instalação: cpanm Coro   (precisa de compilador C)
use strict;
use warnings;
$| = 1;   # sem buffer no STDOUT: mostra a ordem real das mensagens
use Coro;               # async, cede, schedule
use Coro::Channel;      # canal entre corrotinas
use Coro::Semaphore;

# --- 1) Corrotinas cooperativas alternando com cede ---------------------
my @cs = map {
    my $nome = $_;
    async {
        for my $i (1 .. 3) {
            print "[$nome] passo $i\n";
            cede;                         # devolve o controle ao escalonador
        }
        return "$nome fim";
    };
} qw(A B C);
print "join: ", $_->join, "\n" for @cs;  # A1 B1 C1 A2 B2 C2 ...

# --- 2) Produtor/consumidor com Coro::Channel ---------------------------
my $canal = Coro::Channel->new(2);        # capacidade 2
my $prod = async {
    $canal->put($_), print "produzi $_\n" for 1 .. 5;
    $canal->put(undef);                   # marcador de fim
};
my $cons = async {
    while (defined(my $x = $canal->get)) { print "   consumi $x\n" }
};
$_->join for $prod, $cons;

# --- 3) Semáforo de corrotinas ------------------------------------------
my $sem = Coro::Semaphore->new(1);
my $total = 0;
my @ws = map { async { my $g = $sem->guard; my $v = $total; cede; $total = $v + 1 } } 1 .. 5;
$_->join for @ws;
print "total protegido por Coro::Semaphore = $total\n";
