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


; Socket allocation routines. In this file:
; F_socket
; F_accept
; F_close
;
; These routines open hardware sockets and map them to a file descriptor,
; and clean up when all work is done. They are the equivalent of the
; BSD socket library function calls socket() and close(). C implementations
; should wrap these in the appropriate socket()/close() functions.
; The file descriptor is actually the low order of the fd <-> socket
; map address. C wrappers might need to map this further into a list
; of file descriptors.
;
; F_socket:
; Finds a free hardware socket and allocates it to a file descriptor.
; The full BSD routine is int socket(int family, int type, int proto)
; but this function will always be specific to AF_INET sockets, so
; only the type parameter is used. This should be SOCK_STREAM, SOCK_DGRAM
; or SOCK_RAW.
;
; Parameters: C = int type
; Returns: file descriptor in A
;
; Preserves: BC
F_socket
	ld a, (v_pga)		; save page A
	ld (v_buf_pga), a
	ld a, REGPAGE
	call F_setpageA

	; Find a free socket. HL will contain the pointer to the socket
	; register.
	call F_hwallocsock	; carry is set when no hw sockets left.
	jr nc, .foundsock
.nosockets
	ld a, ENFILE		; no more hardware sockets, sorry
	jp J_leavesockfn
.foundsock
	ld de, v_fd1hwsock	; (de) = fd map first entry
	ex de, hl
.findfd
	bit 7, (hl)		; is bit 7 (not allocated) set?
	jr nz, .allocfd
	inc l			; next fd
	jr .findfd
.allocfd
	ld (hl), d		; associate the hw socket with the fd
	ex de, hl
	call F_hwopensock	; h = msb of socket register
	jr nc, .sockopen	; if carry not set, socket was opened
	ld a, EBUGGERED		; TODO: better return code
	jp J_leavesockfn

.sockopen
	ld a, e			; a = file descriptor
	jp J_leavesockfn

;-------------------------------------------------------------------------
; F_sockclose:
; Close an open socket and free its file descriptor. The BSD socket
; library equivalent is: int close(int fd)
; 
; Parameters: A = file descriptor
;
; Carry flag is set if an error occurs reopening a virtual socket.
F_sockclose
	push af
	ld a, (v_pga)		; save page A
	ld (v_buf_pga), a
	ld a, REGPAGE
	call F_setpageA
	pop af

	ld h, v_fd1hwsock / 256	; high order of file descriptor map
	ld l, a			; (hl) = file descriptor map
	ld a, (hl)		; get possible MSB of socket register ptr
	bit 6, a		; is this a virtual socket or not even open?
	ld (hl), FD_CLOSED	; unmap the file descriptor
	jp nz, J_leavesockfn	; virtual socket, no hardware sock to close

	ld h, a			; h = MSB of socket register pointer
	ld l, Sn_MR % 256	; check for non-stream socket
	ld a, (hl)
	and S_MR_TCP		; if it's not TCP jump forward
	jr z, .close		; straight to closing the hardware resource

	ld l, Sn_SR % 256	; check the status register
	ld a, (hl)
	cp S_SR_SOCK_INIT	; nothing has been done yet
	jr z, .close		; so skip disconnect part.

	cp S_SR_SOCK_LISTEN	; still nothing has been done
	jr z, .close		; so skip disconnect part.

	ld l, Sn_CR % 256	; (hl) = socket's command register
	ld (hl), S_CR_DISCON	; disconnect remote host
	ld l, Sn_IR % 256	; (hl) = interrupt register
.waitfordiscon
	ld a, (hl)
	and S_IR_DISCON
	jr z, .waitfordiscon
	ld (hl), S_IR_DISCON	; reset interrupt register
