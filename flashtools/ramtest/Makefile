OBJS = ramtest.o
OUT = ramtest.bin
LDFLAGS = -T ramtest.ld -L ../lib
LIBS = -lmemutil
MAPFILE = -Map $(OUT).map
ASFLAGS = -I../../include
AS = z80-unknown-coff-as
LD = z80-unknown-coff-ld
BIN2TAPE = ../../utils/bin2tape
TAP = $(OUT).tap

all:	ramtest tape

ramtest:	$(OBJS)
	$(LD) -o $(OUT) $(OBJS) $(LDFLAGS) $(LIBS) $(MAPFILE)

tape:	ramtest $(TAP)

$(TAP):
	$(BIN2TAPE) tap $(OUT) $(TAP)

clean:
	$(RM) -f *.o *.bin *.map *.tap

%.o : %.asm
	$(AS) $(ASFLAGS) $< -o $@

