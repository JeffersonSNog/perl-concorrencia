# Concorrência em Perl

Trabalho de Paradigmas de Programação (Parte 3).

Grupo: Jefferson Santana Nogueira, João Pedro Ferreira da Rocha e Lucas de Pinho Ribeiro dos Santos.

## Pastas

- `parte1-threads/`: criar threads, memória compartilhada e sincronização (lock, semáforo, cond_wait, fila)
- `parte2-modelos/`: corrotinas, event loop, promises, atores e fork

## Rodando

Precisa de um perl com suporte a threads. Para conferir:

```bash
perl -V:useithreads
```

A Parte 1 e os exemplos 02, 06 e 08 da Parte 2 rodam direto. Os outros usam módulos do CPAN:

```bash
cpanm --installdeps .
```

Exemplo:

```bash
perl parte1-threads/03_sincronizacao_lock.pl
```
