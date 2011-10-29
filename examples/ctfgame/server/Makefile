CC = gcc
CFLAGS = -I../common -g -DUNIX
OBJS = ctfserv.o ctfsocket.o object.o control.o map.o powerups.o
LIBS =
CTFSERVER = ctfserver

all:	ctfserver

ctfserver:	$(OBJS)
	$(CC) -o $(CTFSERVER) $(CFLAGS) $(OBJS) $(LIBS)

clean:
	rm -f $(OBJS) $(CTFSERVER)

