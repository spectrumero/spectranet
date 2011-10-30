CC = zcc
CFLAGS = +zx -vn -I../common -DNOSTDINT -m 
OBJS = init.o sprites.o rxtx.o viewport.o getinput.o print.o
LIBS = -lmalloc -lsp1 -llibsocket_np 
CTFCLIENT = ctfclient.bin

all:	ctfclient

ctfclient:	$(OBJS)
	$(CC) $(CFLAGS) -o $(CTFCLIENT) $(OBJS) $(LIBS)

clean:
	rm -f *.bin *.o *.tap *.map *.def

