; void setpagea(unsigned char page);
XLIB setpagea
LIB libspectranet
	
	include "spectranet.asm"
.setpagea
	ld a, l
	call SETPAGEA_ROM
	ret
