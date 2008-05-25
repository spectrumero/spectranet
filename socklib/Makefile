# Makefile to build the Spectranet C library.

ASSEMBLER = z80asm
LIBNAME = libsocket
ASMFLAGS = -d -ns -nm -Mo -x$(LIBNAME)
ASMFILES = libsocket.lst
RM = rm -f
CC = zcc
TESTOUT = testsocks.bin
CFLAGS = +zx -vn -I./include -O2 -preserve
COBJS = testsocks.o testclient.o nonmuxserver.o muxserver.o testudpserv.o
CLIBS = -lndos -llibsocket


all:	$(ASMFILES)
	$(ASSEMBLER) $(ASMFLAGS) @$(ASMFILES)

test:	$(COBJS)
	$(CC) $(CFLAGS) -o $(TESTOUT) $(COBJS) $(CLIBS)

clean:
	$(RM) $(LIBNAME).lib *.o

