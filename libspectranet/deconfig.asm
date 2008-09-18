; process
; void deconfig();

XLIB deconfig
LIB libspectranet
	include "spectranet.asm"
.deconfig
	HLCALL DECONFIG_ROM
	ret

