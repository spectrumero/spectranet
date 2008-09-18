; process
; void __FASTCALL__ ifconfig_gw(in_addr_t *addr);
XLIB ifconfig_gw
LIB libspectranet

	include "spectranet.asm"
.ifconfig_gw
	IXCALL IFCONFIG_GW_ROM
	ret

