CC = zcc
CFLAGS = +zx -vn -I../common -DNOSTDINT 
OBJS = init.o sprites.o rxtx.o viewport.o getinput.o
LIBS = -lmalloc -lsp1 -llibsocket -lndos
CTFCLIENT = ctfclient.bin

all:	ctfclient

ctfclient:	$(OBJS)
	$(CC) $(CFLAGS) -o $(CTFCLIENT) $(OBJS) $(LIBS)

clean:
	rm -f *.bin *.o

