CC = zcc
FLAGS = +zx -vn -I../common -DNOSTDINT -m -pragma-define:CLIB_CONIO_NATIVE_COLOUR=1
OBJS = init.o sprites.o rxtx.o viewport.o getinput.o print.o gameover.o fade.o
DEPS = ctf.h ../common/ctfmessage.h
MMOBJS = mmfade.o mmdefaults.o mminit.o mmui.o mminput.o mmsocket.o 
MMDEPS = matchmake.h ../common/ctfmessage.h
LIBS = -lndos -lsp1 -llibsocket_np 
MMLIBS = -lndos -llibsocket
MMCFLAGS = +zx -vn -preserve -O2 -pragma-define:CLIB_CONIO_NATIVE_COLOUR=1
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

