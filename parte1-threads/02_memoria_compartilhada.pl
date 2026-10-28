#!/usr/bin/env perl
# Memória compartilhada entre threads
use strict;
use warnings;
$| = 1;
use threads;
use threads::shared;

# variável normal: cada thread tem a sua cópia
my $normal = 0;
threads->create(sub { $normal = 100; print "dentro da thread: normal=$normal\n" })->join;
print "fora da thread:   normal=$normal   (não mudou!)\n\n";

# variável :shared
my $compartilhada :shared = 0;
threads->create(sub { $compartilhada = 100 })->join;
print "shared depois da thread = $compartilhada   (mudou!)\n\n";

my @lista :shared;
my %placar :shared;
my @ts = map {
    my $id = $_;
    threads->create(sub {
        lock(@lista);
        push @lista, "item-$id";
        $placar{"t$id"} = $id * 10;
    });
} 1 .. 4;
$_->join for @ts;
print "lista  = @{[ sort @lista ]}\n";
print "placar = ", join(', ', map {"$_=$placar{$_}"} sort keys %placar), "\n\n";

# estrutura aninhada precisa de shared_clone
my %config :shared;
$config{usuario} = shared_clone({ nome => 'ana', papeis => ['admin', 'dev'] });
threads->create(sub { push @{ $config{usuario}{papeis} }, 'ops' })->join;
print "papeis = @{ $config{usuario}{papeis} }\n";

printf "is_shared(\$normal)=%s  is_shared(\$compartilhada)=%s\n",
    (is_shared($normal) ? 'sim' : 'não'), (is_shared($compartilhada) ? 'sim' : 'não');
