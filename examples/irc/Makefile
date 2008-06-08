# Makefile for 'irc' example
CC = zcc
RM = rm -f
OUT = irc.bin
CFLAGS = +zx -vn -O2 -preserve
OBJS = irc.o inputline.o statusline.o output.o ircsvrmsg.o
LIBS = -lndos -llibsocket -lim2

all:	$(OBJS)
	$(CC) $(CFLAGS) -o $(OUT) $(OBJS) $(LIBS)

clean:
	$(RM) $(OUT) *.o

