#!/usr/bin/env perl
# Parte 2.4 - Event loop + Promises com Mojolicious (Mojo::IOLoop / Mojo::Promise)
#
# Mojo::IOLoop é um reactor (event loop) single-thread. Mojo::Promise
# implementa a especificação Promises/A+ (a mesma ideia do JavaScript):
# estados pending -> fulfilled | rejected, encadeamento com then/catch/finally,
# e combinadores all / race / any / all_settled.
use strict;
use warnings;
$| = 1;   # sem buffer no STDOUT: mostra a ordem real das mensagens
use Mojo::IOLoop;
use Mojo::Promise;

# Função assíncrona que devolve uma promise resolvida depois de $s segundos
sub espera {
    my ($valor, $s, $falha) = @_;
    my $p = Mojo::Promise->new;
    Mojo::IOLoop->timer($s => sub {
        $falha ? $p->reject("erro em $valor") : $p->resolve($valor);
    });
    return $p;
}

# 1) Encadeamento: o retorno de um then vira o valor do próximo
espera(2, 0.1)
  ->then(sub { my $x = shift; print "then 1 recebeu $x\n"; return $x * 10 })
  ->then(sub { my $x = shift; print "then 2 recebeu $x\n"; return espera($x + 1, 0.1) })  # promise aninhada
  ->then(sub { print "then 3 recebeu $_[0]\n" })
  ->wait;   # roda o loop até essa promise terminar

# 2) Tratamento de erro
espera('B', 0.05, 1)
  ->then(sub { print "nunca roda\n" })
  ->catch(sub { print "catch: $_[0]\n" })
  ->finally(sub { print "finally sempre roda\n" })
  ->wait;

# 3) Combinadores
Mojo::Promise->all(espera('a', 0.3), espera('b', 0.1), espera('c', 0.2))
  ->then(sub { print "all  => ", join(',', map { $_->[0] } @_), "  (ordem preservada)\n" })
  ->wait;

Mojo::Promise->race(espera('lento', 0.3), espera('rápido', 0.1))
  ->then(sub { print "race => $_[0]\n" })
  ->wait;

Mojo::Promise->all_settled(espera('ok', 0.1), espera('x', 0.1, 1))
  ->then(sub { print "all_settled => ", join(' | ', map { "$_->{status}" } @_), "\n" })
  ->wait;

# 4) Timeout como promise
Mojo::Promise->timeout(0.1 => 'demorou demais')
  ->catch(sub { print "timeout: $_[0]\n" })->wait;

# 5) Event loop "cru": recorrente + one-shot + stop
my $n = 0;
my $id = Mojo::IOLoop->recurring(0.05 => sub { print "recurring ", ++$n, "\n" });
Mojo::IOLoop->timer(0.18 => sub { Mojo::IOLoop->remove($id); Mojo::IOLoop->stop });
Mojo::IOLoop->start;
print "loop parado\n";

# Obs.: com Future::AsyncAwait (XS) instalado, Mojolicious aceita
#   use Mojo::Base -async_await;
#   async sub busca { my $x = await espera(1, 0.1); return $x + 1 }
