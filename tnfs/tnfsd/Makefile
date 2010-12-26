CC=gcc
CFLAGS=-Wall -DDEBUG -DUNIX -DNEED_ERRTABLE -DWITH_ZIP
OBJS=main.o datagram.o log.o session.o endian.o directory.o errortable.o tnfs_file.o strlcpy.o strlcat.o
LIBS=
EXEC=tnfsd

all:	$(OBJS)
	$(CC) -o $(EXEC) $(OBJS) $(LIBS)

clean:
	$(RM) -f $(OBJS) $(EXEC)

