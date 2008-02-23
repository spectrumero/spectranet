; ROM library test (that runs from RAM, of course). Load this with the
; loader invoked by *f at address 32768.
	include "../rom/w5100_defines.asm"

	org 0x8000
	di
	ld a, 1		; Page in Spectranet memory
	ld bc, 0x80EF	; pager port
	out (c), a

	; initialize socket file descriptors
	ld hl, v_fd1hwsock
	ld de, v_fd2hwsock
	ld a, 0xFF
	ld (hl), a
	ldi
	ldi
	ldi
	ldi

	; clear rxbuf
	xor a
	ld hl, BUF_rxbuf
	ld (hl), a
	ld de, BUF_rxbuf+1
	ld bc, 0x100
	ldir

	; partial setup of W5100 (rest done by loader)
	ld hl, W5100_REGISTER_PAGE	; page in W5100 into area A
	call F_setpageA
	ld a, 0x0F			; int. enable for all sockets
	ld (IMR), a			; interrupt mask
	
	call F_clear	; clear the screen
	ld hl, STR_romfunctest
	call F_print

	; Open a new socket of type SOCK_STREAM (i.e. TCP)
	ld hl, STR_socket
	call F_print
	ld c, SOCK_STREAM
	call F_socket
	ld (VAR_fd), a		; save the file descriptor
	call F_displayrc

	; Bind the new socket to a port.
	ld hl, STR_bind
	call F_print
	ld a, (VAR_fd)
	ld de, 2000
	call F_bind
	jp c, .oops
	call F_displayrc

	; Listen
	ld hl, STR_listen
	call F_print
	ld a, (VAR_fd)
	call F_listen
	jp c, .oops
	call F_displayrc

	; Accept
	ld hl, STR_accept
	call F_print
	ld a, (VAR_fd)
	call F_accept
	ld (VAR_accfd), a	; save fd of accepted socket
	call F_displayrc

	; Try and receive some stuff
	ld hl, STR_recv
	call F_print
	ld a, (VAR_accfd)
	ld de, BUF_rxbuf
	ld bc, 0x100
	call F_recv

	ld hl, BUF_rxbuf
	call F_print

	; stop
	jp .stop

.oops
	push af
	ld hl, STR_oops
	call F_print
	pop af
	call F_displayrc
.stop
	ld hl, STR_stopped
	call F_print
.stophalt
	halt
	jp .stophalt

	include "../rom/pager.asm"
	include "../rom/sockdefs.asm"
	include "../rom/w5100_genintfunc.asm"
	include "../rom/w5100_buffer.asm"
	include "../rom/w5100_sockalloc.asm"
	include "../rom/w5100_sockctrl.asm"
	include "../rom/w5100_rxtx.asm"

	include "print5by8.asm"
	block 0x9000-$,0x00
	include "rclookup.asm"
	include "charset.asm"

; Simple cls routine
F_clear
	ld hl, 16384
	ld de, 16385
	ld bc, 6144
	ld (hl), 0
	ldir
	ld (hl), 56	; attribute for white
	ld bc, 767
	ldir
	xor a
	ld (v_column), a
	ld (v_rowcount), a
	ld hl, 16384
	ld (v_row), hl
	ret

; hl = start address, b = byte count
F_hexdump
	push hl
	ld a, (hl)
	call F_inttohex8
	call F_print
	ld a, ' '
	call putc_5by8
	pop hl
	inc hl
	djnz F_hexdump
	ret

; Print utility routine.
F_print
	ld a, (hl)
	and a		; test for NUL termination
	ret z		; NUL encountered
	call putc_5by8	; print it
	inc hl
	jr F_print

; F_inttohex8 - convert 8 bit number in A. On return hl=ptr to string
F_inttohex8
	push af
	push bc
	ld hl, v_workspace
	ld b, a
	call	.Num1
	ld a, b
	call	.Num2
	xor a
	ld (hl), a	; add null
	pop bc
	pop af
	ld hl, v_workspace
	ret

.Num1	rra
	rra
	rra
	rra
.Num2	or	0xF0
	daa
	add	a,0xA0
	adc	a,0x40

	ld	(hl),a
	inc	hl
	ret

F_regdump
	push hl
	push de
	push bc
	push af

	ld a, '\n'
	call putc_5by8

	push hl
	ld a, h
	call F_inttohex8
	call F_print
	pop hl
	ld a, l
	call F_inttohex8
	call F_print
	ld a, ','
	call putc_5by8

	ld a, d
	call F_inttohex8
	call F_print
	ld a, e
	call F_inttohex8
	call F_print
	ld a, ','
	call putc_5by8
	
	ld a, b
	call F_inttohex8
	call F_print
	ld a, c
	call F_inttohex8
	call F_print
	ld a, ','
	call putc_5by8

	pop af
	push af
	call F_inttohex8
	call F_print
	pop bc
	push bc
	ld a, c
	call F_inttohex8
	call F_print
	ld a, '\n'
	call putc_5by8

	pop af
	pop bc
	pop de
	pop hl
	ret

; Simple 'wait for the any key to get pressed' routine.
; Based largely on the concepts of the Spectrum's KEY-SCAN routine.
F_waitforkey
	ld bc, 0xFEFE	; B = counter, C = port
.keyline
	in a, (c)	; read key line
	cpl		; 
	and 0x1F	; mask out unused bits and set flags
	ret nz		; key pressed, exit the loop
	rlc b		; shift counter
	jr c, .keyline	; scan if lines to be scanned
	jr F_waitforkey	; Restart routine for another pass.

; Display return codes and add a CR.
F_displayrc
	push af
	call F_inttohex8
	call F_print
	ld a, '\n'
	call putc_5by8
	pop af
	ret

VAR_fd		defb 0
VAR_accfd	defb 0
STR_romfunctest defb "ROM function test routine\n",0
STR_socket	defb "Opening socket: ",0
STR_oops	defb "Operation failed with rc = ",0
STR_bind	defb "bind: ",0
STR_listen	defb "listen: ",0
STR_accept	defb "accept: ",0
STR_recv	defb "recv: ",0
STR_stopped	defb "\nProgram stopped.\n",0
STR_debug	defb "Debug: ",0

BUF_rxbuf	defb 0

	include "../rom/sysvars.asm"
	include "../rom/sysdefs.asm"

