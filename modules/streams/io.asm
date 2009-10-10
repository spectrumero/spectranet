;The MIT License
;
;Copyright (c) 2009 Dylan Smith
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

; IO routines for streams
J_modcall
	call F_fetchpage	; get our memory page
	bit 6, l		; Control stream?
	jp nz, F_ctrlstream
	bit 7, l		; MSB set?
	jr nz, F_input		; Call the input routine
	call F_feedbuffer	; Pass writes to the buffer
	jp F_leave

;----------------------------------------------------------------------------
; F_input
; Process input to a stream.
F_input
	push hl
	ld hl, ZX_TV_FLAG	; the mode is considered unchanged
	res 3, (hl)
	pop hl

	ld a, l			; fetch the function number
	and 0x0f		; clear flag bits
	ld c, a			; save it
	rlca			; find metadata for stream
	rlca
	rlca
	ld l, a
	ld h, 0x10		; point HL at metadata
	ld d, (hl)		; get tx buffer number
	inc l			; point at tx buffer pointer
	inc l
	ld a, (hl)		; get tx buffer pointer
	and a			; if nonzero, flush the buffer
	call nz, .flush

.isinkey
	push hl
	ld hl, (ZX_ERR_SP)	; fetch the current ERR_SP
	ld e, (hl)
	inc hl
	ld d, (hl)
	and a
	ld hl, 0x107F		; Compare with ED_ERROR
	sbc hl, de
	pop hl
	jp nz, .doinkey

.input
	dec l			; HL points at RX buffer number
;	ld d, (hl)		; which is the MSB of the actual buffer...
	ld d, INTERPWKSPC/256	; TODO: use our private buffers
	inc l			; HL now points at the
	inc l			; RX buffer current address
	ld e, (hl)
	push hl			; save this address
	inc l			; and now it points at the socket handle
	ld a, (hl)		; fetch it
	ld (v_asave), a		; save it for the loop operation
	inc l
	ld (flagaddr), hl	; save the address of the flags byte
	xor a			; Is the buffer pointer at 
	cp e			; the start of the buffer?
	jr z, .getdata		; Yes - so read more data from the network
	
	inc l			; HL points at bytes remaining in buffer...
	ld b, (hl)		; ...parameter, fetch it
	ex de, hl		; and put the buffer pointer in HL
	jr .unloadloop

.getdata
	ld a, (v_asave)		; Get the descriptor
	ld de, INTERPWKSPC
	ld bc, 255		; read up to 255 chars
	ld hl, (flagaddr)	; check flags bit
	bit BIT_ISFILE, (hl)	; is a file?
	jr nz, .readfromfile
	bit BIT_ISDIR, (hl)	; is a directory?
	jr nz, .readdir
	call RECV
.readdone
	jp c, .readerrpop
.readdirdone
	ld hl, INTERPWKSPC
	ld b, c			; get the length returned into B for djnz

.unloadloop
	ld a, (hl)
	cp 0x0d			; This is how the Interface 1 does it...
	jr z, .checkformore	; Either a CR
	cp 0x0a
	jr z, .checkformore	; or a linefeed
	push hl
	push bc
	rst CALLBAS
	defw 0x0F85		; ROM ADD-CHAR subroutine
	pop bc
	pop hl
	inc l
	djnz .unloadloop
	jr .getdata		; go get it

.readfromfile
	call READ
	jr .readdone
.readdir
	call READDIR
	jp c, .readerrpop
	ld hl, INTERPWKSPC	; directly load INPUT with data as we can
.readdirloop
	ld a, (hl)		; never have a partial read doing READDIR.
	and a			; End of string?
	jr z, .exit		; Return to BASIC
	push hl
	rst CALLBAS		; Feed INPUT
	defw 0x0F85
	pop hl
	inc hl
	jr .readdirloop

.exit
	pop hl			; restore stack
.exitnopop
	ld a, 0x0d		; BASIC expects this to end INPUT
	ld l, 0			; signal "munge the stack"
	scf
	jp F_leave

.checkformore
	dec b			; do what djnz would have done if it
	xor a			; had got to the end...
	cp b			; no more chars left?
	jr z, .cleardown
	inc l			; next byte in the buffer
	ld a, (hl)		; see what it is
	cp 0x0d
	jr z, .checklastcr
	cp 0x0a
	jr z, .checklastcr
.saveposition
	pop de			; fetch the metadata pointer
	ex de, hl		; into HL
	ld (hl), e		; save the current position
	inc l
	inc l
	inc l
	ld (hl), b		; save bytes remaining
	jr .exitnopop
.cleardown
	pop hl			; get the metadata ptr
	ld (hl), 0		; clear bufpos
	inc l
	inc l
	ld (hl), 0		; clear bufsz
	jr .exitnopop

.checklastcr
	dec b			; have we finally finished?
	xor a
	cp b
	jr z, .cleardown	; yes, just leave now.
	inc l			; otherwise advance the buffer
	jr .saveposition	; and save where we got to

.flush
	dec a			; make actual end position, not new char pos
	ld e, a			; make buffer LSB
	push hl
	call F_flushbuffer
	pop hl
	ret

.doinkey
	inc l
	ld a, (hl)		; get the socket
	ld (v_asave), a		; save it
	call POLLFD		; anything to receive?
	jr c, .readerr		; Read error?
	jr z, .nodata		; No hay nada

	ld a, (v_asave)		; get the fd back
	ld de, INTERPWKSPC
	ld bc, 1		; read one byte
	call RECV
	jr c, .readerr
	ld a, (INTERPWKSPC)
	ld l, 1			; signal "don't munge the stack"
	scf			; signal 'character available'
	ret
	
.nodata
	xor a			; carry and zero reset - no data
	ld l, 1			; signal "don't munge the stack"
	jp F_leave

.readerrpop
	pop hl			; fix the stack
.readerr			; TODO error handling
	ld hl, INTERPWKSPC
	call ITOH8
	ld hl, INTERPWKSPC
	call PRINT42
	or 1			; reset carry, reset zero: EOF
	ld l, 1			; signal "don't munge the stack"
	jp F_leave

;--------------------------------------------------------------------------
; F_ctrlstream
; Handle a control stream (read only) - at the moment, only listening
; sockets.
F_ctrlstream
	ld a, l			; convert the function
	and 0x0F		; number to the stream number
	rlca
	rlca
	rlca			; LSB of control stream metadata
	ld h, 0x10		; MSB of metadata
	add a, 4		; A=LSB of fd
	ld l, a
	ld a, (hl)		; get the socket descriptor
	
	call POLLFD		; Poll this fd and see if it's ready
	
	ld hl, ZX_TV_FLAG	; the mode is considered unchanged
	res 3, (hl)

	jr z, .nodata		; Socket has no events

	ld a, '1'		; indicate event
	ld l, 1			; signal "don't munge the stack"
	scf			; signal 'character available'
	ret
	
.nodata
	xor a			; carry and zero reset - no data
	ld l, 1			; signal "don't munge the stack"
	jp F_leave

