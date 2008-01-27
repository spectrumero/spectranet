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
	call F_copyrxbuf	; if BC >2k it'll get downsized by W5100
	ret

; TODO: sendto/recvfrom
F_sendto
F_recvfrom
	ret

