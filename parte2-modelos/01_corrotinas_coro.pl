#!/usr/bin/env perl
# Corrotinas com Coro (precisa de: cpanm Coro)
use strict;
use warnings;
$| = 1;
use Coro;
use Coro::Channel;
use Coro::Semaphore;

my @cs = map {
    my $nome = $_;
    async {
        for my $i (1 .. 3) {
            print "[$nome] passo $i\n";
            cede;
        }
        return "$nome fim";
    };
} qw(A B C);
print "join: ", $_->join, "\n" for @cs;

# produtor/consumidor com canal
my $canal = Coro::Channel->new(2);
my $prod = async {
    $canal->put($_), print "produzi $_\n" for 1 .. 5;
    $canal->put(undef);
};
my $cons = async {
    while (defined(my $x = $canal->get)) { print "   consumi $x\n" }
};
$_->join for $prod, $cons;

# semáforo
my $sem = Coro::Semaphore->new(1);
my $total = 0;
my @ws = map { async { my $g = $sem->guard; my $v = $total; cede; $total = $v + 1 } } 1 .. 5;
$_->join for @ws;
print "total protegido por Coro::Semaphore = $total\n";
