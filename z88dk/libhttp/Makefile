# Makefile for the simple HTTP library.
LIBNAME = libhttp
COBJS = addFormData.o freeFormData.o parseURI.o parseproto.o \
	allocURI.o freeURI.o base64enc.o request.o readData.o \
	postsize.o getheader.o freeheaders.o readHeaders.o htrecv.o
CFLAGS = -I./include -O2 -preserve -vn -make-lib

all:	$(COBJS)
	$(LIBLINKER) $(LIBLDFLAGS) -x$(LIBNAME) $(COBJS)

include ../make.inc
