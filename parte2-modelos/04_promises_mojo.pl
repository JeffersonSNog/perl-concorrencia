#!/usr/bin/env perl
# Promises com Mojo::Promise e Mojo::IOLoop
use strict;
use warnings;
$| = 1;
use Mojo::IOLoop;
use Mojo::Promise;

sub espera {
    my ($valor, $s, $falha) = @_;
    my $p = Mojo::Promise->new;
    Mojo::IOLoop->timer($s => sub {
        $falha ? $p->reject("erro em $valor") : $p->resolve($valor);
    });
    return $p;
}

# encadeamento
espera(2, 0.1)
  ->then(sub { my $x = shift; print "then 1 recebeu $x\n"; return $x * 10 })
  ->then(sub { my $x = shift; print "then 2 recebeu $x\n"; return espera($x + 1, 0.1) })
  ->then(sub { print "then 3 recebeu $_[0]\n" })
  ->wait;

# erro
espera('B', 0.05, 1)
  ->then(sub { print "nunca roda\n" })
  ->catch(sub { print "catch: $_[0]\n" })
  ->finally(sub { print "finally sempre roda\n" })
  ->wait;

Mojo::Promise->all(espera('a', 0.3), espera('b', 0.1), espera('c', 0.2))
  ->then(sub { print "all  => ", join(',', map { $_->[0] } @_), "\n" })
  ->wait;

Mojo::Promise->race(espera('lento', 0.3), espera('rápido', 0.1))
  ->then(sub { print "race => $_[0]\n" })
  ->wait;

Mojo::Promise->all_settled(espera('ok', 0.1), espera('x', 0.1, 1))
  ->then(sub { print "all_settled => ", join(' | ', map { "$_->{status}" } @_), "\n" })
  ->wait;

Mojo::Promise->timeout(0.1 => 'demorou demais')
  ->catch(sub { print "timeout: $_[0]\n" })->wait;

# loop direto
my $n = 0;
my $id = Mojo::IOLoop->recurring(0.05 => sub { print "recurring ", ++$n, "\n" });
Mojo::IOLoop->timer(0.18 => sub { Mojo::IOLoop->remove($id); Mojo::IOLoop->stop });
Mojo::IOLoop->start;
print "loop parado\n";
