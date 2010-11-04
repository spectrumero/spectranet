AS = z80-unknown-coff-as
LD = z80-unknown-coff-ld
RM = rm
ASFLAGS = -I../../include
MAPFILE = $(OUT).map
LDFLAGS = -T ../modules.ld -Map $(MAPFILE)

module:	$(ASOBJS)
	$(LD) -o $(OUT) $(ASOBJS) $(LDFLAGS) $(LIBPATH) $(LIBS)

%.o : %.asm
	$(AS) $(ASFLAGS) $< -o $@

clean:
	$(RM) -f *.o *.module *.bin *.map

