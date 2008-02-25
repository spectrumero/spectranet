;The MIT License
;
;Copyright (c) 2008 Dylan Smith
;
;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:
;
;The above copyright notice and this permission notice shall be included in
;all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;THE SOFTWARE.


; Socket control routines. In this file:
; F_bind
; F_connect
;
; Bind is used to set the socket parameters for a port that is going to
; listen. Connect is used to set the parameters when initiating a connection
; to a remote host.
;
; There's an important difference with the assembler routines compared to
; the BSD interface. On Unix, bind() is defined as follows:
;
;   int bind(int sockfd, const struct sockaddr *my_addr, socklen_t addrlen);
;
; The asm function F_bind only takes sockfd and port as a parameter.
; This is because we only will ever support AF_INET family sockets regardless
; of the hardware.
;
; The full BSD bind() implementation uses the struct sockaddr to pass 
; various parameters. It is intended that the z88dk C library will take
; a struct sockaddr pointer. But this is overkill for assembler programs
; so we don't do it.
;
; Connect is similar, except an IP address must be supplied as well.
; The C version will use a struct sockaddr pointer.
;
;---------------------------------------------------------------------------
; F_bind:
; Set socket information for a socket that will be used for listening
; (the local port to listen on).
;
; Parameters: A  = socket fd
;             DE = port
; On error, carry flag is set and A contains error number.
F_bind
	call F_gethwsock	; H now is hardware socket MSB address
	ret c			; carry is set on error
	ld l, Sn_PORT0 % 256	; port register
	ld (hl), d		; set port MSB
	inc l
	ld (hl), e		; set port LSB
	ret

;--------------------------------------------------------------------------
; F_listen:
; Tell a socket to listen for incoming connections.
; 
; Parameters: A  = socket fd
;
; On error, the carry flag is set and A contains the error number.
F_listen
	call F_gethwsock	; H is now hardware socket MSB address
	ret c			; unless carry is set because of an error

	ld l, Sn_CR % 256	; hl points at hardware socket's command reg
	ld (hl), S_CR_LISTEN	; tell the socket to listen
	ld l, Sn_SR % 256	; hl points at the status register
	ld a, (hl)		; read it
	cp S_SR_SOCK_LISTEN	; check state is now listening
	ret z			; Socket is listening so return
	ld a, EBUGGERED		; hardware error
	scf			; set carry flag and return
	ret

;-------------------------------------------------------------------------
; F_connect:
; Connect to a remote host.
;
; Parameters: A = socket fd
;            DE = pointer to 4 byte buffer containing destination IP
;            BC = port number
; On error, the carry flag is set and A contains the error number.
; On success, returns zero in A
F_connect
	push af
	ld hl, W5100_REGISTER_PAGE
	call F_setpageA
	pop af

	call F_gethwsock	; H = socket register bank MSB
	ld l, Sn_DPORT0 % 256	; destination port register
	ld (hl), b		; high order of port
	inc l
	ld (hl), c		; low order of port
	ld l, Sn_DIPR0 % 256	; destination IP address register
	ex de, hl		; passed buffer value now in hl
	ldi
	ldi
	ldi
	ldi
	ex de, hl
	ld l, Sn_CR % 256	; command register
	ld (hl), S_CR_CONNECT	; instruction to connect to remote host

	ld l, Sn_IR % 256	; interrupt register
.waitforconn
	ld a, (hl)
	bit BIT_IR_CON, a
	jr nz, .connected
	and a			; if not, is it zero (no flags set?)
	jr z, .waitforconn
	and S_IR_DISCON		; connection refused?
	jr nz, .refused
	ld a, ETIMEDOUT		; connection timed out
	scf
	ret	
.refused
	ld a, ECONNREFUSED
	scf
	ret
.connected
	set BIT_IR_CON, (hl)	; reset interrupt bit
	xor a			; connection OK
	ret

