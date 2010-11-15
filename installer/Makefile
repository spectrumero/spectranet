INSOBJS	= installer.o base.o modules.o
INSOUT = installer.bin
INSLDFLAGS = -T installer.ld -L ../syslib
INSLIBS = -lpager -lromui

installer:	$(INSOBJS)
	$(LD) -o $(INSOUT) $(INSOBJS) $(INSLDFLAGS) $(INSLIBS)

include ../make.inc

