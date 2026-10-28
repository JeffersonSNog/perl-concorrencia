#!/usr/bin/env perl
# Parte 2.6 - Modelo de Atores implementado com threads + Thread::Queue
#
# Um ator: (1) tem estado PRIVADO, (2) tem uma caixa de mensagens (mailbox),
# (3) processa UMA mensagem por vez, (4) só se comunica enviando mensagens.
# Como ithreads não compartilham memória por padrão, Perl casa muito bem
# com esse modelo: cada ator é uma thread e a mailbox é uma Thread::Queue.
use strict;
use warnings;
$| = 1;   # sem buffer no STDOUT: mostra a ordem real das mensagens
use threads;
use Thread::Queue;

package Ator {
    sub new {
        my ($class, %handlers) = @_;
        my $mailbox = Thread::Queue->new;
        my $thr = threads->create(sub {
            my %estado = (saldo => 0);               # estado privado do ator
            while (defined(my $msg = $mailbox->dequeue)) {
                my ($tipo, @args) = @$msg;
                my $h = $handlers{$tipo} or next;
                $h->(\%estado, @args);
            }
            return $estado{saldo};
        });
        return bless { mailbox => $mailbox, thr => $thr }, $class;
    }
    sub send { my ($self, @msg) = @_; $self->{mailbox}->enqueue([@msg]) }   # assíncrono, não bloqueia
    sub stop { my $self = shift; $self->{mailbox}->end; $self->{thr}->join }
}

# Ator "conta bancária": não precisa de lock, só ele mexe no saldo
my $conta = Ator->new(
    deposita => sub { my ($st, $v) = @_; $st->{saldo} += $v },
    saca     => sub { my ($st, $v) = @_; $st->{saldo} -= $v if $st->{saldo} >= $v },
    # request/reply: a mensagem carrega a "caixa de resposta"
    consulta => sub { my ($st, $resposta) = @_; $resposta->enqueue($st->{saldo}) },
);

# Vários "clientes" (threads) mandando mensagens concorrentemente
my @clientes = map {
    threads->create(sub { $conta->send(deposita => 10) for 1 .. 100 });
} 1 .. 5;
$_->join for @clientes;
$conta->send(saca => 200);

my $resp = Thread::Queue->new;
$conta->send(consulta => $resp);
print "saldo consultado: ", $resp->dequeue, "\n";      # 5*100*10 - 200 = 4800

print "saldo final ao parar o ator: ", $conta->stop, "\n";
