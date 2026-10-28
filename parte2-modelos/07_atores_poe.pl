#!/usr/bin/env perl
# Atores com POE
use strict;
use warnings;
$| = 1;
use POE;

# contador
POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->alias_set('contador');
            $_[HEAP]{total} = 0;
        },
        soma => sub {
            my ($heap, $n, $remetente) = @_[HEAP, ARG0, ARG1];
            $heap->{total} += $n;
            print "contador: +$n => $heap->{total}\n";
            $_[KERNEL]->post($remetente, 'ack', $heap->{total});
        },
        fim => sub { $_[KERNEL]->alias_remove('contador') },
    },
);

# cliente
POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->alias_set('cliente');
            $_[KERNEL]->post(contador => soma => $_, 'cliente') for 1 .. 3;
            $_[KERNEL]->delay(tchau => 0.2);
        },
        ack   => sub { print "  cliente recebeu ack: total=$_[ARG0]\n" },
        tchau => sub {
            print "cliente encerrando\n";
            $_[KERNEL]->post(contador => 'fim');
            $_[KERNEL]->alias_remove('cliente');
        },
    },
);

POE::Kernel->run();
print "POE kernel terminou\n";
