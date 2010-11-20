AS = z80-unknown-coff-as
LD = z80-unknown-coff-ld
AR = z80-unknown-coff-ar
ARFLAGS = -cr
RANLIB = z80-unknown-coff-ranlib
ASFLAGS = -I../include

UIOBJS = ui_menu.o ui_output.o ui_charset.o ui_lookup.o
UIOUT  = libromui.a

FWOBJS = pager.o flashwrite.o 
FWOUT = libflashwrite.a

PGROBJS = pager.o dispatcher.o
PGROUT = libpager.a

DBGOBJS = debug.o
DBGOUT = libdebug.a

all:	libui libflashwrite libpager libdebug

libui:	$(UIOBJS)
	$(AR) $(ARFLAGS) $(UIOUT) $(UIOBJS)
	$(RANLIB) $(UIOUT)

libflashwrite:	$(FWOBJS)
	$(AR) $(ARFLAGS) $(FWOUT) $(FWOBJS)
	$(RANLIB) $(FWOUT)

libpager:	$(PGROBJS)
	$(AR) $(ARFLAGS) $(PGROUT) $(PGROBJS)
	$(RANLIB) $(PGROUT)

libdebug:	$(DBGOBJS)
	$(AR) $(ARFLAGS) $(DBGOUT) $(DBGOBJS)
	$(RANLIB) $(DBGOUT)

%.o : %.asm
	$(AS) $(ASFLAGS) $< -o $@

clean:
	$(RM) -f *.o *.a

