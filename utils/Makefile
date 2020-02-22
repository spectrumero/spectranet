CC = gcc
CFLAGS = -Wall
B2TOBJS = bin2tape.o
B2TOUT = bin2tape
CFSERVOBJS = configserv.o
CFSERVOUT = configserv
RM = rm

ifeq ($(OS),Windows_NT)
B2TOUT = bin2tape.exe
CFSERVOUT = configserv.exe
LIBS = -lwsock32
else
B2TOUT = bin2tape
CFSERVOUT = configserv
LIBS = 
endif

all:	bin2tzx cfserv

bin2tzx:	$(B2TOBJS)
	$(CC) -o $(B2TOUT) $(B2TOBJS)

cfserv:		$(CFSERVOBJS)
	$(CC) -o $(CFSERVOUT) $(CFSERVOBJS) $(LIBS)

clean:
	$(RM) -f $(B2TOUT) $(B2TOBJS) $(CFSERVOUT) $(CFSERVOBJS)
