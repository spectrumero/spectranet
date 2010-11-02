AS = z80-unknown-coff-as
LD = z80-unknown-coff-ld
RM = rm
ASFLAGS = -I../../include
LDFLAGS = -T ../modules.ld --Map snapman.map
ASOBJS = directory.o inputloop.o loadsna.o memory.o savesna.o screen.o strings_en.o utils.o vectors.o
OUT = snapman.out

all:	$(ASOBJS)
	$(LD) -o $(OUT) $(ASOBJS) $(LDFLAGS)

%.o : %.asm
	$(AS) $(ASFLAGS) $< -o $@

clean:
	$(RM) -f $(ASOBJS) $(OUT)
