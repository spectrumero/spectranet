# make.inc file for z88dk libraries
CC = zcc
LIBLINKER = z80asm
ASSEMBLER = z80asm
RM = rm -f
LIBLDFLAGS = -d -ns -nm -Mo
ASMFLAGS = -d -ns -nm -Mo

.PHONY:	clean

clean:
	$(RM) *.o *.lib *.def *_p.asm *_np.asm

