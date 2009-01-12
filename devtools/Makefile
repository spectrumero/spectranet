# devtools makefile
CC = gcc
ETHUPOBJS = ethup.o
ETHUPLIBS =
CFLAGS = -DUNIX
ETHUPOUT = ethup

ethup:	$(ETHUPOBJS)
	$(CC) $(CFLAGS) -o $(ETHUPOUT) $(ETHUPOBJS) $(ETHUPLIBS)
clean:
	$(RM) *.o $(ETHUPOUT)
