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

;------------------------------------------------------------------------
; F_scrollarea
; Scroll an area of the screen.
; HL = pointer to first line to scroll
; B = number of lines to scroll
; C = 0 = scroll normal way, nonzero scroll reverse
F_scrollarea
	push bc			; save counter
	ld a, l			; Get value of L to calculate bytes to move..
	and 0x1F		; Mask away top few bits
	ld b, a			; save it in B...
	ld a, (v_maxcolumn)	
	sub b			; and calculate value.
	ld (v_movebytes), a
	xor a
	ld (v_movebytes+1), a
	cp c			; forward/reverse?
	jr nz, F_scrollreverse

	ld a, l			; moving across thirds?
	and 0xE0		; if so none of the top 3 bits are set
	ld b, 8			; number of iterations
	push hl
	jr z, .moveloopthird
.moveloop
	push bc			; save line counter
	ld a, l
	sub 32			; address of next line up
	ld d, h			 
	ld e, a 
	push hl
	ld bc, (v_movebytes)
	ldir
	pop hl
	inc h
	pop bc
	djnz .moveloop
.nextline
	pop hl
	pop af			; get counter
	dec a
	ret z			; all lines scrolled

	push af			; save counter
	ld a, l
	and 0xE0
	cp 0xE0			; about to go into the next third?
	jr z, .nextthird
	ld a, 32
	add a, l		; next line
	ld l, a
	push hl
	ld b, 8			; number of iterations per line
	jr .moveloop

.nextthird
	ld a, l
	and 0x1F		; clear 3 most significant bits
	ld l, a			; set LSB of pointer
	ld a, h
	add 8
	ld h, a			; set MSB of pointer
	push hl			; save HL
	ld b, 8			; move 8 lines
.moveloopthird
	push bc
	ld a, l
	or 0xE0			; set top 3 bits of LSB
	ld e, a
	ld a, h
	sub 0x08		; subtract 8 from MSB
	ld d, a			; DE now equals address of prev row
	push hl
	ld bc, (v_movebytes)
	ldir
	pop hl
	inc h
	pop bc
	djnz .moveloopthird
	jr .nextline

F_scrollreverse	
	ld a, l			; starting with a 3rd boundary?
	and 0xE0		; if so all of the top 3 bits are
	cp 0xE0			; set
	ld b, 8			; number of iterations
	push hl
	jr z, .nextthird
.moveloop
	push bc
	ld a, 32
	add a, l		; calculate next line
	ld e, a
	ld d, h			; de is now pointer to next line
	push hl
	ld bc, (v_movebytes)
	ldir
	pop hl
	inc h
	pop bc
	djnz .moveloop	
.nextline
	pop hl
	pop af
	dec a			; decrement line counter
	ret z			; and leave if we've finished all lines

	push af			; store counter
	ld a, l			; about to cross a third boundary?
	and 0xE0
	jr z, .nextthird
	ld a, l
	sub 32			; move up a line
	ld l, a
	push hl	
	ld b, 8
	jr .moveloop

.nextthird
	ld a, l
	or 0xE0			; set top 3 bits of the pointer
	ld l, a			; set LSB of pointer
	ld a, h
	sub 8
	ld h, a			; set MSB of pointer
	push hl			; save HL
	ld b, 8			; move 8 lines
.moveloopthird
	push bc
	ld a, l
	and 0x1F		; clear 3 bits of LSB
	ld e, a
	ld a, h
	add 0x08		; add 0x08 to the MSB of copy to pointer
	ld d, a			; DE now equals address of next row
	push hl
	ld bc, (v_movebytes)
	ldir
	pop hl
	inc h
	pop bc
	djnz .moveloopthird
	jr .nextline

;--------------------------------------------------------------------------
; F_cleararea: Clears a defined area.
; HL = Start address
; B = Number of lines to clear
F_cleararea
	push bc			; save counter
	ld a, l			; Get value of L to calculate bytes to move..
	and 0x1F		; Mask away top few bits
	ld b, a			; save it in B...
	ld a, (v_maxcolumn)	
	sub b			; and calculate value
	dec a			; minus 1
	ld (v_movebytes), a
	xor a
	ld (v_movebytes+1), a
	push hl
	ld b, 8			; clear 8 scanlines
.clearloop
	push bc			; save line counter
	ld d, h			 
	ld e, l
	inc e
	push hl
	ld bc, (v_movebytes)
	xor a
	ld (hl), a
	ldir
	pop hl
	inc h
	pop bc			; retrieve counter
	djnz .clearloop
.nextline
	pop hl
	pop af			; get counter
	dec a
	ret z			; all lines cleared

	push af			; save counter
	ld a, l
	and 0xE0
	cp 0xE0			; about to go into the next third?
	jr z, .nextthird
	ld a, 32
	add a, l		; next line
	ld l, a
	push hl
	ld b, 8			; number of iterations per line
	jr .clearloop

.nextthird
	ld a, l
	and 0x1F		; clear 3 most significant bits
	ld l, a			; set LSB of pointer
	ld a, h
	add 8
	ld h, a			; set MSB of pointer
	push hl			; save HL
	ld b, 8			; move 8 lines
	jr .clearloop

;------------------------------------------------------------------------
; F_movebar
; Moves selection bar down.
; A = 0 - move bar down
; Otherwise, it moves up.
F_movebar
	push af
	ld hl, (v_baraddr)	; current start address of bar
	ld a, (v_barlen)	; how long the bar is
	ld b, 0
	ld c, a
	ld d, h
	ld e, l
	inc e
	push hl
	ld (hl), NORMAL_ATTR	; Clear current line to normal attr colour
	ldir
	pop hl
	ld de, 32		; Next row
	pop af
	and a			; Is A = 0?
	jr z, .down
	sbc hl, de
	jr .move
.down
	add hl, de
.move
	ld (v_baraddr), hl	; Save the new row pointer
	ld d, h
	ld e, l
	inc e
	ld a, (v_barlen)
	ld c, a
	ld b, 0
	ld (hl), SELECTED_ATTR	; Colour to draw
	ldir
	ret

