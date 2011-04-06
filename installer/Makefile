INSOBJS	= instmain.o installer.o base.o modules.o
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

INSCFGOBJS = cfginstmain.o getconfig.o installer.o base.o modules.o
INSCFGOUT = insconfig.bin
INSCFGMAP = -Map insconfig.bin.map
INSCFGTZX = insconfig.tzx
INSCFGTAP = insconfig.tap

BASEDEPS = page0.bin page1.bin page2.bin page3.bin jumptable.bin
MODDEPS = basext.module streams.module msgrom.module config.module snapman.module

INSTADDR = 27000
BIN2TAPE = ../utils/bin2tape

all:	installer base insconfig basetzx instzx basetap instap inscfgtzx inscfgtap

installer:	$(INSOBJS) 
	$(LD) -o $(INSOUT) $(INSOBJS) $(INSLDFLAGS) $(INSLIBS) $(INSMAP)

base:	$(BASEOBJS)
	$(LD) -o $(BASEOUT) $(BASEOBJS) $(INSLDFLAGS) $(INSLIBS) $(BASEMAP)

insconfig:	$(INSCFGOBJS)
	$(LD) -o $(INSCFGOUT) $(INSCFGOBJS) $(INSLDFLAGS) $(INSCFGMAP) $(INSLIBS)

tapefiles:	basetzx instzx basetap instap inscfgtzx inscfgtap

basetzx:	$(BASETZX)

basetap:	$(BASETAP)

instzx:	$(INSTZX)

instap:	$(INSTAP)

inscfgtzx:	$(INSCFGTZX)

inscfgtap:	$(INSCFGTAP)

$(BASETZX):	
	$(BIN2TAPE) tzx $(BASEOUT) $(BASETZX) $(INSTADDR)

$(INSTZX):
	$(BIN2TAPE) tzx $(INSOUT) $(INSTZX) $(INSTADDR)

$(BASETAP):	
	$(BIN2TAPE) tap $(BASEOUT) $(BASETAP) $(INSTADDR)

$(INSTAP):
	$(BIN2TAPE) tap $(INSOUT) $(INSTAP) $(INSTADDR)

$(INSCFGTZX):
	$(BIN2TAPE) tzx $(INSCFGOUT) $(INSCFGTZX) $(INSTADDR)

$(INSCFGTAP):
	$(BIN2TAPE) tap $(INSCFGOUT) $(INSCFGTAP) $(INSTADDR)

base.o:	$(BASEDEPS)

$(BASEDEPS):
	$(MAKE) -C ../rom

modules.o:	$(MODDEPS)

$(MODDEPS):
	$(MAKE) -C ../modules

include ../make.inc

