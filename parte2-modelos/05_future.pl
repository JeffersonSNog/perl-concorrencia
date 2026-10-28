#!/usr/bin/env perl
# Parte 2.5 - Futures (CPAN: Future)
#
# Future é o outro modelo de "promise" muito usado em Perl (base do
# IO::Async e do Future::AsyncAwait). Um Future representa um resultado
# que ainda vai existir: done (sucesso), fail (erro) ou cancel.
# Aqui o "loop" é simulado por uma fila de callbacks para mostrar que
# Future não depende de nenhum event loop específico.
use strict;
use warnings;
$| = 1;   # sem buffer no STDOUT: mostra a ordem real das mensagens
use Future;

my @pendentes;                          # "event loop" de brinquedo
sub mais_tarde { push @pendentes, shift }
sub roda_loop  { while (my $cb = shift @pendentes) { $cb->() } }

sub busca_usuario {
    my ($id) = @_;
    my $f = Future->new;
    mais_tarde(sub { $id > 0 ? $f->done({ id => $id, nome => "user$id" }) : $f->fail("id inválido") });
    return $f;
}

# then encadeia (o callback deve devolver outro Future)
my $f1 = busca_usuario(7)
  ->then(sub { my $u = shift; Future->done("Olá, $u->{nome}") })
  ->on_done(sub { print "on_done: $_[0]\n" });

my $f2 = busca_usuario(-1)
  ->else(sub { my $erro = shift; print "else tratou: $erro\n"; Future->done('valor padrão') });

# needs_all: espera todos (como Promise.all)
my $todos = Future->needs_all(map { busca_usuario($_) } 1 .. 3)
  ->on_done(sub { print "needs_all: ", join(', ', map { $_->{nome} } @_), "\n" });

# wait_any: o primeiro que terminar (como Promise.race)
my $qualquer = Future->wait_any(busca_usuario(10), busca_usuario(20))
  ->on_done(sub { print "wait_any: $_[0]{nome}\n" });

roda_loop();
print "f2 resultado = ", $f2->get, "\n";
printf "estados: f1 %s, todos %s\n", ($f1->is_done ? 'done' : 'pending'), ($todos->is_done ? 'done' : 'pending');
