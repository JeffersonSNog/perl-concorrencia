#!/usr/bin/env perl
# Semáforo e variáveis de condição
use strict;
use warnings;
$| = 1;
use threads;
use threads::shared;
use Thread::Semaphore;
use Time::HiRes qw(sleep time);

# semáforo: no máximo 2 threads ao mesmo tempo
my $sem       = Thread::Semaphore->new(2);
my $dentro :shared = 0;
my $pico   :shared = 0;

my @ts = map {
    my $id = $_;
    threads->create(sub {
        $sem->down;
        { lock($dentro); $dentro++; $pico = $dentro if $dentro > $pico; }
        print "  thread $id entrou (dentro=$dentro)\n";
        sleep 0.2;
        { lock($dentro); $dentro--; }
        $sem->up;
    });
} 1 .. 6;
$_->join for @ts;
print "pico de threads simultâneas = $pico (limite 2)\n\n";

# cond_wait / cond_broadcast
my $pronto :shared = 0;

my @esperando = map {
    my $id = $_;
    threads->create(sub {
        lock($pronto);
        cond_wait($pronto) until $pronto;
        print "  trabalhador $id acordou (pronto=$pronto)\n";
    });
} 1 .. 3;

sleep 0.3;
{
    lock($pronto);
    $pronto = 1;
    print "main: sinal enviado a todos\n";
    cond_broadcast($pronto);
}
$_->join for @esperando;

# espera com timeout
my $nunca :shared = 0;
{
    lock($nunca);
    my $ok = cond_timedwait($nunca, time() + 0.5);
    print "cond_timedwait retornou ", ($ok ? 'sinal' : 'timeout'), "\n";
}
