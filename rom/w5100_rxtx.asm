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
;
;
; send/sendto and recv/recvfrom send data to a socket and get data
; from it.
;
; F_send:
; Sends data to a socket (that should be a SOCK_STREAM).
; Parameters: A  = file descriptor to send data to
;             DE = source buffer to copy to hardware
;             BC = size of source buffer
; On return,  BC = number of bytes sent
; Carry flag is set on error and A contains error code.
F_send
	call F_gethwsock	; H is socket reg. MSB address
	ret c			; error finding socket if carry set
	ld a, b			; MSB of send buffer size
	cp 0x08			; greater than 2K if compare result is pos.
	jp p, .multisend	; TODO: send buffers >2k
	call F_copytxbuf
	ret
.multisend			; see TODO above!
	ld bc, 0x7FF		; send as much as possible for now.
	call F_copytxbuf
	ret

; F_recv:
; Receive data from a socket. Note - this function blocks if no data
; is available. Use poll to check if data is available if you don't want
; this to happen.
;
; Parameters : A  = file descriptor
;              DE = address of memory to fill with data
;              BC = number of bytes to get
F_recv
	call F_gethwsock	; H is socket reg MSB
	ret c			; carry is set if the fd is not valid
	ld l, Sn_IR % 256	; get the interrupt register

.waitforrecv
	ld a, (hl)
	bit BIT_IR_RECV, a	; see if the recv bit is set
	jr nz, .rxdata		; Data is ready
	bit BIT_IR_DISCON, a	; check for RST condition
	jr z, .waitforrecv	; no, so keep waiting
	ld a, ECONNRESET	; connection reset by peer
	scf
	ret

.rxdata
	set BIT_IR_RECV, (hl)	; clear recv interrupt bit
	call F_copyrxbuf	; if BC >2k it'll get downsized by W5100
	ret

;=========================================================================
; Sendto:
; send data to a non-stream socket (i.e. SOCK_DGRAM, a UDP socket). 
;
; Parameters:  A = file descriptor
;             HL = address of 8 byte socket info structure
;             DE = address of buffer to send
;             BC = size of buffer to send
F_sendto	
	ld (v_bufptr), hl	; save socket info buffer pointer
	call F_gethwsock	; H is socket reg. MSB address
	ret c			; error finding socket if carry set
	push de			; save data buffer
	push bc			; save buffer length
	ld de, (v_bufptr)	; get sock info ptr
	call F_setsockinfo
	pop bc			; retrieve buffer length	
	pop de			; retrieve data buffer
	ld a, b			; MSB of send buffer size
	cp 0x08			; greater than 2K if compare result is pos.
	jp p, .multisend	; TODO: send buffers >2k
	call F_copytxbuf
	ret
.multisend			; see TODO above!
	ld bc, 0x7FF		; send as much as possible for now.
	call F_copytxbuf
	ret

;=========================================================================
; Recvfrom - receive data from a socket. Usually used for a SOCK_DGRAM
; socket, i.e. UDP.
;
; Parameters:  A = file descriptor
;             HL = address of buffer to fill with connection information
;             DE = address of buffer to fill with return data
;             BC = maximum bytes to get
;
; On error, the carry flag is set and the return code is returned in A.
; On successful return, BC contains the number of bytes transferred.
F_recvfrom
	ld (v_bufptr), hl	; save the connection buffer ptr
	call F_gethwsock	; H is socket reg MSB
	ret c			; carry is set if the fd is not valid
	ld l, Sn_IR % 256	; get the interrupt register

.waitforrecv
	ld a, (hl)
	bit BIT_IR_RECV, a	; see if the recv bit is set
	jr nz, .rxdata		; Data is ready
	bit BIT_IR_DISCON, a	; check for RST condition
	jr z, .waitforrecv	; no, so keep waiting
	ld a, ECONNRESET	; connection reset by peer
	scf
	ret

.rxdata
	set BIT_IR_RECV, (hl)	; clear recv interrupt bit
	ld l, Sn_MR % 256	; inspect mode register
	ld a, (hl)
	cp SOCK_DGRAM		; Is this a SOCK_DGRAM (UDP) socket?
	jr z, .rxudp	
	call F_copyrxbuf	; if BC >2k it'll get downsized by W5100
	ld de, (v_bufptr)	; retrieve the buffer pointer
	call F_sockinfo		; get socket information
	ret

	; UDP data comes with an 8 byte header stuck to the front.
	; To avoid having to shift the entire receive data buffer around,
	; first we pull off this 8 byte header and put it into the
	; socket info buffer. Then we receive the data proper.
	; The structure of the socket info buffer is documented in
	; w5100_sockinfo.asm.
