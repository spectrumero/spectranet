; void exit_success()
XLIB exit_success
LIB libspectranet

	include "spectranet.asm"
.exit_success
	pop hl		; unwind return address from the stack
	jp EXIT_SUCCESS

