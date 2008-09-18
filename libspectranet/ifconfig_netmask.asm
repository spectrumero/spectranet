; process
; void __FASTCALL__ ifconfig_netmask(in_addr_t *addr);
XLIB ifconfig_netmask
LIB libspectranet

	include "spectranet.asm"
.ifconfig_netmask
	IXCALL IFCONFIG_NETMASK_ROM
	ret

