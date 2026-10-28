#!/usr/bin/env perl
# Modelo de atores com threads + Thread::Queue
use strict;
use warnings;
$| = 1;
use threads;
use Thread::Queue;

package Ator {
    sub new {
        my ($class, %handlers) = @_;
        my $mailbox = Thread::Queue->new;
        my $thr = threads->create(sub {
            my %estado = (saldo => 0);
            while (defined(my $msg = $mailbox->dequeue)) {
                my ($tipo, @args) = @$msg;
                my $h = $handlers{$tipo} or next;
                $h->(\%estado, @args);
            }
            return $estado{saldo};
        });
        return bless { mailbox => $mailbox, thr => $thr }, $class;
    }
    sub send { my ($self, @msg) = @_; $self->{mailbox}->enqueue([@msg]) }
    sub stop { my $self = shift; $self->{mailbox}->end; $self->{thr}->join }
}

my $conta = Ator->new(
    deposita => sub { my ($st, $v) = @_; $st->{saldo} += $v },
    saca     => sub { my ($st, $v) = @_; $st->{saldo} -= $v if $st->{saldo} >= $v },
    consulta => sub { my ($st, $resposta) = @_; $resposta->enqueue($st->{saldo}) },
);

my @clientes = map {
    threads->create(sub { $conta->send(deposita => 10) for 1 .. 100 });
} 1 .. 5;
$_->join for @clientes;
$conta->send(saca => 200);

my $resp = Thread::Queue->new;
$conta->send(consulta => $resp);
print "saldo consultado: ", $resp->dequeue, "\n";

print "saldo final ao parar o ator: ", $conta->stop, "\n";
