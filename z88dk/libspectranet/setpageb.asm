; void setpageb(unsigned char page);
XLIB setpageb
LIB libspectranet
	
	include "spectranet.asm"
.setpageb
	ld a, l
	call SETPAGEB_ROM
	ret
