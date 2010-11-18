AS = z80-unknown-coff-as
LD = z80-unknown-coff-ld
RM = rm
ASFLAGS = -I../include
MAPFILE = $(OUT).map

.PHONY: clean

%.o : %.asm
	$(AS) $(ASFLAGS) $< -o $@

clean:
	$(RM) -f *.o *.module *.bin *.map *.xinc *.tzx

