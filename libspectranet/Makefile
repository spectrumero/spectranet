# Makefile to build the Spectranet C library.

ASSEMBLER = z80asm
SRCGEN = ./makesources.pl
PLIBNAME = libspectranet
NPLIBNAME = libspectranet_np
ASMFLAGS = -d -ns -nm -Mo
PASMFILES = libspectranet.lst
NPASMFILES = libspectranet_np.lst
RM = rm -f
CC = zcc
TESTOUT = testlibsn.bin
BASOUT = testbas.bin
CFLAGS = +zx -vn -I./include -O2 -preserve
COBJS = testlibsn.o
BASOBJS = testbasext.o
CLIBS = -lndos -llibspectranet


plib:	$(PASMFILES)
	$(SRCGEN)
	$(ASSEMBLER) $(ASMFLAGS) -x$(PLIBNAME) @$(PASMFILES)

nplib:	$(NPASMFILES)
	$(SRCGEN)
	$(ASSEMBLER) $(ASMFLAGS) -x$(NPLIBNAME) @$(NPASMFILES)

test:	$(COBJS)
	$(CC) $(CFLAGS) -o $(TESTOUT) $(COBJS) $(CLIBS)

basext:	$(BASOBJS)
	$(CC) $(CFLAGS) -o $(BASOUT) $(BASOBJS) $(CLIBS)

clean:
	$(RM) $(LIBNAME).lib *.o *_p.asm *_np.asm

