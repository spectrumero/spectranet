CC = zcc
FLAGS = +zx -vn -m 
OBJS = main.o sncontrol.o ram.o cpld.o flash.o
DEPS = 
LIBS = -lndos
EXE = sntester.bin

ifeq ($(LANG), ES)
	EXFLAGS=-DLANG_ES
endif

CFLAGS = $(FLAGS) $(EXFLAGS)

all:	tester

tester:	$(OBJS)
	$(CC) $(CFLAGS) -o $(EXE) $(OBJS) $(LIBS)

clean:
	rm -f *.bin *.o *.tap *.map *.def

$(OBJS):  $(DEPS)

