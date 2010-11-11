P3OBJS = tnfs_vectors.o tnfs_init.o tnfs_core.o tnfs_mount.o tnfs_file.o tnfs_directory.o inetinit.o dhcpclient.o dhcp_data.o basstart.o startmsg.o
P3OUT = page3.bin
P3LDFLAGS = -T ../modules/modules.ld
DATEFILE = date.xinc
VERFILE = ver.xinc

all:	page3

page3:	date ver $(P3OBJS)
	$(LD) -o $(P3OUT) $(P3OBJS) $(P3LDFLAGS)

date:	$(DATEFILE)
$(DATEFILE):
	echo "blddate: defb \"`date`\",0x0a,0" > $(DATEFILE)

ver:	$(VERFILE)
$(VERFILE):
	echo "bldstr: defb \"gnubinutils\",0x0a,0" > $(VERFILE)

include ../make.inc
