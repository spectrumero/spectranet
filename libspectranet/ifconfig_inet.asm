; void __FASTCALL__ ifconfig_inet(in_addr_t *addr);
XLIB ifconfig_inet
LIB libspectranet

	include "spectranet.asm"
.ifconfig_inet
	ld ix, IFCONFIG_INET_ROM
	call IXCALL
	ret

