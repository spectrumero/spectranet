; process
; void __FASTCALL__ ifconfig_inet(in_addr_t *addr);
XLIB ifconfig_inet
LIB libspectranet

	include "spectranet.asm"
.ifconfig_inet
	IXCALL IFCONFIG_INET_ROM
	ret

