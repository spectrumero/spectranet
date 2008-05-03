# Makefile to build the Spectranet C library.

ASSEMBLER = z80asm
LIBNAME = libsocket
ASMFLAGS = -d -ns -nm -Mo -x$(LIBNAME)
ASMFILES = libsocket.lst
RM = rm -f

all:	$(ASMFILES)
	$(ASSEMBLER) $(ASMFLAGS) @$(ASMFILES)

clean:
	$(RM) $(LIBNAME).lib *.o

