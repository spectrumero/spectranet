CC = gcc
CFLAGS = -I../common -g
OBJS = ctfserv.o ctfsocket.o object.o clientmsg.o
LIBS =
CTFSERVER = ctfserver

all:	ctfserver

ctfserver:	$(OBJS)
	$(CC) -o $(CTFSERVER) $(CFLAGS) $(OBJS) $(LIBS)

clean:
	rm -f $(OBJS) $(CTFSERVER)

