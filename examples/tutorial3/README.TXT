Tutorial 3 code example - A simple TCP client.

There are two programs here - one in assembler (simpleclient.asm) and one in
C (simpleclient.c)

The assembly language program is tested with SJAsmPlus. Other assemblers
may need a different directive to include the spectranet.asm file.
To compile the C example, invoke the following:

zcc +zx -vn -O2 -o simpleclient.bin simpleclient.c -lndos -llibsocket

Tutorial 3 is available here:

http://spectrum.alioth.net/doc/index.php/Spectranet:_Tutorial_3

