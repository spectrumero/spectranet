; CALLER linkage for listen()
XLIB listen
LIB listen_callee
XREF ASMDISP_LISTEN_CALLEE

; int listen(int sockfd, int backlog);
.listen
	pop hl		; return address
	pop de		; backlog
	pop af		; sockfd
	push af
	push de
	push hl
	jp listen_callee + ASMDISP_LISTEN_CALLEE