.close
	ld l, Sn_CR % 256	; (hl) = command register
	ld (hl), S_CR_CLOSE	; close the socket.
	ex de, hl		; store socket register pointer in DE

	; Check for virtual sockets. A virtual socket is allocated when
	; we are listening, and ran out of hardware sockets but needed
	; to keep an open fd for the listen()/accept() routine. We now
	; definitely have at least one free socket going, so we can give
	; it to the first fd that we find that's in need of one.
	ld hl, v_fd1hwsock
	ld b, MAX_FDS
.vsearch
	bit 6, (hl)		; virtual bit set?
	jr nz, .realloc		; reallocate the hardware socket to this fd
	inc l			; check the next fd
	djnz .vsearch
	jp J_leavesockfn	; nothing more to do - function complete.

	; To reallocate a hardware socket to a file descriptor that's
	; gone virtual, it must be opened.
.realloc
	; The hardware needs a delay before a socket is re-opened.
	; TODO: write to Wiznet and see if there's a better way of doing this.
	ld b, 255
.waitloop
	djnz .waitloop

	ex de, hl		; socket register pointer back to HL
	ld a, (v_virtualmr)	; get socket type for the socket we're doing
	ld c, a			; socket type in C
	call F_hwopensock	; open socket pointed to by (hl)
	jp c, J_leavesockfn	; an error has occurred if carry is set.
	ex de, hl		; fd address now in hl, sock register in de
	push hl			; save fd
	ld hl, v_virtualport	; v_virtualport is in network byte order
	ld e, Sn_PORT0 % 256	; de = port register
	ldi
	ldi
	ex de, hl		; sock in hl, de=don't care
	ld l, Sn_CR % 256	; get command register
	ld (hl), S_CR_LISTEN	; listen
	ld l, Sn_SR % 256	; get status register
	ld a, (hl)
	cp S_SR_SOCK_LISTEN	; should be listening
	ex de, hl		; move sock register addr to de
	pop hl			; retrieve fd
	jr nz, .reallocerr
	ld (hl), d		; store socket register ptr MSB in fd map
	jp J_leavesockfn
.reallocerr
	ld a, EBUGGERED
	scf
	jp J_leavesockfn

;--------------------------------------------------------------------------
; F_accept: Accept a connection on a socket that is listening.
; 
; First, the connection is accepted by poking the hardware registers.
; Then a new fd is allocated, and the hardware socket is associated with
; the new fd. Then, a new listening socket is opened - and if we've not
; run out of hardware sockets it is associated with the original fd.
; If we've run out of hardware sockets, the original fd is marked
; virtual (so that a new socket can get allocated when one gets closed).
;
; Parameters: A = file descriptor to perform an accept on.
; Returns: A = file descriptor of accepted connection
;
; On error carry is set and A contains the error number.
F_accept
	push af			; save the fd
	ld a, (v_pga)		; save page A
	ld (v_buf_pga), a
	ld a, REGPAGE
	call F_setpageA
	pop af

	ld h, v_fd1hwsock / 256	; MSB of fd map address
	ld l, a			; (hl) = fd map for this fd
	ld d, (hl)		; d = MSB of socket register address
	ex de, hl		; h = MSB of socket register address
	ld l, Sn_SR % 256	; (hl) = socket's SR
.waitforestablished
	ld a, (hl)
	cp S_SR_SOCK_ESTABLISHED
	jr nz, .waitforestablished
	ld l, Sn_IR % 256	; clear the interrupt flag for this socket
	ld (hl), S_IR_CON

	; Now allocate a new fd for the accepted connection.
	ld b, h			; save socket register pointer MSB
	ld hl, v_fd1hwsock
.findfd
	bit 7, (hl)		; is bit 7 (not allocated) set?
	jr nz, .allocfd
	inc l			; next fd
	jr .findfd
