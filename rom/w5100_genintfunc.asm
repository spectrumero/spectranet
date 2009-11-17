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
; General internal functions for the socket library.
;
;
; F_gethwsock:
; Get the hardware socket for a file descriptor. If no hardware socket
; is associated with the fd, set the carry flag and return with the error
; code in A. Otherwise, return the hardware socket register area MSB in
; H.
F_gethwsock
	ex af, af'
	ld a, (v_pga)		; save current page A
	ld (v_buf_pga), a
	ld a, REGPAGE
	call F_setpageA
	ex af, af'
	ld h, v_fd1hwsock / 256	; set (hl) to point at the fd map
	ld l, a
	ld a, (hl)
	ld h, a			; point hl at putative hardware socket
	and NOTSOCKMASK		; is this not a hardware socket?
	ret z			; OK - return with hw sock register in H
.nohwsock
	ld a, ESBADF
	scf
	ret

;----------------------------------------------------------------------------
; J_leavesockfn - jump point to restore original page A
J_leavesockfn
	ex af, af'
	ld a, (v_buf_pga)
	call F_setpageA
	ex af, af'
	ret
