INSOBJS	= installer.o base.o modules.o
INSOUT = installer.bin
INSLDFLAGS = -T installer.ld -L ../syslib 
INSLIBS = -lpager -lromui -lflashwrite
INSMAP = -Map installer.bin.map
INSTZX = installer.tzx
INSTAP = installer.tap

BASEOBJS = baseinst.o base.o
BASEOUT = baseinst.bin
BASEMAP = -Map baseinst.bin.map
BASETZX = baseinst.tzx
BASETAP = baseinst.tap

BASEDEPS = page0.bin page1.bin page2.bin page3.bin jumptable.bin
MODDEPS = basext.module streams.module msgrom.module config.module snapman.module

INSTADDR = 27000
BIN2TAPE = ../utils/bin2tape

all:	installer base basetzx instzx basetap instap

installer:	$(INSOBJS) 
	$(LD) -o $(INSOUT) $(INSOBJS) $(INSLDFLAGS) $(INSLIBS) $(INSMAP)

base:	$(BASEOBJS)
	$(LD) -o $(BASEOUT) $(BASEOBJS) $(INSLDFLAGS) $(INSLIBS) $(BASEMAP)

tapefiles:	basetzx instzx basetap instap

basetzx:	$(BASETZX)

basetap:	$(BASETAP)

instzx:	$(INSTZX)

instap:	$(INSTAP)

$(BASETZX):	
	$(BIN2TAPE) tzx $(BASEOUT) $(BASETZX) $(INSTADDR)

$(INSTZX):
	$(BIN2TAPE) tzx $(INSOUT) $(INSTZX) $(INSTADDR)

$(BASETAP):	
	$(BIN2TAPE) tap $(BASEOUT) $(BASETAP) $(INSTADDR)

$(INSTAP):
	$(BIN2TAPE) tap $(INSOUT) $(INSTAP) $(INSTADDR)

base.o:	$(BASEDEPS)

$(BASEDEPS):
	$(MAKE) -C ../rom

modules.o:	$(MODDEPS)

$(MODDEPS):
	$(MAKE) -C ../modules

include ../make.inc

