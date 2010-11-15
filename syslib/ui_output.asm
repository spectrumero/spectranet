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
.include	"sysvars.inc"
.include	"ctrlchars.inc"

; User interface output routines
; This is mostly about putting characters on the screen, and clearing the
; screen to the Spectranet UI colours. It doesn't depend on the ZX ROM.
; The print routine prints 42 columns wide.

;--------------------------------------------------------------------------
; F_putc_5by8 
; Print characters 42 columns per line.
; The 'core' of the putchar routine, F_print calls this directly (handling
; the paging itself)
; The routine could probably do with improvement.
.text
.globl F_putc_5by8_impl
F_putc_5by8_impl:
      	push hl
	push bc
	push de
	ld h, a			; save character
	ld a, (v_utf8)		; check UTF-8 state
	and a			; if nonzero, process it
	jp nz, .map_utf81
	ld a, h			; restore character

	cp NEWLINE	     ; carriage return?
	jr z, .nextrow1

	cp 0xC1			; utf-8 character that we support
	jp nc, .utf81		; which is 0xC2 and higher

	; find the address of the character in the bitmap table
	sub 32      		; space = offset 0
	ld l, a
.utf8_continue1:			; we return here from the utf8 map subroutine
	ld h, 0

	; multiply by 8 to get the byte offset
	add hl, hl
	add hl, hl
	add hl, hl

	; add the offset
	ld bc, CHARSET
	add hl, bc

	; Now find the address in the frame buffer to be written.
	ex de, hl
	ld hl, col_lookup
	ld a, (v_column)
	ld b, a
	add a, l
	ld l, a        ; hl = pointer to byte in lookup table
	ld a, (hl)     ; a = lookup table value
	ld hl, (v_row) ; hl = framebuffer pointer for start of row
	add a,l
	ld l, a        ; hl = frame buffer address

; de contains the address of the char bitmap
; hl contains address in the frame buffer
.paintchar1:
	ld a, b           ; retrieve column
	and 3             ; find out how much we need to rotate
	jr z, .norotate1   ; no need to rotate, character starts at MSB
	rla               ; multipy by 2
	ld (v_pr_wkspc), a   ; save A
	ld b, 8           ; byte copy count for outer loop
.fbwriterotated1:
	push bc           ; save outer loop count
	ld a, (v_pr_wkspc)
	ld b, a           ; set up rotate loop count
	ld a, (de)        ; get character bitmap
	ld c, a           ; C contains rightmost fragment of bitmap
	xor a             ; set a=0 to accept lefmost fragment of bitmap
.rotloop1:
	rl c             
	rla               ; suck out leftmost bit from the carry flag 
	djnz .rotloop1
.writerotated1:
	or (hl)           ; merge with existing character
	ld (hl), a
	ld a, c
	cp 0
	jr z, .writerotated1_skip1   ; nothing to do
	inc l             ; next char cell
	or (hl)
	ld (hl), a
	dec l             ; restore l
.writerotated1_skip1:
	inc h             ; next line
	inc de            ; next line of character bitmap
	pop bc            ; retrieve outer loop count
	djnz .fbwriterotated1
.nextchar1:
	ld a, (v_column)
	inc a
	cp 42
	jr nz, .nextchar1_done1
.nextrow1:      
	ld a, (v_rowcount) ; check the row counter
	cp 23		; 24th line?
	jr nz, .noscroll1
	call F_jumpscroll_impl
	ld a, 16
	ld (v_rowcount), a
	ld hl, 0x5000     ; address of first row of bottom 1/3rd
	jr .nextchar1_saverow1 ; save row addr and complete
.noscroll1:
	inc a
	ld (v_rowcount), a
	ld hl, (v_row)    ; advance framebuffer pointer to next character row
	ld a, l
	add a, 32
	jr c, .nextthird1
	ld l, a
	jr .nextchar1_saverow1
.nextthird1:
	ld l, 0
	ld a, h
	add a, 8
	ld h, a
.nextchar1_saverow1:
	ld (v_row), hl
	xor a             ; a = 0
.nextchar1_done1:
	ld (v_column), a
.leave1:
	pop de
	pop bc
	pop hl
	ret

.norotate1:
	ld b, 8
.norotate1_loop1:
	ld a, (de)        ; move bitmap into the frame buffer
	ld (hl), a
	inc de            ; next line of bitmap
	inc h             ; next line of frame buffer
	djnz .norotate1_loop1
	jr .nextchar1

	; Support for a subset of utf-8 - a few of the 0xC2 characters
	; (€, ¡ and ¿) and all of the 0xC3 characters (mostly accented
	; chars and the Spanish ñ character)
