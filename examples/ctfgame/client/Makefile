CC = zcc
CFLAGS = +zx -vn -I../common -DNOSTDINT -m 
OBJS = init.o sprites.o rxtx.o viewport.o getinput.o print.o
MMOBJS = mminit.o mmui.o mminput.o mmsocket.o
LIBS = -lmalloc -lsp1 -llibsocket_np 
MMLIBS = -lndos -lmalloc -lim2 -llibsocket
MMCFLAGS = +zx -vn -O2 -preserve 
CTFCLIENT = ctfclient.bin
MATCHMK	= matchmake.bin

all:	ctfclient matchmake

ctfclient:	$(OBJS)
	$(CC) $(CFLAGS) -o $(CTFCLIENT) $(OBJS) $(LIBS)

matchmake:	$(MMOBJS)
	$(CC)	$(MMCFLAGS) -o $(MATCHMK) $(MMOBJS) $(MMLIBS)

clean:
	rm -f *.bin *.o *.tap *.map *.def

