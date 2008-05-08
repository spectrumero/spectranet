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
	ld a, FD_CLOSED
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

	; Test client (connect function)
	;jp F_client
	;jp F_udp
	jp F_dnslookup

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
	jp c, oops
	call F_displayrc

	; Listen
	ld hl, STR_listen
	call F_print
	ld a, (VAR_fd)
	call F_listen
	jp c, oops
	call F_displayrc

.poll
	ld hl, STR_polling
	call F_print
	call F_dumpfds
.pollloop
	call F_pollall
	jr z, .pollloop
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

	; Try to send something back
	ld a, (VAR_accfd)
	ld de, STR_romfunctest
	ld bc, STR_socket-STR_romfunctest
	call F_send

	; Close
	ld hl, STR_closing
	call F_print
	ld a, (VAR_accfd)
	call F_sockclose
	jr c, oops
	jp .poll

	; stop
	jp stop

oops
	push af
	ld hl, STR_oops
	call F_print
	pop af
	call F_displayrc
stop
	ld hl, STR_stopped
	call F_print
stophalt
	halt
	jp stophalt

	; test client code
F_client
	; Open a new socket of type SOCK_STREAM (i.e. TCP)
	ld hl, STR_socket
	call F_print
	ld c, SOCK_STREAM
	call F_socket
	ld (VAR_clifd), a		; save the file descriptor
	call F_displayrc

	; Connect to remote host
	ld hl, STR_connecting
	call F_print
	ld a, (VAR_clifd)
	ld de, DEST_IP
	ld bc, 2000
	call F_connect
	jp c, oops
	call F_displayrc

	; Send something
	ld hl, STR_sending
	call F_print
	ld a, (VAR_clifd)
	ld de, STR_romfunctest
	ld bc, STR_socket-STR_romfunctest
	call F_send

	; Close
	ld hl, STR_closing
	call F_print
	ld a, (VAR_clifd)
	call F_sockclose
	jp c, oops

	; stop
	jp stop

; Test UDP
F_udp
	; Open a new socket of type SOCK_DGRAM (UDP)
	ld hl, STR_socket
	call F_print
	ld c, SOCK_DGRAM
	call F_socket
	ld (VAR_fd), a		; save the file descriptor
	call F_displayrc

.loop
	; try to send something back
	ld hl, STR_sendto
	call F_print

	; port 2000 on the remote
	ld ix, BUF_txinfo
	xor a
	ld (ix+6), a
	ld (ix+7), a
	ld hl, BUF_txinfo
	ld de, STR_romfunctest
	ld bc, STR_socket-STR_romfunctest
	ld a, (VAR_fd)
	call F_sendto
	jp c, oops
	call F_regdump

	ld hl, STR_recvfrom
	call F_print
	ld hl, BUF_txinfo
	ld de, BUF_rxbuf
	ld bc, 0x100
	ld a, (VAR_fd)
	call F_recvfrom
	jp c, oops
	ld hl, BUF_rxbuf
	call F_print
	
	ld hl, W5100_REGISTER_PAGE
	call F_setpageA
	ld hl, 0x1401
	call F_dumpw5100
	jr .loop

	call F_waitforkey	
	ret

; dns test
F_dnslookup
	ld hl, DNS_IP
	ld de, v_nameserver1
	ldi
	ldi
	ldi
	ldi

	ld hl, STR_dns
	call F_print
	ld hl, STR_host
	call F_print
	ld a, '\n'
	call putc_5by8

	ld hl, STR_host
	ld de, BUF_ip
	call F_gethostbyname
	jp c, oops

	ld hl, STR_dnsresult
	call F_print

	; Show IP
	ld hl, BUF_ip
	ld de, BUF_rxbuf	; just a convenient place to store stuff
	call F_long2ipstring
	ld hl, BUF_rxbuf	; and display it
	call F_print

	ld a, '\n'
	call putc_5by8

	call F_waitforkey
	jp 0x007B

	include "../rom/pager.asm"
	include "../rom/sockdefs.asm"
	include "../rom/w5100_genintfunc.asm"
	include "../rom/w5100_buffer.asm"
	include "../rom/w5100_sockalloc.asm"
	include "../rom/w5100_sockctrl.asm"
	include "../rom/w5100_rxtx.asm"
	include "../rom/w5100_sockinfo.asm"
	include "../rom/dns.asm"
	include "../rom/dnsdefs.asm"
	include "../rom/utility.asm"

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

