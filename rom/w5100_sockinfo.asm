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
.include	"sockdefs.inc"
.include	"sysvars.inc"
.include	"sysdefs.inc"
.include	"w5100_defs.inc"

;
; Sockinfo.asm0: Routines to get information about a socket, analagous
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
.globl F_sockinfo
F_sockinfo:
	call F_checkpageA
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
	ld a, (v_buf_pgb)
	and a
	jp nz, F_setpageB
	ret

;========================================================================
; F_setsockinfo:
; Sets socket information from structure described above.
;
; Parameters:  H = MSB of W5100 socket register area
;             DE = address of the 8 byte socket info structure.
.globl F_setsockinfo
F_setsockinfo:
	call F_checkpageA
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
	jr z, .checkset2		; need to set random source port?
	ld l, Sn_PORT0 % 256	; hl points at source port
	ld a, (de)		; source port MSB
	ld (hl), a		; set MSB
	inc l
	dec de
	ld a, (de)
	ld (hl), a		; set LSB
	jr .leave2
.checkset2:
	ld l, Sn_PORT0 % 256	; port MSB
	ld a, (hl)
	inc l			; port LSB
	or (hl)			; is it zero?
	jr nz, .leave2		; no - nothing to do
	ex de, hl		; yes - set the local port
	ld hl, v_localport
	ld e, Sn_PORT1 % 256	; set local port LSB
	ldi
	ld e, Sn_PORT0 % 256	; set local port MSB
	ldi
	ld hl, (v_localport)	; update the local port number
	inc hl
	ld (v_localport), hl
	ex de, hl
.leave2:
	ld a, (v_buf_pgb)
	and a
	jp nz, F_setpageB
	ret

;---------------------------------------------------------------------------
; F_fillsockaddr
; Fills a struct sockaddr_in with the remote socket info
; Parameters: Socket in A
;             Pointer to sockaddr_in in DE
.globl F_remoteaddress
F_remoteaddress:
	call F_gethwsock
	jp c, J_leavesockfn	; invalid socket
	
	call F_checkpageA
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
	ld a, (v_buf_pgb)
	and a
	call nz, F_setpageB
	jp J_leavesockfn
		
