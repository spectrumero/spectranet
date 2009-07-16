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
	ld l, a
	ld h, 0x10		; point HL at metadata
	ld a, (hl)		; get buffer pointer
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
	jr nz, .doinkey

.input
	inc l			; point at socket descriptor
	ld a, (hl)		; fetch it
	ld (v_asave), a		; save it for the loop operation
	inc l			; Test whether we need to unload more
	push hl			; save the pointer
	ld a, (hl)		; data from the buffer
	and a			; Input buffer pos = 0?
	jr z, .getdata		; Nothing remaining, get the data.
	
	inc l			; Get the bytes remaining
	ld b, (hl)		; parameter.
	ld h, INTERPWKSPC / 256 ; MSB of buffer
	ld l, a			; LSB of buffer
	jr .unloadloop

.getdata
	ld a, (v_asave)		; Get the descriptor
	ld de, INTERPWKSPC
	ld bc, 255		; read up to 255 chars
	call RECV
	jr c, .readerr

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
	ld (hl), b		; save bytes remaining
	jr .exitnopop
.cleardown
	pop hl			; get the metadata ptr
	ld (hl), 0		; clear bufpos
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
	ld a, c			; retrieve stream number
	or 0x10			; make buffer MSB
	ld d, a
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

.readerr			; TODO error handling
	ld hl, INTERPWKSPC
	call ITOH8
	ld hl, INTERPWKSPC
	call PRINT42
	or 1			; reset carry, reset zero: EOF
	ld l, 1			; signal "don't munge the stack"
	jp F_leave

F_debugA
	push de
	push bc
	push af
	ld hl, INTERPWKSPC
	call ITOH8
	ld hl, INTERPWKSPC
	call PRINT42
	pop af
	pop bc
	pop de
	ret


;---------------------------------------------------------------------------
; Dealing with buffers
; Buffers start from 0x1100, with a 256 byte buffer for each possible
; stream.
; At 0x1000 there is buffer information which is formatted as follows:
; Byte 0 - Current buffer pointer
; Byte 1 - Current descriptor (a socket handle, perhaps)
; Byte 2,3 - Data specific to the kind of stream

;---------------------------------------------------------------------------
; F_feedbuffer
; Adds the byte in A to the buffer for the stream in L
F_feedbuffer
	ex af, af'		; save A
	ld a, l			; calculate buffer offset
	and 0x0F		; mask out any flags in the top nibble
	ld c, a			; save this value
	or 0x10			; now form the MSB
	ld d, a			; and put it in the MSB of DE

	ld a, c			; get the buffer number back
	rlca			; multiply by 4 to find the buffer pointer
	rlca
	ld h, 0x10		; MSB = 0x10
	ld l, a			; HL = buffer pointer
	ld e, (hl)		; DE now is the full buffer pointer
	ex af, af'		; get byte back
	cp 0x0d			; Spectrum ENTER?
	jr nz, .cont

	ld (de), a		; Convert it to 0x0d 0x0a
	inc e
	ld a, 0x0a
	ld (de), a
	jr F_flushbuffer
.cont
	ld (de), a		; write the value into the buffer
	ld a, 0xFE		; it would be easier to flush one byte later
	cp e			; but we must leave enough room for CRLF
	jr z, F_flushbuffer	; If the buffer is full flush it

	inc e			; increment the buffer pointer
	ld (hl), e		; save the buffer pointer
	ret

;---------------------------------------------------------------------------
; F_flushbuffer
; Flushes the given buffer
;	DE = current buffer pointer
;	HL = current buffer info pointer (points at the bufptr storage) 
F_flushbuffer
	; TODO
	; This needs to work with all kinds of streams, not just SOCK_STREAM
	ld (hl), 0		; reset buffer pointer
	inc l			; point at descriptor
	ld a, (hl)		; and get it

	ld b, 0			; set BC to the size of the buffer to send
	ld c, e			; inc BC to make the proper length
	inc bc
	ld e, 0			; set DE to the start of the buffer

	; DE now = buffer start
	; BC now = length
	; A now = file descriptor
	call SEND		; Send the data
	jr c, .borked
	ret
	
.borked
	ld a, 2			; todo - proper error handling
	out (254), a
	ret

