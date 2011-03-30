CC = gcc
CFLAGS = -Wall
B2TOBJS = bin2tape.o
B2TOUT = bin2tape
CFSERVOBJS = configserv.o
CFSERVOUT = configserv
RM = rm

all:	bin2tzx cfserv

bin2tzx:	$(B2TOBJS)
	$(CC) -o $(B2TOUT) $(B2TOBJS)

cfserv:		$(CFSERVOBJS)
	$(CC) -o $(CFSERVOUT) $(CFSERVOBJS)

clean:
	$(RM) -f $(B2TOUT) $(B2TOBJS) $(CFSERVOUT) $(CFSERVOBJS)
