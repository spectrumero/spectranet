; int find_int1();
; Gets an 8 bit int
; note: call only when Spectranet memory is paged in.
XLIB find_int1
LIB libspectranet

	include "zxromdefs.asm"
.find_int1
	rst 16
	defw ZX_FIND_INT1
	ld h, 0
	ld l, a
	ret

