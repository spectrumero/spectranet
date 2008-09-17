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
NPTESTOUT = testsocks_np.bin
CFLAGS = +zx -vn -I./include -O2 -preserve
COBJS = testsocks.o testclient.o nonmuxserver.o muxserver.o testudpserv.o
NPCOBJS = np_testsocks.o testclient.o nonmuxserver.o muxserver.o testudpserv.o
CLIBS = -lndos -llibsocket
NPCLIBS = -lndos -llibsocket_np


plib:	$(PASMFILES)
	$(SRCGEN)
	$(ASSEMBLER) $(ASMFLAGS) -x$(PLIBNAME) @$(PASMFILES)

nplib:	$(NPASMFILES)
	$(SRCGEN)
	$(ASSEMBLER) $(ASMFLAGS) -x$(NPLIBNAME) @$(NPASMFILES)

test:	$(COBJS)
	$(CC) $(CFLAGS) -o $(TESTOUT) $(COBJS) $(CLIBS)

nptest:	$(NPCOBJS)
	$(CC) $(CFLAGS) -o $(NPTESTOUT) $(NPCOBJS) $(NPCLIBS)

clean:
	$(RM) $(LIBNAME).lib *.o *_p.asm *_np.asm

