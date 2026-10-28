#!/usr/bin/env perl
# Parte 1.2 - Compartilhamento de memória entre threads
#
# Por padrão NADA é compartilhado: ao criar uma thread, o interpretador
# é clonado e cada thread passa a ter sua própria cópia das variáveis.
# Para compartilhar é preciso marcar explicitamente com threads::shared.
use strict;
use warnings;
$| = 1;   # sem buffer no STDOUT: mostra a ordem real das mensagens
use threads;
use threads::shared;

# --- 1) Variável comum: cada thread altera a SUA cópia ---------------
my $normal = 0;
threads->create(sub { $normal = 100; print "dentro da thread: normal=$normal\n" })->join;
print "fora da thread:   normal=$normal   (não mudou!)\n\n";

# --- 2) Variável :shared: todas as threads enxergam a mesma ----------
my $compartilhada :shared = 0;
threads->create(sub { $compartilhada = 100 })->join;
print "shared depois da thread = $compartilhada   (mudou!)\n\n";

# --- 3) Arrays e hashes compartilhados -------------------------------
my @lista :shared;
my %placar :shared;
my @ts = map {
    my $id = $_;
    threads->create(sub {
        lock(@lista);                 # trava antes de mexer (ver parte 3)
        push @lista, "item-$id";
        $placar{"t$id"} = $id * 10;
    });
} 1 .. 4;
$_->join for @ts;
print "lista  = @{[ sort @lista ]}\n";
print "placar = ", join(', ', map {"$_=$placar{$_}"} sort keys %placar), "\n\n";

# --- 4) Estruturas aninhadas: usar shared_clone ----------------------
# Referência comum NÃO pode ser guardada em variável shared;
# shared_clone faz uma cópia profunda já compartilhada.
my %config :shared;
$config{usuario} = shared_clone({ nome => 'ana', papeis => ['admin', 'dev'] });
threads->create(sub { push @{ $config{usuario}{papeis} }, 'ops' })->join;
print "papeis = @{ $config{usuario}{papeis} }\n";

# is_shared retorna o endereço interno se a variável é compartilhada
printf "is_shared(\$normal)=%s  is_shared(\$compartilhada)=%s\n",
    (is_shared($normal) ? 'sim' : 'não'), (is_shared($compartilhada) ? 'sim' : 'não');
