AS = z80-unknown-coff-as
LD = z80-unknown-coff-ld
RM = rm
ASFLAGS = -I../../include
LDFLAGS = -Ttext 0x2000
ASOBJS = vectors.o directory.o inputloop.o loadsna.o memory.o savesna.o screen.o strings_en.o utils.o
OUT = snapman.out

all:	$(ASOBJS)
	$(LD) -o $(OUT) $(ASOBJS) $(LDFLAGS)

%.o : %.asm
	$(AS) $(ASFLAGS) $< -o $@

clean:
	$(RM) -f $(ASOBJS) $(OUT)
