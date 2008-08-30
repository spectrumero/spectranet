; void setpageb(unsigned char page);
XLIB setpageb
LIB libspectranet
	
	include "spectranet.asm"
.setpagea
	ld a, l
	ld hl, SETPAGEB_ROM
	call HLCALL
	ret
