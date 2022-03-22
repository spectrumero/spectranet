# Makefile for the simple HTTP library.
LIBNAME = libhttp
COBJS = addFormData.o freeFormData.o parseURI.o parseproto.o \
	allocURI.o freeURI.o base64enc.o request.o readData.o \
	postsize.o getheader.o freeheaders.o readHeaders.o htrecv.o
CFLAGS = +zx -I./include -O2 -vn

all:	$(COBJS)
	$(LIBLINKER) $(LIBLDFLAGS) -x$(LIBNAME) $(COBJS)

install:
	$(CP) *.lib $(ZCCCFG)/../clibs
	$(CP) -r ./include $(ZCCCFG)/../../

include ../make.inc
