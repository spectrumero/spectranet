# Makefile for 'irc' example
CC = zcc
RM = rm -f
OUT = irc.bin
CFLAGS = +zx -vn -O2 -preserve
OBJS = irc.o inputline.o statusline.o output.o
LIBS = -lndos -llibsocket

all:	$(OBJS)
	$(CC) $(CFLAGS) -o $(OUT) $(OBJS) $(LIBS)

clean:
	$(RM) $(OUT) *.o

