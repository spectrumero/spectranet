; void __FASTCALL__ ifconfig_gw(in_addr_t *addr);
XLIB ifconfig_gw
LIB libspectranet

	include "spectranet.asm"
.ifconfig_gw
	ld ix, IFCONFIG_GW_ROM
	call IXCALL
	ret