F_dumpfds
	push hl
	push de
	push bc
	push af
	ld hl, v_fd1hwsock
	ld b, 5
.loop
	ld a, (hl)
	push hl
	call F_inttohex8
	call F_print
	ld a, ' '
	call putc_5by8
	pop hl
	inc l
	djnz .loop
	ld a, '\n'
	call putc_5by8

	pop af
	pop bc
	pop de
	pop hl
	ret

; ix points to sockinfo data
F_dumpsockinfo
	ld a, (ix+0)
	call F_inttohex8
	call F_print
	ld a, '.'
	call putc_5by8
	ld a, (ix+1)
	call F_inttohex8
	call F_print
	ld a, '.'
	call putc_5by8
	ld a, (ix+2)
	call F_inttohex8
	call F_print
	ld a, '.'
	call putc_5by8
	ld a, (ix+3)
	call F_inttohex8
	call F_print
	ld a, ':'
	call putc_5by8
	ld a, (ix+5)
	call F_inttohex8
	call F_print
	ld a, (ix+4)
	call F_inttohex8
	call F_print
	ld a, ':'
	call putc_5by8
	ld a, (ix+7)
	call F_inttohex8
	call F_print
	ld a, (ix+6)
	call F_inttohex8
	call F_print
	ld a, '\n'
	call putc_5by8
	ret

; h = register page
F_dumpw5100
	ld l, Sn_DIPR0 % 256	; hl = dest. IP
	ld a, (hl)
	push hl
	call F_inttohex8
	call F_print
	ld a, '.'
	call putc_5by8
	pop hl
	inc l
	ld a, (hl)
	push hl
	call F_inttohex8
	call F_print
	ld a, '.'
	call putc_5by8
	pop hl
	inc l
	ld a, (hl)
	push hl
	call F_inttohex8
	call F_print
	ld a, '.'
	call putc_5by8
	pop hl
	inc l
	ld a, (hl)
	push hl
	call F_inttohex8
	call F_print
	ld a, ':'
	call putc_5by8
	pop hl
	ld l, Sn_DPORT0 % 256	; dest port
	ld a, (hl)
	push hl
	call F_inttohex8
	call F_print
	pop hl
	inc l
	ld a, (hl)
	push hl
	call F_inttohex8
	call F_print
	ld a, ':'
	call putc_5by8
	pop hl
	ld l, Sn_PORT0 % 256	; source port
	ld a, (hl)
	push hl
	call F_inttohex8
	call F_print
	pop hl
	inc l
	ld a, (hl)
	push hl
	call F_inttohex8
	call F_print
	ld a, '\n'
	call putc_5by8
	pop hl
	ret
	
; hl = start address, bc = bytes to dump
F_dumpmem
	push de
	push af
.loop
	ld a, (hl)
	push hl
	push bc
	call F_inttohex8
	call F_print
	ld a, ' '
	call putc_5by8
	pop bc
	pop hl

	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .loop

	ld a, '\n'
	call putc_5by8

	pop af
	pop de
	ret

		
	
VAR_fd		defb 0
VAR_accfd	defb 0
VAR_clifd	defb 0
VAR_ws		defw 0
DEST_IP		defb 172,16,0,2
STR_romfunctest defb "ROM function test routine\n",0
STR_socket	defb "Opening socket: ",0
STR_oops	defb "Operation failed with rc = ",0
STR_bind	defb "bind: ",0
STR_listen	defb "listen: ",0
STR_accept	defb "accept: ",0
STR_recv	defb "recv: ",0
STR_stopped	defb "\nProgram stopped.\n",0
STR_debug	defb "Debug: ",0
STR_closing	defb "Closing sockets.\n",0
STR_closelisten	defb "...closing listen socket\n",0
STR_polling	defb "polling...",0
STR_sending	defb "Sending\n",0
STR_connecting	defb "connect: ",0
STR_recvfrom	defb "recvfrom: ",0
STR_sendto	defb "sendto...\n",0
STR_host	defb "spectrum.alioth.net",0
STR_dns		defb "Testing DNS\n\nLooking up: ",0
STR_dnsresult	defb "Result: ",0
DNS_IP		defb 83,218,26,5
BUF_txinfo	defb 172,16,0,2,0xD0,0x07,0x00,0x00

BUF_conninfo	defb 0,0,0,0,0,0,0,0
BUF_ip		defb 0,0,0,0
BUF_rxbuf	defb 0

UNPAGE		equ 0x7c
	include "../rom/sysvars.asm"
	include "../rom/sysdefs.asm"
