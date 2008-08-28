; int __FASTCALL__ sethwaddr(char *hwaddr);
XLIB sethwaddr
LIB libspectranet

	include "spectranet.asm"
.sethwaddr
	ld ix, SETHWADDR_ROM
	call IXCALL
	ld hl, 0	; rc=0
	ret nc
	dec hl		; rc=-1
	ret
	
