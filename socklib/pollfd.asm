; unsigned char __FASTCALL__ pollfd(int sockfd);
XLIB pollfd

	include "spectranet.asm"
.pollfd
	ld a, l		; get fd
	ld hl, POLLFD	; pollfd function
	call HLCALL
	ld h, 0		; h should always be cleared
	jr c, err_pollfd
	ld l, c		; flags in C
	ret
.err_pollfd
	ld l, POLLNVAL	; error return code
	ret

