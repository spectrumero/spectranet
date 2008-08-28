# Makefile to build the Spectranet C library.

ASSEMBLER = z80asm
LIBNAME = libspectranet
ASMFLAGS = -d -ns -nm -Mo -x$(LIBNAME)
ASMFILES = libspectranet.lst
RM = rm -f
CC = zcc
TESTOUT = testlibsn.bin
CFLAGS = +zx -vn -I./include -O2 -preserve
COBJS = testlibsn.o
CLIBS = -lndos -llibspectranet


all:	$(ASMFILES)
	$(ASSEMBLER) $(ASMFLAGS) @$(ASMFILES)

test:	$(COBJS)
	$(CC) $(CFLAGS) -o $(TESTOUT) $(COBJS) $(CLIBS)

clean:
	$(RM) $(LIBNAME).lib *.o

