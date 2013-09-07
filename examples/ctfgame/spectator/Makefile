OBJS=main.o gfx.o map.o
PROG=spectate
LIBS=-lSDL -lSDL_gfx -lSDL_ttf
RM=rm

all:	$(OBJS)
	$(CC) -o $(PROG) $(OBJS) $(LIBS)

clean:	
	$(RM) -f $(PROG) $(OBJS)