.allocfd
	ld (hl), b		; associate new fd with accepted socket
	push hl			; save address of new fd
	ld h, b			; point hl at accepted socket to get type
	ld l, Sn_MR % 256	; (hl) = socket's MR
	ld c, (hl)		; save MR in c
	call F_hwallocsock	; try to open a new hardware socket
	jr c, .virtualize	; no sockets left, so virtualize the fd
	call F_hwopensock	; (hl) points at new registers, try to open
	jr c, .virtualize	; failed
	ex de, hl		; get original fd address into hl
	ld (hl), d		; save the new listening socket's MSB in fd map
	ld h, b			; get MSB of original socket
	ld l, Sn_PORT0 % 256	; (hl) = port register of accepted hw socket
	ld e, l			; (de) = port register of new hw socket
	ldi			; copy port across to bind new hw socket
	ldi
	ex de, hl		; new socket pointed to by hl
	ld l, Sn_CR % 256	; hl = command register ptr
	ld (hl), S_CR_LISTEN	; tell new socket to listen
	ld l, Sn_SR % 256	; hl = status register ptr
	ld a, (hl)
	cp S_SR_SOCK_LISTEN	; check for listening state
	jr nz, .listenfail
	pop hl			; get fd back to return to caller
	ld a, l			; set fd number in A
	jp J_leavesockfn
.listenfail
	ld a, EBUGGERED		; set error code and return with carry set
	scf
	jp J_leavesockfn

.virtualize
	ex de, hl		; get original fd address
	ld (hl), FD_VIRTUAL	; mark as virtual
	ld h, b			; get MSB of socket register into H for HL
	ld l, Sn_MR % 256	; mode register
	ld de, v_virtualmr	; point de at MR storage
	ldi			; save MR
	ld l, Sn_PORT0 % 256	; port number
	ldi			; save in network byte order in v_virtualport
	ldi			
	pop hl			; get fd back	
	ld a, l			; new fd number in A
	jp J_leavesockfn

;--------------------------------------------------------------------------
; Find a free hardware socket. Carry flag is set if no free sockets.
; An internal function.
; No parameters.
; On return (hl) = status register of available hardware socket.
F_hwallocsock
	; Find a free socket.
	ld hl, Sn_SR		; hl points at the first socket register
.sockloop
	ld a, (hl)		; get status register value
	cp S_SR_SOCK_CLOSED	; a closed socket?
	jr z, .foundsock	; yes, allocate it
	inc h			; next socket register
	ld a, h			; check whether hardware sockets are
	cp Sn_MAX		; exhausted
	jr nz, .sockloop	; and check the next if not.
	scf			; out of sockets - set C
.foundsock
	ret

; Open a hardware socket. Carry flag is set if no free sockets.
; An internal function.
; Parameters: C = socket type (SOCK_STREAM, SOCK_DGRAM, SOCK_RAW etc)
; 	      HL = pointer to socket register area
F_hwopensock
	ld a, SOCK_STREAM	; for SOCK_STREAM ensure delayed ACK is off
	cp c
	jr nz, .continue
	set 5, c		; set 'use no delayed ACK'
.continue
	ld l, Sn_IR % 256	; (hl) = interrupt register
	ld (hl), 0x1F		; clear all interrupt flags
	ld l, Sn_MR % 256	; (hl) = socket mode register
	ld (hl), c		; set type of socket
	ld l, Sn_CR % 256	; (hl) = command register
	ld (hl), S_CR_OPEN	; hardware command: open socket	
	ld l, Sn_SR % 256	; (hl) = status register
	ld a, SOCK_DGRAM	; is this a UDP socket?
	cp c
	jr z, .checkudpstat	; do status check for UDP socket.
	ld a, (hl)		; TCP socket (SOCK_STREAM)
	cp S_SR_SOCK_INIT	; did it initialize ok?
	ret z

	; Bad things happened. Clean up and return an error.
.failed
	ld l, Sn_CR % 256	; (hl) = command register so...
	ld (hl), S_CR_CLOSE	; clean up.
	scf
	ret
.checkudpstat
	ld a, (hl)
	cp S_SR_SOCK_UDP	; Successfully initialized?
	ret z
	jr .failed

