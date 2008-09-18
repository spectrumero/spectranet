; process
; void __FASTCALL__ get_ifconfig_netmask(in_addr_t *addr);
XLIB get_ifconfig_netmask
LIB libspectranet

	include "spectranet.asm"
.get_ifconfig_netmask
	ex de, hl
	HLCALL GET_IFCONFIG_NETMASK_ROM
	ret

