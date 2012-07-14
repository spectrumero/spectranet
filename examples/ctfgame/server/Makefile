CC = gcc
ifeq ($(OS), LINUX)
	FLAGS = -I../common -g -DUNIX -DNEED_BSDCOMPAT -DUSECURSES
	EXOBJS = strlcpy.o
	LIBS = -lm -lncurses
	CTFSERVER = ctfserver
endif
ifeq ($(OS), WIN32)
	FLAGS = -I../common -g -DWIN32 -DNEED_BSDCOMPAT
	EXOBJS = strlcpy.o
	LIBS = -lwsock32
	CTFSERVER = ctfserver.exe
endif
ifeq ($(OS), BSD)
	FLAGS = -I../common -g -DUNIX -DUSECURSES
	LIBS = -lncurses
	CTFSERVER = ctfserver
endif

ifeq ($(LANG), ES)
	EXFLAGS=-DLANG_ES
endif

CFLAGS = $(FLAGS) $(EXFLAGS)
OBJS = ctfserv.o ctfsocket.o object.o control.o map.o powerups.o bcastmsg.o matchmake.o endgame.o scoreboard.o $(EXOBJS)
DEPS = ctfserv.h ../common/ctfmessage.h

all:	ctfserver

ctfserver:	$(OBJS)
	$(CC) -o $(CTFSERVER) $(CFLAGS) $(OBJS) $(LIBS)

clean:
	rm -f $(OBJS) $(CTFSERVER)

$(OBJS):  $(DEPS)

