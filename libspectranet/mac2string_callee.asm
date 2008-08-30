; CALLEE linkage for mac2string
; void mac2string_callee(char *mac, char *str);

XLIB mac2string_callee
XDEF ASMDISP_MAC2IPSTRING_CALLEE
	include "spectranet.asm"
.mac2string_callee
	pop bc		; return addr
	pop de		; char *str
	pop hl		; char *mac
	push bc		; resture ret addr
.asmentry
	ld ix, MAC2STRING_ROM
	call IXCALL
	ret

defc ASMDISP_MAC2STRING_CALLEE = asmentry - mac2string_callee

