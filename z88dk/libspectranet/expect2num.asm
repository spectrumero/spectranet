; int expect2Num
XLIB expect2Num
LIB libspectranet

	include "zxromdefs.asm"
.expect2Num
	rst 16
	defw ZX_NEXT_2NUM
	ld h, 0
	ld l, a
	ret

