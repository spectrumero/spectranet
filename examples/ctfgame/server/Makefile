CC = gcc
CFLAGS = -I../common
OBJS = ctfserv.o ctfsocket.o
LIBS =
CTFSERVER = ctfserver

all:	ctfserver

ctfserver:	$(OBJS)
	$(CC) -o $(CTFSERVER) $(CFLAGS) $(OBJS) $(LIBS)

clean:
	rm -f $(OBJS) $(CTFSERVER)

