# Makefile to build the Spectranet C library.

ASSEMBLER = z80asm
SRCGEN = ./makesources.pl
LIBNAME = libsocket
ASMFLAGS = -d -ns -nm -Mo 
PASMFILES = libsocket.lst
NPASMFILES = libsocket_np.lst
PLIBNAME = libsocket
NPLIBNAME = libsocket_np
RM = rm -f
CC = zcc
TESTOUT = testsocks.bin
CFLAGS = +zx -vn -I./include -O2 -preserve
COBJS = testsocks.o testclient.o nonmuxserver.o muxserver.o testudpserv.o
CLIBS = -lndos -llibsocket


plib:	$(PASMFILES)
	$(SRCGEN)
	$(ASSEMBLER) $(ASMFLAGS) -x$(PLIBNAME) @$(PASMFILES)

nplib:	$(NPASMFILES)
	$(SRCGEN)
	$(ASSEMBLER) $(ASMFLAGS) -x$(NPLIBNAME) @$(NPASMFILES)

test:	$(COBJS)
	$(CC) $(CFLAGS) -o $(TESTOUT) $(COBJS) $(CLIBS)

clean:
	$(RM) $(LIBNAME).lib *.o *_p.asm *_np.asm

