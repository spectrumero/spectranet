CC=gcc
CFLAGS=-Wall -DUNIX -DNEED_ERRTABLE -DENABLE_CHROOT
OBJS=main.o datagram.o log.o session.o endian.o directory.o errortable.o tnfs_file.o strlcpy.o strlcat.o chroot.o
LIBS=
EXEC=tnfsd

all:	$(OBJS)
	$(CC) -o $(EXEC) $(OBJS) $(LIBS)

clean:
	$(RM) -f $(OBJS) $(EXEC)

