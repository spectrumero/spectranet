AS = z80-unknown-coff-as
LD = z80-unknown-coff-ld
RM = rm
ASFLAGS = -I../../include
LDFLAGS = -T ../modules.ld -Map msgrom.map
ASOBJS = getmsg.o messages_en.o vectors.o
OUT = msgrom.module

all:	$(ASOBJS)
	$(LD) -o $(OUT) $(ASOBJS) $(LDFLAGS)

%.o : %.asm
	$(AS) $(ASFLAGS) $< -o $@

clean:
	$(RM) -f $(ASOBJS) $(OUT)
