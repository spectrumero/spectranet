; int expectStringExp()
XLIB expectStringExp
LIB libspectranet

	include "zxromdefs.asm"
.expectStringExp
	rst 16
	defw ZX_EXPT_EXP
	ld h, 0
	ld l, a
	ret

