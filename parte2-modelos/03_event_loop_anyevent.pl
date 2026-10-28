#!/usr/bin/env perl
# Event loop com AnyEvent
use strict;
use warnings;
$| = 1;
use AnyEvent;

my $t0 = AnyEvent->now;
sub log_ { printf "[%.2fs] %s\n", AnyEvent->now - $t0, shift }

my $fim = AnyEvent->condvar;

my $w1 = AnyEvent->timer(after => 0.3, cb => sub { log_('timer de 0.3s') });
my $w2 = AnyEvent->timer(after => 0.1, cb => sub { log_('timer de 0.1s') });

# timer periódico
my $ticks = 0;
my $w3; $w3 = AnyEvent->timer(after => 0, interval => 0.15, cb => sub {
    log_('tick ' . ++$ticks);
    undef $w3 if $ticks == 3;
});

# espera as 3 tarefas terminarem
my $grupo = AnyEvent->condvar;
my %resultado;
for my $tarefa (qw(x y z)) {
    $grupo->begin;
    my $w; $w = AnyEvent->timer(after => rand(0.4), cb => sub {
        undef $w;
        $resultado{$tarefa} = uc $tarefa;
        log_("tarefa $tarefa pronta");
        $grupo->end;
    });
}
$grupo->cb(sub { log_('grupo completo: ' . join(',', sort values %resultado)); $fim->send('ok') });

log_('main: registrou tudo, entrando no loop');
my $r = $fim->recv;
log_("loop terminou com '$r'");
