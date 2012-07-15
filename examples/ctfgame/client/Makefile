CC = zcc
FLAGS = +zx -vn -I../common -DNOSTDINT -m 
OBJS = init.o sprites.o rxtx.o viewport.o getinput.o print.o gameover.o fade.o
DEPS = ctf.h ../common/ctfmessage.h
MMOBJS = mmdefaults.o mminit.o mmui.o mminput.o mmsocket.o
MMDEPS = matchmake.h ../common/ctfmessage.h
LIBS = -lmalloc -lsp1 -llibsocket_np 
MMLIBS = -lndos -lmalloc -lim2 -llibsocket
MMCFLAGS = +zx -vn -preserve -O2
CTFCLIENT = ctfclient.bin
MATCHMK	= matchmake.bin

ifeq ($(LANG), ES)
	EXFLAGS=-DLANG_ES
endif

CFLAGS = $(FLAGS) $(EXFLAGS)

all:	ctfclient matchmake

ctfclient:	$(OBJS)
	$(CC) $(CFLAGS) -o $(CTFCLIENT) $(OBJS) $(LIBS)

matchmake:	$(MMOBJS)
	$(CC)	$(MMCFLAGS) -o $(MATCHMK) $(MMOBJS) $(MMLIBS)

clean:
	rm -f *.bin *.o *.tap *.map *.def

$(OBJS):  $(DEPS)

$(MMOBJS):  $(MMDEPS)

