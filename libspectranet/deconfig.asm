; void deconfig();

XLIB deconfig
LIB libspectranet
	include "spectranet.asm"
.deconfig
	ld hl, DECONFIG_ROM
	call HLCALL
	ret

