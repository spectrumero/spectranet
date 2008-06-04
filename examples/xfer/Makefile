# Makefile for 'xfer' example
CC = zcc
RM = rm -f
OUT = xfer.bin
CFLAGS = +zx -vn -O2 -preserve
OBJS = xfer.o
LIBS = -lndos -llibsocket

all:	$(OBJS)
	$(CC) $(CFLAGS) -o $(OUT) $(OBJS) $(LIBS)

clean:
	$(RM) $(OUT) *.o

