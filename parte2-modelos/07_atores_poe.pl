#!/usr/bin/env perl
# Parte 2.7 - Atores com POE (Perl Object Environment, CPAN)
#
# POE é o framework de concorrência mais antigo do Perl (1998). Cada
# POE::Session funciona como um ator: tem um alias (endereço), estado
# próprio no HEAP e só reage a eventos (mensagens) enviados pelo kernel
# com post(). Tudo roda num event loop cooperativo de uma thread.
use strict;
use warnings;
$| = 1;   # sem buffer no STDOUT: mostra a ordem real das mensagens
use POE;

# Ator "contador"
POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->alias_set('contador');      # nome para receber mensagens
            $_[HEAP]{total} = 0;                    # estado privado
        },
        soma => sub {
            my ($heap, $n, $remetente) = @_[HEAP, ARG0, ARG1];
            $heap->{total} += $n;
            print "contador: +$n => $heap->{total}\n";
            $_[KERNEL]->post($remetente, 'ack', $heap->{total});   # responde
        },
        fim => sub { $_[KERNEL]->alias_remove('contador') },
    },
);

# Ator "cliente"
POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->alias_set('cliente');
            $_[KERNEL]->post(contador => soma => $_, 'cliente') for 1 .. 3;
            $_[KERNEL]->delay(tchau => 0.2);          # timer
        },
        ack   => sub { print "  cliente recebeu ack: total=$_[ARG0]\n" },
        tchau => sub {
            print "cliente encerrando\n";
            $_[KERNEL]->post(contador => 'fim');
            $_[KERNEL]->alias_remove('cliente');
        },
    },
);

POE::Kernel->run();     # event loop; termina quando não há mais sessões ativas
print "POE kernel terminou\n";
