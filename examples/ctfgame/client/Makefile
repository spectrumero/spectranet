CC = zcc
CFLAGS = +zx -vn -I../common
OBJS = init.o sprites.o rxtx.o
LIBS = -lmalloc -lsp1 -llibsocket
CTFCLIENT = ctfclient.bin

all:	ctfclient

ctfclient:	$(OBJS)
	$(CC) $(CFLAGS) -o $(CTFCLIENT) $(OBJS) $(LIBS)

clean:
	rm -f *.bin *.o

