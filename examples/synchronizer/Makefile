OBJS = socket.o receiver.o transmitter.o
EXEC = udpsync.bin
LDFLAGS = -T udpsync.ld -Map $(EXEC).map

all:	$(OBJS)
	$(LD) -o $(EXEC) $(OBJS) $(LDFLAGS) $(LIBS)

include ../make.inc
