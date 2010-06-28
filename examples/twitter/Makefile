# Makefile for the simple HTTP library.
CC = zcc
RM = rm -f
COBJS = tweetmain.o tweetscr.o tweetinput.o ui.o tweethttp.o
CLIBS = -llibhttp -lndos -lmalloc -llibsocket -lim2 
COUT = twitter.bin
CFLAGS = +zx -vn -O2 -preserve -no-cleanup

all:	$(COBJS)
	$(CC) $(CFLAGS) -o $(COUT) $(COBJS) $(CLIBS)

clean:	
	$(RM) $(COBJS) $(COUT)

