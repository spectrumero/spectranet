; int accept_callee(int sockfd, struct sockaddr *addr, socklen_t *addrlen);

XLIB accept_callee
XDEF ASMDISP_ACCEPT_CALLEE
	include "spectranet.asm"
.accept_callee
	pop hl		; return addr
	pop bc		; addrlen
	pop de		; addr
	ex (sp), hl	; restore return address, fd now in l
	ld a, l
.asmentry
	ex af, af'	; save af
	ld a, d		; Is DE (struct sockaddr *addr) NULL?
	or e
	jr nz, accept_getdata
	ex af, af'	; retrieve socket fd
	ld hl, ACCEPT	; Just accept, no structure to fill.
	call HLCALL
	jr c, err
	ld h, 0		; success, return new socket
	ld l, a
	ret
.err
	ld hl, -1
	ret
.accept_getdata
	call PAGEIN	; spectranet pagein
	ex af, af'	; get sockfd back
	push de		; and the address of struct sockaddr *addr
	call ACCEPT	; accept the connection
	jr c, err2
	ld h, 0
	ld l, a		; new socket number
	pop de		; get addr pointer back
	push hl		; save return code
	call REMOTEADDRESS	; get the remote port/address into *addr
	call PAGEOUT	; spectranet pageout
	pop hl		; retrieve return code
	ret
.err2
	call PAGEOUT
	pop de		; fix the stack
	ld hl, -1
	ret

defc ASMDISP_ACCEPT_CALLEE = asmentry - accept_callee
