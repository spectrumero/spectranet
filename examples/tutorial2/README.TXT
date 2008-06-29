Tutorial 2 code example - A simple TCP server

There are two programs here - one in assembler (simpleserv.asm) and one in C
(simpleserv.c).

The assembly language program is tested with SJAsmPlus. Other assemblers
may need a different directive to include the spectranet.asm file.
To compile the C example, invoke the following:

zcc +zx -vn -O2 -o simpleserv.bin simpleserv.c -lndos -llibsocket

Tutorial 2 is available here:

http://spectrum.alioth.net/doc/index.php/Spectranet:_Tutorial_2

