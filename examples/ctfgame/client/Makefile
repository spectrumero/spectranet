CC = zcc
CFLAGS = +zx -vn -I../common -DNOSTDINT -m -create-app
OBJS = init.o sprites.o rxtx.o viewport.o getinput.o
LIBS = -lmalloc -lsp1 -llibsocket 
CTFCLIENT = ctfclient.bin

all:	ctfclient

ctfclient:	$(OBJS)
	$(CC) $(CFLAGS) -o $(CTFCLIENT) $(OBJS) $(LIBS)

clean:
	rm -f *.bin *.o *.tap *.map *.def

