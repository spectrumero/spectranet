OBJS = flashid.o
OUT = flashid.bin
LDFLAGS = -T flashid.ld
LIBS = 
MAPFILE = -Map $(OUT).map
ASFLAGS = -I../../include
AS = z80-unknown-coff-as
LD = z80-unknown-coff-ld
BIN2TAPE = ../../utils/bin2tape
TAP = $(OUT).tap

all:	flashid tape

flashid:	$(OBJS)
	$(LD) -o $(OUT) $(OBJS) $(LDFLAGS) $(LIBS) $(MAPFILE)

tape:	flashid $(TAP)

$(TAP):
	$(BIN2TAPE) tap $(OUT) $(TAP)

clean:
	$(RM) -f *.o *.bin *.map *.tap

%.o : %.asm
	$(AS) $(ASFLAGS) $< -o $@

