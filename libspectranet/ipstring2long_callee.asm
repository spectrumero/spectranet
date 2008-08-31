; CALLEE linkage for ipstring2long
; int ipstring2long_callee(char *str, in_addr_t *addr);

XLIB ipstring2long_callee
XDEF ASMDISP_IPSTRING2LONG_CALLEE

	include "spectranet.asm"
.ipstring2long_callee
	pop bc		; ret addr
	pop de		; in_addr_t *addr
	pop hl		; char *str
	push bc		; restore ret addr
.asmentry
	ld ix, IPSTRING2LONG_ROM
	call IXCALL
	ld hl, 0
	ret nc
	dec hl		; return -1 for an error
	ret

defc ASMDISP_IPSTRING2LONG_CALLEE = asmentry - ipstring2long_callee

