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

; Buffer management routines.
; Note - the memory we want to use should be paged into area A.


;---------------------------------------------------------------------------
; Dealing with buffers
; Buffers start from 0x1100, with a 256 byte buffer for each possible
; stream.
; At 0x1000 there is buffer information which is formatted as follows:
; Byte 0 - Write buffer number
; Byte 1 - Read buffer number
; byte 2 - Write buffer pointer
; byte 3 - read buffer pointer
; Byte 4 - Current descriptor (a socket handle, perhaps)
; Byte 5-7 - Data specific to the kind of stream:
; Byte 5 - Flag bits (bit 0 = socket or file)

;--------------------------------------------------------------------------
; F_findfreebuf - Returns the number of the first free buffer found.
; Carry set if no buffer available.
F_findfreebuf
	push hl
	ld b, 0x1F		; number of buffers available
.findloop
	ld hl, 0x1000		; address to start from in metadata page
.next
	ld a, (hl)
	cp b
	jr z, .inuse
	inc l			; check second buffer
	ld a, (hl)
	cp b
	jr z, .inuse
	ld a, 7			; advance by 7 bytes
	add a, l
	jr z, .free		; this buffer number wasn't found, it's free
	ld l, a
	jr .next
.inuse
	djnz .findloop		; try the next buffer number
	pop hl
	scf			; we ran out of attempts
	ret
.free
	pop hl
	ld a, b			; get result into A
	and a			; clear possible carry (from the add op)
	ret

;---------------------------------------------------------------------------
; F_feedbuffer
; Adds the byte in A to the buffer for the stream in L
F_feedbuffer
        ex af, af'              ; save A
        ld a, l                 ; calculate buffer offset
        and 0x0F                ; mask out any flags in the top nibble

        rlca                    ; multiply by 8 to find the stream data
        rlca
        rlca
        ld h, 0x10              ; MSB = 0x10
	add 5			; first check the flags bit
        ld l, a                 ; HL = info pointer

	bit BIT_RDONLY, (hl)	; if read only do nothing
	ret nz
	sub 5
	ld l, a			;:point hl at the start of the info block
        ld d, (hl)              ; D = buffer number (happens to be the MSB)
        inc l
        inc l                   ; advance to write buffer pointer
        ld e, (hl)              ; DE = current buffer pointer
        ex af, af'              ; get byte back
        cp 0x0d                 ; Spectrum ENTER?
        jr nz, .cont

        ld (de), a              ; Convert it to 0x0d 0x0a
        inc e
        ld a, 0x0a
        ld (de), a
        jr F_flushbuffer
.cont
        ld (de), a              ; write the value into the buffer
        ld a, 0xFE              ; it would be easier to flush one byte later
        cp e                    ; but we must leave enough room for CRLF
        jr z, F_flushbuffer     ; If the buffer is full flush it

        inc e                   ; increment the buffer pointer
        ld (hl), e              ; save the buffer pointer
        ret

;---------------------------------------------------------------------------
; F_flushbuffer
; Flushes the given buffer
;       DE = current buffer pointer
;       HL = current buffer info pointer (points at the bufptr storage,
;               i.e. metadata base address + 2) 
F_flushbuffer
        ; TODO
        ; This needs to work with all kinds of streams, not just SOCK_STREAM
        ld (hl), 0              ; reset buffer pointer
        inc l                   ; point at descriptor (advance past read
        inc l                   ; buffer pointer)
        ld a, (hl)              ; and get it

        ld b, 0                 ; set BC to the size of the buffer to send
        ld c, e                 ; inc BC to make the proper length
        inc bc
        ld e, 0                 ; set DE to the start of the buffer

        ; DE now = buffer start
        ; BC now = length
        ; A now = file descriptor
	inc l
	bit 0, (hl)		; Check "is a file" flag
	jr nz, .filewrite
        call SEND               ; Send the data
        jr c, .borked
        ret

.borked
        ld a, 2                 ; todo - proper error handling
        out (254), a
        ret

.filewrite
	; TODO: File I/O does not yet handle writing a buffer in page A
	; because that's where the VFS mods put their data. So copy the
	; data first. However, VFS modules ought to be able to cope with
	; this.
	ex de, hl
	ld de, INTERPWKSPC	; where to copy
	push bc
	ldir			; copy the buffer
	pop bc			; restore the length
	ld hl, INTERPWKSPC	; start of new buffer
	call WRITE
	jr c, .borked
	ret

