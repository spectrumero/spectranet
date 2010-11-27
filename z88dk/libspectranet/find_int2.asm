; int find_int2();
; note: call only when Spectranet memory is paged in.
XLIB find_int2
LIB libspectranet

	include "zxromdefs.asm"
.find_int2
	rst 16			; CALLBAS
	defw ZX_FIND_INT2	; get 16 bit integer
	ld h, b
	ld l, c
	ret

