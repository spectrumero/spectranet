; process
; int __CALLEE__ socket_callee(int domain, int type, int protocol);
; Open a socket.
; The Spectranet only supports domain AF_INET and IP.
XLIB socket_callee
XDEF ASMDISP_SOCKET_CALLEE

	include "spectranet.asm"

.socket_callee
	pop hl		; return addr
	pop de		; proto
	pop bc		; type
	ex (sp), hl	; restore the return address, hl = domain

.asmentry
	HLCALL SOCKET
	
	ld h, 0
	ld l, a		; socket in hl
	ret

defc ASMDISP_SOCKET_CALLEE = asmentry - socket_callee

