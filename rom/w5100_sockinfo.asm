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
; Sockinfo.asm: Routines to get information about a socket, analagous
; to filling a struct sockaddr_t in C.
;
; The data structure that is returned looks like this:
;
; remote IP   - 32 bits
; remote port - 16 bits
; local port  - 16 bits
;
; So the calling program must allow 6 bytes for the data to be returned.
;===========================================================================
; F_sockinfo:
; Returns information about a hardware socket. It's assumed that the W5100
; register area is paged in.
;
; Parameters:  H = High order of socket hardware register address
;             DE = Address of the buffer to fill.
F_sockinfo
	ld l, Sn_DIPR0 % 256	; remote IP address register
	ldi
	ldi
	ldi
	ldi
	; convert ports from big to little endian
	ld l, Sn_DPORT1 % 256	; remote port register
	ld a, (hl)
	ld (de), a
	dec l
	inc de
	ld a, (hl)
	ld (de), a
	inc de
	ld l, Sn_PORT1 % 256	; local port register
	ld a, (hl)
	ld (de), a
	dec l
	inc de
	ld a, (hl)
	ld (de), a
	ret

;========================================================================
; F_setsockinfo:
; Sets socket information from structure described above.
;
; Parameters:  H = MSB of W5100 socket register area
;             DE = address of the 8 byte socket info structure.
F_setsockinfo
	ex de, hl
	ld e, Sn_DIPR0 % 256	; destination IP address
	ldi
	ldi
	ldi
	ldi
	ld e, Sn_DPORT1 % 256	; destination port
	ld a, (hl)
	ld (de), a
	dec e
	inc hl
	ld a, (hl)
	ld (de), a
	inc hl

	; only set source port if source port is set.
	ld a, (hl)
	inc hl
	or (hl)
	ex de, hl		; restore registers to expected order
	ret z			; nothing more to do
	ld l, Sn_PORT1 % 256	; hl points at source port
	ld a, (de)		; source port MSB
	ld (hl), a		; set MSB
	inc l
	dec de
	ld a, (de)
	ld (hl), a		; set LSB
	ret

;---------------------------------------------------------------------------
; F_fillsockaddr
; Fills a struct sockaddr_in with the remote socket info
; Parameters: Socket in A
;             Pointer to sockaddr_in in DE
F_remoteaddress
	call F_gethwsock
	ret c			; invalid socket

	inc de			; increment past int sin_family
	inc de
	ld l, Sn_DPORT1 % 256	; destination port LSB
	ldi
	ld l, Sn_DPORT0 % 256	; destination port MSB
	ldi

	ld l, Sn_DIPR0 % 256	; remote IP address register
	ldi			; copy in network order
	ldi	
	ldi
	ldi
	ret
		
