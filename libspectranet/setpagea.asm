; void setpagea(unsigned char page);
XLIB setpagea
LIB libspectranet
	
	include "spectranet.asm"
.setpagea
	ld a, l
	ld hl, SETPAGEA_ROM
	call HLCALL
	ret
