; int __CALLEE__ socket_callee(int domain, int type, int protocol);
; Open a socket.
; The Spectranet only supports domain AF_INET and IP.
XLIB socket_callee
XDEF ASMDISP_SOCKET_CALLEE

XREF SOCKET
XREF HLCALL

.socket_callee
	pop hl		; return addr
	pop de		; proto
	pop bc		; type
	ex (sp), hl	; restore the return address, hl = domain

.asmentry
;	ld hl, SOCKET	; jump table address
;	call HLCALL	; open the socket
	ld hl, 0x3E00
	call 0x3FFA
	
	ld h, 0
	ld l, a		; socket in hl
	ret

defc ASMDISP_SOCKET_CALLEE = asmentry - socket_callee

