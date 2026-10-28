# Dependências da Parte 2 (a Parte 1 usa só módulos core do Perl)
# Instalar com:  cpanm --installdeps .
requires 'Coro';          # corrotinas (XS, precisa de compilador C)
requires 'AnyEvent';      # event loop
requires 'Mojolicious';   # Mojo::IOLoop + Mojo::Promise
requires 'Future';        # futures / promises
requires 'POE';           # sessões no estilo ator
