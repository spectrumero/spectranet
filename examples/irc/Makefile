# Makefile for 'irc' example
CC = zcc
RM = rm -f
OUT = irc.bin
CFLAGS = +zx -vn -O2 -pragma-define:CLIB_CONIO_NATIVE_COLOUR=1
OBJS = irc.o inputline.o statusline.o output.o ircsvrmsg.o usercmd.o 
LIBS = -lndos -llibsocket

all:	$(OBJS)
	$(CC) $(CFLAGS) -o $(OUT) $(OBJS) $(LIBS)

clean:
	$(RM) $(OUT) *.o