.rxudp
	push bc			; save the max length requested
	push de			; save the data buffer address
	ld bc, 8		; length of the header
	ld de, (v_bufptr)	; retrieve the header buffer pointer
	call F_copyrxbuf	; fetch the header
	ld l, Sn_IR % 256	; the IR needs resetting again
	set BIT_IR_RECV, (hl)	; since the W5100 sees it still has data
	pop de			; retrieve the data buffer address
	pop bc			; retrieve the length argument
	call F_copyrxbuf	; get the data
	push hl			; save the W5100 register pointer
	ld ix, (v_bufptr)	; now convert the big endian port to
	ld h, (ix+4)		; little endian. Byte 4 is the high order
	ld l, (ix+5)		; and 5 is the low order byte.
	ld (ix+4), l
	ld (ix+5), h
	pop hl			; get the register pointer back
	ld l, Sn_PORT0 % 256	; point it at the source port register
	ld a, (hl)
	ld (ix+7), a		; high order of the source port
	inc l
	ld a, (hl)
	ld (ix+6), a		; low order of the source port
	ret

;--------------------------------------------------------------------------
; F_poll:
; Check an array of open file descriptors to see if one has data ready
; to read (or in the case of a listening socket, if someone connected).
; This function doesn't provide a timeout (the BSD version does). The 
; C wrapper will provide a timeout.
;
; Parameters: DE = address of file descriptor list
;             B  = number of file descriptors to poll
;
; If an fd is found that is ready (data can be read, or a connection can
; be accepted), the first fd to be found ready is returned in A and the
; flags that caused the condition in B. If no sockets are ready, A is 0 
; and the zero flag is set. On error, the carry flag is set and A is set 
; to the error.
F_poll
	ld a, REGPAGE
	call F_setpageA

.sockloop
	ld a, (de)		; get the first socket
	ld c, a			; save the file descriptor
	ld h, v_fd1hwsock / 256	; set (hl) to point at fd map
	ld l, a			; (hl) = fd address
	ld a, (hl)		; a = hw socket MSB
	and SOCKMASK		; mask out closed/virtual bits
	jr nz, .poll		; nonzero means it's an open hw socket
	inc de			; next socket
	djnz .sockloop
	jr .noneready
.poll
	ld h, a			; (hl) = socket register
	ld l, Sn_IR % 256	; interrupt register
	ld a, (hl)
	and S_IR_CON|S_IR_RECV|S_IR_DISCON
	jr nz, .ready		; an event has occurred
	inc de			; next file descriptor
	djnz .sockloop		
.noneready
	xor a			; loop finished, no sockets were ready
	ret
.ready
	ld b, a			; save flags
	ld a, c			; retrieve fd
	ret

;---------------------------------------------------------------------------
; F_pollall:
; This is not a BSD socket library function. However, there are many
; (perhaps most?) instances where you just want to poll all open sockets.
; Given there can never be very many file descriptors in the first place,
; unless you're polling a subset of your file descriptors, it's probably
; best to use this function (it will be a lot easier, since you won't
; need to shuffle things in and out of an array of file descriptors)
;
; To make the program (if written in C) compatible with a modern OS, it
; would be quite easy to provide an #ifdef'd pollall() function.
;
; No parameters. The first file descriptor found to be ready will be returned
; in A. If none are ready, A=0 and the zero flag is set. If an fd is ready,
; it is returned in A, and C contains the flags that triggered the condition.
F_pollall
	ld a, REGPAGE
	call F_setpageA
	ld d, v_fd1hwsock / 256
	ld a, (v_lastpolled)	; get addr. of socket to start at
	cp MAX_FD_NUMBER+1	; wrap if this puts us off the end
	jr nz, .setaddr
	ld a, v_fd1hwsock % 256	; wrap
.setaddr
	ld e, a			; (de) points at socket to poll
	ld b, MAX_FDS
.sockloop
	ld a, (de)		; get hardware socket register ptr
	and SOCKMASK		; check it's a real socket
	jr nz, .poll
.nextsock
	inc e			; next socket
	ld a, MAX_FD_NUMBER+1
	cp e			; wrap around to first fd?
	jr nz, .continue	; no
	ld e, v_fd1hwsock % 256	; wrap back to first file descriptor
.continue
	djnz .sockloop
	jr .noneready
.poll
	ld h, a			; (hl) = socket register
	ld l, Sn_IR % 256	; interrupt register
	ld a, (hl)
	and S_IR_CON|S_IR_RECV|S_IR_DISCON
	jr nz, .ready
	jr .nextsock		; advance to next socket fd
.noneready
	xor a			; A=0, zero flag set
	ret
.ready
	ld c, a			; copy flags into C
	ld a, e			; ready fd in e
	inc a
	ld (v_lastpolled), a	; save last polled sockfd+1
	dec a			; restore A to proper value
	ret

;-------------------------------------------------------------------------
; F_pollfd
; Poll a single file descriptor.
; Again, not a BSD socket function. However, in many instances all you
; need to do is poll a single socket, and this will be the most efficient
; way to do it.
; Parameters: A = socket file descriptor
; Zero flag is set if not ready.
; For a ready fd, the reason for readiness is returned in C
; Carry is set on error.
F_pollfd
	call F_gethwsock	; H is socket reg MSB
	ret c			; carry is set if the fd is not valid

	ld l, Sn_IR % 256	; interrupt register
	ld a, (hl)		; read its value
	and S_IR_CON|S_IR_RECV|S_IR_DISCON
	ld c, a			; copy flags into C
	ret

