# Makefile to build the Spectranet VFS DOS library (libspdos)
# Expects Spectranet to be paged in

LIBNAME = libspdos
COBJS = open.o close.o read.o write.o readbyte.o writebyte.o lseek.o \
	mkdir.o rmdir.o chdir.o getcwd.o \
	rename.o remove.o unlink.o \
	opendir.o readdir.o closedir.o \
	mount.o umount.o stat.o
CFLAGS = +zx -vn -I./include -I/usr/local/z88dk/share/z88dk/include -O2

# Pattern rule to compile .c to .o
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

all:	$(COBJS)
	$(LIBLINKER) $(LIBLDFLAGS) -x$(LIBNAME) $(COBJS)

$(LIBNAME).lib: $(COBJS)
	$(LIBLINKER) $(LIBLDFLAGS) -x$(LIBNAME) $(COBJS)

install: $(LIBNAME).lib
	$(CP) *.lib $(ZCCCFG)/../clibs
	$(CP) -r ./include $(ZCCCFG)/../../

include ../make.inc

