MAP2SYM = ../buildtools/map2sym

P1OBJS = ui_charset.o ui_keyscan.o ui_output.o ui_lookup.o
P1OUT = page1.bin
P1LDFLAGS = -T page1.ld -Map $(P1OUT).map

P2OBJS = utilromvectors.o utility_impl.o utilnmi.o save7ffd.o utilnmi_en.o
P2OUT = page2.bin
P2LDFLAGS = -T ../modules/modules.ld -Map $(P2OUT).map -L ../syslib
P2LIBS = -lromui

P3OBJS = tnfs_vectors.o tnfs_init.o tnfs_core.o tnfs_mount.o tnfs_file.o tnfs_directory.o inetinit.o dhcpclient.o dhcp_data.o basstart.o startmsg.o
P3OUT = page3.bin
P3LDFLAGS = -T ../modules/modules.ld -Map $(P3OUT).map

MODMANOBJS = romconfigmain.o romconfstrings_en.o
MODMANOUT = modman.bin
MODMANLDFLAGS = -T modman.ld -L ../syslib -Map $(MODMANOUT).map
MODMANLIBS = -lromui -lflashwrite

DATEFILE = date.xinc
VERFILE = ver.xinc
P3SYMS = page3.xinc
P2SYMS = page2.xinc
P1SYMS = page1.xinc

all:	page1 page2 page3 modman

page1:	$(P1OBJS)
	$(LD) -o $(P1OUT) $(P1OBJS) $(P1LDFLAGS) $(P1LIBS)

page2:	modman $(P2OBJS)
	$(LD) -o $(P2OUT) $(P2OBJS) $(P2LDFLAGS) $(P2LIBS)

page3:	date ver $(P3OBJS)
	$(LD) -o $(P3OUT) $(P3OBJS) $(P3LDFLAGS) $(P3LIBS)

modman:	$(MODMANOBJS)
	$(LD) -o $(MODMANOUT) $(MODMANOBJS) $(MODMANLDFLAGS) $(MODMANLIBS)

date:	$(DATEFILE)
$(DATEFILE):
	echo "blddate: defb \"`date`\",0x0a,0" > $(DATEFILE)

ver:	$(VERFILE)
$(VERFILE):
	echo "bldstr: defb \"gnubinutils\",0x0a,0" > $(VERFILE)

p1syms: page1 $(P1SYMS)
	$(MAP2SYM) $(P1OUT).map $(P1SYMS)

p2syms: page2 $(P2SYMS)
$(P2SYMS):
	$(MAP2SYM) $(P2OUT).map $(P2SYMS)

p3syms:	page3 $(P3SYMS)
$(P3SYMS):
	$(MAP2SYM) $(P3OUT).map $(P3SYMS)

include ../make.inc
