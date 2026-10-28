#!/usr/bin/env perl
# Processos com fork, pipe e waitpid
use strict;
use warnings;
$| = 1;
use POSIX ':sys_wait_h';

my @numeros = (10, 20, 30, 40);
my %filhos;

for my $n (@numeros) {
    pipe(my $leitor, my $escritor) or die "pipe: $!";
    my $pid = fork() // die "fork: $!";
    if ($pid == 0) {
        # filho
        close $leitor;
        my $soma = 0; $soma += $_ for 1 .. $n * 100_000;
        print {$escritor} "$$ somou 1..", $n * 100_000, " = $soma\n";
        close $escritor;
        exit 0;
    }
    # pai
    close $escritor;
    $filhos{$pid} = $leitor;
}

for my $pid (keys %filhos) {
    my $fh = $filhos{$pid};
    print "pai recebeu de $pid: ", scalar <$fh>;
    waitpid($pid, 0);
    print "  filho $pid saiu com status ", $? >> 8, "\n";
}

# o filho não altera a memória do pai
my $x = 1;
my $pid = fork();
if ($pid == 0) { $x = 999; exit 0 }
waitpid($pid, 0);
print "no pai, \$x continua $x\n";
