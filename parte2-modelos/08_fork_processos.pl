#!/usr/bin/env perl
# Parte 2.8 - Outra forma: processos com fork() + pipe + waitpid
#
# Historicamente é a forma MAIS usada de concorrência em Perl (Unix).
# fork() duplica o processo inteiro (copy-on-write); pai e filho têm
# memórias separadas e se comunicam via pipe, socket, arquivo etc.
# Vantagens: paralelismo real em vários núcleos, isolamento total.
# Módulos que facilitam: Parallel::ForkManager, MCE, IO::Async::Function.
use strict;
use warnings;
$| = 1;   # sem buffer no STDOUT: mostra a ordem real das mensagens
use POSIX ':sys_wait_h';

my @numeros = (10, 20, 30, 40);
my %filhos;   # pid => leitor do pipe

for my $n (@numeros) {
    pipe(my $leitor, my $escritor) or die "pipe: $!";
    my $pid = fork() // die "fork: $!";
    if ($pid == 0) {                       # ---- processo FILHO ----
        close $leitor;
        my $soma = 0; $soma += $_ for 1 .. $n * 100_000;   # trabalho de CPU
        print {$escritor} "$$ somou 1..", $n * 100_000, " = $soma\n";
        close $escritor;
        exit 0;
    }
    close $escritor;                       # ---- processo PAI ----
    $filhos{$pid} = $leitor;
}

# Coleta resultados e espera cada filho (evita processos zumbis)
for my $pid (keys %filhos) {
    my $fh = $filhos{$pid};
    print "pai recebeu de $pid: ", scalar <$fh>;
    waitpid($pid, 0);
    print "  filho $pid saiu com status ", $? >> 8, "\n";
}

# Memória NÃO é compartilhada: o filho muda $x e o pai não vê
my $x = 1;
my $pid = fork();
if ($pid == 0) { $x = 999; exit 0 }
waitpid($pid, 0);
print "no pai, \$x continua $x\n";
