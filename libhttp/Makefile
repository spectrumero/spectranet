# Makefile for the simple HTTP library.
CC = zcc
LIBNAME = libhttp
RM = rm -f
LIBLINKER = z80asm
ASSEMBLER = z80asm
COBJS = addFormData.o freeFormData.o parseURI.o parseproto.o \
	allocURI.o freeURI.o base64enc.o request.o readData.o \
	postsize.o getheader.o freeheaders.o readHeaders.o htrecv.o
CFLAGS = -I./include -O2 -preserve -vn -make-lib

all:	$(COBJS)
	$(LIBLINKER) -d -ns -nm -Mo -x$(LIBNAME) $(COBJS)

clean:	
	$(RM) $(COBJS) $(TESTOBJS) $(TESTOUT) $(LIBNAME)

