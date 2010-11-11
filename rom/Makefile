P1OBJS = ui_charset.o ui_keyscan.o ui_output.o ui_lookup.o
P1OUT = page1.bin
P1LDFLAGS = -T page1.ld

P2OBJS = utilromvectors.o utility_impl.o utilnmi.o save7ffd.o utilnmi_en.o
P2OUT = page2.bin
P2LDFLAGS = -T ../modules/modules.ld -Map $(OUT).map
P2LIBS = -lromui

P3OBJS = tnfs_vectors.o tnfs_init.o tnfs_core.o tnfs_mount.o tnfs_file.o tnfs_directory.o inetinit.o dhcpclient.o dhcp_data.o basstart.o startmsg.o
P3OUT = page3.bin
P3LDFLAGS = -T ../modules/modules.ld -Map $(OUT).map

MODMANOBJS = romconfigmain.o romconfstrings_en.o
MODMANOUT = modman.bin
MODMANLDFLAGS = -T modman.ld -L ../syslib -Map $(OUT).map
MODMANLIBS = -lromui -lflashwrite

DATEFILE = date.xinc
VERFILE = ver.xinc

all:	page3 modman

page3:	date ver $(P3OBJS)
	$(LD) -o $(P3OUT) $(P3OBJS) $(P3LDFLAGS)

modman:	$(MODMANOBJS)
	$(LD) -o $(MODMANOUT) $(MODMANOBJS) $(MODMANLDFLAGS) $(MODMANLIBS)

date:	$(DATEFILE)
$(DATEFILE):
	echo "blddate: defb \"`date`\",0x0a,0" > $(DATEFILE)

ver:	$(VERFILE)
$(VERFILE):
	echo "bldstr: defb \"gnubinutils\",0x0a,0" > $(VERFILE)

include ../make.inc
