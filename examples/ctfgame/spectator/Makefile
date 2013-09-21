OBJS=main.o gfx.o map.o rxtx.o
PROG=spectate
LIBS=-lSDL -lSDL_gfx -lSDL_ttf
CFLAGS=-I../common -DUNIX -g
RM=rm

all:	$(OBJS)
	$(CC) -o $(PROG) $(OBJS) $(LIBS)

clean:	
	$(RM) -f $(PROG) $(OBJS)

