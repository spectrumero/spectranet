; int listen_callee(int sockfd, int backlog);
; The Spectranet listen() implementation currently does not take a
; backlog parameter, but it must be provided for compatibility.

XLIB listen_callee
XDEF ASMDISP_LISTEN_CALLEE

.listen_callee
	pop hl		; return addr
	pop de		; int backlog
	ex (sp), hl	; swap socket/return address
	ld a, l		; socket in A
.asmentry
;	ld hl, LISTEN
;	call HLCALL
	ld hl, 0x3E06
	call 0x3FFA
	jr c, err
	ld hl, 0
	ret
.err
	ld hl, -1
	ret

defc ASMDISP_LISTEN_CALLEE = asmentry - listen_callee

