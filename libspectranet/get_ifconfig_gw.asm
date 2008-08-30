; void __FASTCALL__ get_ifconfig_gw(in_addr_t *addr);
XLIB get_ifconfig_gw
LIB libspectranet

	include "spectranet.asm"
.get_ifconfig_gw
	ex de, hl
	ld hl, GET_IFCONFIG_GW_ROM
	call HLCALL
	ret

