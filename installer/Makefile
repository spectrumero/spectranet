INSOBJS	= installer.o base.o modules.o
INSOUT = installer.bin
INSLDFLAGS = -T installer.ld -L ../syslib 
INSLIBS = -lpager -lromui -lflashwrite
INSMAP = -Map installer.bin.map
INSTZX = installer.tzx

BASEOBJS = baseinst.o base.o
BASEOUT = baseinst.bin
BASEMAP = -Map baseinst.bin.map
BASETZX = baseinst.tzx

INSTADDR = 27000
BIN2TZX = ../utils/bin2tzx

all:	installer base basetzx instzx

installer:	$(INSOBJS)
	$(LD) -o $(INSOUT) $(INSOBJS) $(INSLDFLAGS) $(INSLIBS) $(INSMAP)

base:	$(BASEOBJS)
	$(LD) -o $(BASEOUT) $(BASEOBJS) $(INSLDFLAGS) $(INSLIBS) $(BASEMAP)

tzxfiles:	basetzx installtzx

basetzx:	$(BASETZX)

instzx:	$(INSTZX)

$(BASETZX):	
	$(BIN2TZX) $(BASEOUT) $(BASETZX) $(INSTADDR)

$(INSTZX):
	$(BIN2TZX) $(INSOUT) $(INSTZX) $(INSTADDR)

include ../make.inc