.utf81:
	cp 0xC3		; 0xC3 chars need no translation
	jr z, .leave1	
	ld (v_utf8), a	; else set the UTF8 variable to the byte passed
	jr .leave1

.map_utf81:
	xor a		; reset UTF8 state
	ld (v_utf8), a
	ld a, h		; get char
	cp 0x80		; euro
	ld l, CHARSET_C2_DIST
	jp z, .utf8_continue1
	cp 0xA1		; ¡
	ld l, CHARSET_INVPLING_DIST
	jp z, .utf8_continue1
	cp 0xA2		; cent
	inc l
	jp z, .utf8_continue1
	ld l, CHARSET_INVQUEST_DIST
	jp .utf8_continue1

;--------------------------------------------------------------------------
; F_jumpscroll:
; a simple 'jump scroll' which scrolls the screen by 1/3rd. Simpler
; than scrolling one line.
.globl F_jumpscroll_impl
F_jumpscroll_impl:
	push hl
	push de
	push bc
	ld hl, 0x4800	; start of 2nd 1/3rd of screen
	ld de, 0x4000	; first third
	ld bc, 0x1000	; copy 2/3rds of the screen up by 1/3rd
	ldir
	ld hl, 0x5000	; clear out last 2k
	ld de, 0x5001
	ld bc, 0x07FF
	ld (hl), 0
	ldir
	pop bc
	pop de
	pop hl	
	ret

;-------------------------------------------------------------------------
; F_erasechar
; Removes the character at the current 5by8 character position.
; No parameters.
.globl F_erasechar_impl
F_erasechar_impl:
	; Find the address in the frame buffer.
	ld hl, col_lookup

	ld a, (v_column)
	ld b, a
	add a, l
	ld l, a		; hl = pointer to byte in lookup table
	ld a, (hl)	; a = lookup table value
	ld hl, (v_row)	; hl = framebuffer pointer for start of row
	add a, l
	ld l, a		; hl = frame buffer address
	ld a, b		; retrieve column
	and 3		; find out how much rotation is needed
	jr z, .norotate3	; no need to do any at all

	rla		; multiply by 2
	ld b, a		; set loop count
	ld a, 0xFC	; binary 11111100 - mask with no rotation

	; now create two masks - one for the left byte, and one for the
	; right byte.
	ld c, 0		; c will contain left mask
.maskloop3:
	rla
	rl c
	djnz .maskloop3
.rotated3:
	cpl		; turn it into the proper mask value
	ld (v_pr_wkspc), a	; save right byte mask
	ld b, 8		; 8 bytes high
.rotated_loop3:
	inc l		; right hand byte
	and (hl)	; make new value
	ld (hl), a	; write it back
	ld a, c		; get left mask
	cpl
	dec l		; point at left byte
	and (hl)
	ld (hl), a	; write it back
	inc h		; next line in frame buffer
	ld a, (v_pr_wkspc)	; retrieve right byte mask
	djnz .rotated_loop3
	ret		; done

.norotate3:
	ld b, 8		; 8 bytes high
.norotate_loop3:
	ld a, 0x03	; mask out left 6 bits
	and (hl)	; mask out character cell at current position
	ld (hl), a	; write back to frame buffer
	inc h
	djnz .norotate_loop3
	ret		; done

;--------------------------------------------------------------------------
; F_backspace: Perform a backspace (move current character position 1
; back and delete the right most character).
.globl F_backspace_impl
F_backspace_impl:
	ld a, (v_column)
	and a		; Are we at column 0?
	ret z		; nothing more to do (possible TODO - go back a line)
	dec a		; move column pointer one space back
	ld (v_column), a ; and store it
	jp F_erasechar_impl	; then erase the character that's there.
	
;--------------------------------------------------------------------------
; F_clear: Clears the screen to spectranet UI colours.
.globl F_clear_impl
F_clear_impl:
	ld a, 1
	out (254), a	; border
	ld hl, 16384
	ld de, 16385
	ld bc, 6144
	ld (hl), l
	ldir
	ld (hl), 15	; blue/white
	ld bc, 767
	ldir
	xor a
	ld (v_column), a
	ld (v_rowcount), a
	ld hl, 16384
	ld (v_row), hl
	ret

