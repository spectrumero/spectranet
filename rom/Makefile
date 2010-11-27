MAP2SYM = ../buildtools/map2sym

P0OBJS = zeropage.o reset.o trapdispatch.o w5100_ifconfig.o w5100_genintfunc.o w5100_buffer.o w5100_sockalloc.o w5100_sockctrl.o w5100_rxtx.o dns.o utility.o ui_input.o ui_output_stub.o progtrap.o basicextn.o pagealloc.o vfs.o w5100_sockinfo.o
P0OUT = page0.bin
P0LDFLAGS = -T page0.ld -Map $(P0OUT).map -L ../syslib
P0LIBS = -lpager

P1OBJS = ui_keyscan.o ui_funcs.o
P1OUT = page1.bin
P1LDFLAGS = -T page1.ld -Map $(P1OUT).map -L ../syslib
P1LIBS = -lromui

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

JPTABLEOBJS = jumptable.o
JPTABLEOUT = jumptable.bin
JPTABLELDFLAGS = -Ttext 0x0000 

DATEFILE = date.xinc
VERFILE = ver.xinc
P3SYMS = page3.xinc
P2SYMS = page2.xinc
P1SYMS = page1.xinc
P0SYMS = page0.xinc

INSTALLDIR = ../installer
CP = cp -f

all:	page0 page1 page2 page3 jptable

page0:	ver p1syms p2syms p3syms $(P0OBJS)
	$(LD) -o $(P0OUT) $(P0OBJS) $(P0LDFLAGS) $(P0LIBS)
	$(CP) $(P0OUT) $(INSTALLDIR)

page1:	$(P1OBJS)
	$(LD) -o $(P1OUT) $(P1OBJS) $(P1LDFLAGS) $(P1LIBS)
	$(CP) $(P1OUT) $(INSTALLDIR)

page2:	modman $(P2OBJS)
	$(LD) -o $(P2OUT) $(P2OBJS) $(P2LDFLAGS) $(P2LIBS)
	$(CP) $(P2OUT) $(INSTALLDIR)

page3:	date ver $(P3OBJS)
	$(LD) -o $(P3OUT) $(P3OBJS) $(P3LDFLAGS) $(P3LIBS)
	$(CP) $(P3OUT) $(INSTALLDIR)

modman:	$(MODMANOBJS)
	$(LD) -o $(MODMANOUT) $(MODMANOBJS) $(MODMANLDFLAGS) $(MODMANLIBS)

jptable:	p0syms $(JPTABLEOBJS)
	$(LD) -o $(JPTABLEOUT) $(JPTABLEOBJS) $(JPTABLELDFLAGS)
	$(CP) $(JPTABLEOUT) $(INSTALLDIR)

date:	$(DATEFILE)
$(DATEFILE):
	echo "blddate: defb \"`date`\",0x0a,0" > $(DATEFILE)

ver:	$(VERFILE)
$(VERFILE):
	echo "bldstr: defb \"`whoami`@`hostname` R`svn info .|grep -m 1 Rev|cut -d " " -f 2`\",0x0a,0" > $(VERFILE)

p0syms: page0 $(P0SYMS)
$(P0SYMS):
	$(MAP2SYM) $(P0OUT).map $(P0SYMS)

p1syms: page1 $(P1SYMS)
$(P1SYMS):
	$(MAP2SYM) $(P1OUT).map $(P1SYMS)

p2syms: page2 $(P2SYMS)
$(P2SYMS):
	$(MAP2SYM) $(P2OUT).map $(P2SYMS)

p3syms:	page3 $(P3SYMS)
$(P3SYMS):
	$(MAP2SYM) $(P3OUT).map $(P3SYMS)

include ../make.inc
