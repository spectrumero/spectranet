; unsigned char __FASTCALL__ pollfd(int sockfd);
XLIB poll_fd

	include "spectranet.asm"
.poll_fd
	ld a, l			; get fd
	ld hl, POLLFD_ROM	; pollfd function
	call HLCALL
	ld h, 0			; h should always be cleared
	jr c, err_pollfd
	ld l, c			; flags in C
	ret
.err_pollfd
	ld l, POLLNVAL		; error return code
	ret

