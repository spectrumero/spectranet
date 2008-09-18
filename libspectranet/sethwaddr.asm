; process
; int __FASTCALL__ sethwaddr(char *hwaddr);
XLIB sethwaddr
LIB libspectranet

	include "spectranet.asm"
.sethwaddr
	IXCALL SETHWADDR_ROM
	ld hl, 0	; rc=0
	ret nc
	dec hl		; rc=-1
	ret
	
