; process
; void __FASTCALL__ gethwaddr(char *hwaddr); /* hwaddr points to 6 byte buf */
XLIB gethwaddr
LIB libspectranet

	include "spectranet.asm"
.gethwaddr
	ex de, hl
	HLCALL GETHWADDR_ROM
	ret

