#!/usr/bin/env perl
# Futures (módulo Future)
use strict;
use warnings;
$| = 1;
use Future;

# loop simples só para o exemplo
my @pendentes;
sub mais_tarde { push @pendentes, shift }
sub roda_loop  { while (my $cb = shift @pendentes) { $cb->() } }

sub busca_usuario {
    my ($id) = @_;
    my $f = Future->new;
    mais_tarde(sub { $id > 0 ? $f->done({ id => $id, nome => "user$id" }) : $f->fail("id inválido") });
    return $f;
}

my $f1 = busca_usuario(7)
  ->then(sub { my $u = shift; Future->done("Olá, $u->{nome}") })
  ->on_done(sub { print "on_done: $_[0]\n" });

my $f2 = busca_usuario(-1)
  ->else(sub { my $erro = shift; print "else tratou: $erro\n"; Future->done('valor padrão') });

my $todos = Future->needs_all(map { busca_usuario($_) } 1 .. 3)
  ->on_done(sub { print "needs_all: ", join(', ', map { $_->{nome} } @_), "\n" });

my $qualquer = Future->wait_any(busca_usuario(10), busca_usuario(20))
  ->on_done(sub { print "wait_any: $_[0]{nome}\n" });

roda_loop();
print "f2 resultado = ", $f2->get, "\n";
printf "estados: f1 %s, todos %s\n", ($f1->is_done ? 'done' : 'pending'), ($todos->is_done ? 'done' : 'pending');
