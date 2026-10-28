#!/usr/bin/env perl
# Parte 2.3 - Event loop com AnyEvent (CPAN)
#
# AnyEvent é uma camada que funciona sobre vários loops (EV, Event, POE,
# IO::Async...) e tem um backend em Perl puro. Uma única thread fica no
# loop esperando eventos (timers, I/O, sinais) e chama callbacks.
# AnyEvent->condvar é o "ponto de sincronização" (parecido com uma promise).
use strict;
use warnings;
$| = 1;   # sem buffer no STDOUT: mostra a ordem real das mensagens
use AnyEvent;

my $t0 = AnyEvent->now;
sub log_ { printf "[%.2fs] %s\n", AnyEvent->now - $t0, shift }

my $fim = AnyEvent->condvar;   # condition variable

# Timers: os callbacks rodam quando o loop percebe que o tempo passou
my $w1 = AnyEvent->timer(after => 0.3, cb => sub { log_('timer de 0.3s') });
my $w2 = AnyEvent->timer(after => 0.1, cb => sub { log_('timer de 0.1s') });

# Timer periódico
my $ticks = 0;
my $w3; $w3 = AnyEvent->timer(after => 0, interval => 0.15, cb => sub {
    log_('tick ' . ++$ticks);
    undef $w3 if $ticks == 3;          # destruir o watcher cancela o timer
});

# condvar com begin/end: espera N operações assíncronas terminarem
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

log_('main: registrou tudo, entrando no loop (nada rodou ainda)');
my $r = $fim->recv;           # roda o event loop até alguém chamar ->send
log_("loop terminou com '$r'");
