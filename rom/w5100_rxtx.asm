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
	bit S_IR_RECV, (hl)	; see if the recv bit is set
	jr z, .waitforrecv	; not yet, wait.

	set S_IR_RECV, (hl)	; clear recv interrupt bit
	call F_copyrxbuf	; if BC >2k it'll get downsized by W5100
	ret

; TODO: sendto/recvfrom
F_sendto
F_recvfrom
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
; be accepted), the first fd to be found ready is returned in A. If
; no sockets are ready, A is 0 and the zero flag is set. On error, the
; carry flag is set and A is set to the error.
F_poll
	ld hl, W5100_REGISTER_PAGE
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
	bit S_IR_CON, (hl)	; Interrupt for a new connection?
	jr nz, .ready		; ready for action
	bit S_IR_RECV, (hl)	; Interrupt for received data?
	jr nz, .ready		; ready for action
	inc de			; next file descriptor
	djnz .sockloop		
.noneready
	xor a			; loop finished, no sockets were ready
	ret
.ready
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
; in A. If none are ready, A=0 and the zero flag is set.
F_pollall
	ld hl, W5100_REGISTER_PAGE
	call F_setpageA
	ld de, v_fd1hwsock
	ld b, MAX_FDS
.sockloop
	ld a, (de)		; get hardware socket register ptr
	and SOCKMASK		; check it's a real socket
	jr nz, .poll
	inc e
	djnz .sockloop
	jr .noneready
.poll
	ld h, a			; (hl) = socket register
	ld l, Sn_IR % 256	; interrupt register
	bit S_IR_CON, (hl)	; Interrupt for a new connection?
	jr nz, .ready		; ready for action
	bit S_IR_RECV, (hl)	; Interrupt for received data?
	jr nz, .ready		; ready for action
	inc e			; next file descriptor
	djnz .sockloop
.noneready
	xor a			; A=0, zero flag set
	ret
.ready
	ld a, e			; ready fd in e
	ret

