AS = z80-unknown-coff-as
LD = z80-unknown-coff-ld
AR = z80-unknown-coff-ar
ARFLAGS = -cr
RANLIB = z80-unknown-coff-ranlib
ASFLAGS = -I../../include

OBJS = pager.o util.o
OUT = libmemutil.a

libmemutil:	$(OBJS)
	$(AR) $(ARFLAGS) $(OUT) $(OBJS)

clean:
	$(RM) -f *.o *.a

%.o : %.asm
	$(AS) $(ASFLAGS) $< -o $@


