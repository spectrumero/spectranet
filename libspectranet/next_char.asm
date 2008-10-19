; next_char() - returns the next character on the BASIC line
XLIB next_char
LIB libspectranet

	include "zxromdefs.asm"
.next_char
	rst 16
	defw ZX_NEXT_CHAR
	ld h, 0
	ld l, a
	ret

