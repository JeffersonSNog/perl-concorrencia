#!/usr/bin/env perl
# Parte 1.4 - Sincronização: semáforos e variáveis de condição
use strict;
use warnings;
$| = 1;   # sem buffer no STDOUT: mostra a ordem real das mensagens
use threads;
use threads::shared;
use Thread::Semaphore;
use Time::HiRes qw(sleep time);

# --- 1) Thread::Semaphore: no máximo 2 threads na "área" ao mesmo tempo
my $sem       = Thread::Semaphore->new(2);
my $dentro :shared = 0;
my $pico   :shared = 0;

my @ts = map {
    my $id = $_;
    threads->create(sub {
        $sem->down;                                   # P / acquire
        { lock($dentro); $dentro++; $pico = $dentro if $dentro > $pico; }
        print "  thread $id entrou (dentro=$dentro)\n";
        sleep 0.2;
        { lock($dentro); $dentro--; }
        $sem->up;                                     # V / release
    });
} 1 .. 6;
$_->join for @ts;
print "pico de threads simultâneas = $pico (limite 2)\n\n";

# --- 2) cond_wait / cond_signal / cond_broadcast ----------------------
# Uma thread espera até que uma condição seja verdadeira.
my $pronto :shared = 0;

my @esperando = map {
    my $id = $_;
    threads->create(sub {
        lock($pronto);
        cond_wait($pronto) until $pronto;   # libera o lock e dorme
        print "  trabalhador $id acordou (pronto=$pronto)\n";
    });
} 1 .. 3;

sleep 0.3;
{
    lock($pronto);
    $pronto = 1;
    print "main: sinal enviado a todos\n";
    cond_broadcast($pronto);               # acorda TODAS (cond_signal acorda uma)
}
$_->join for @esperando;

# --- 3) cond_timedwait: espera com timeout ----------------------------
my $nunca :shared = 0;
{
    lock($nunca);
    my $ok = cond_timedwait($nunca, time() + 0.5);
    print "cond_timedwait retornou ", ($ok ? 'sinal' : 'timeout'), "\n";
}
