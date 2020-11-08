OBJS = flashid.o
OUT = flashid.bin
LDFLAGS = -T flashid.ld
LIBS = 
MAPFILE = -Map $(OUT).map
ASFLAGS = -I../../include
AS = z80-unknown-coff-as
LD = z80-unknown-coff-ld

flashid:	$(OBJS)
	$(LD) -o $(OUT) $(OBJS) $(LDFLAGS) $(LIBS) $(MAPFILE)

clean:
	$(RM) -f *.o *.bin *.map

%.o : %.asm
	$(AS) $(ASFLAGS) $< -o $@

