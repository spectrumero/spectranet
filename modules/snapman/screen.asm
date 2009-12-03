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
; F_makeselection
; HL = start address of box
; B = number of lines the box has
; C = maximum column number (32 cols)
; DE = address of first item to show
F_makeselection
	ld (v_selstart), hl	; save start address
	ld (v_maxcolumn), bc	; and save the num lines + end column
	push hl			; TODO: optimize
	push bc
	push de
	call F_bytesperline	; initialize line length
	call F_cleararea
	pop de
	pop bc
	pop hl
		
	ld a, l			; calculate start column
	and 0x1F		; by masking out top 3 bits
	ld (v_startcolumn), a	; save the start column
	ld b, a			; calculate number of 42-col characters
	ld a, c			; (end column in A)
	sub b			; number of 8 pixel columns
	dec a
	ld (v_barlen), a	; - this is needed later for the bar len
	inc a
	ld b, a			; save this
	sra a			; divide by four
	sra a
	add a, b		; and add to the number of 8 px columns
	inc a
	ld (v_42colsperln),a	; then save.
	ld a, l			; Initialize the position of the 42 col
	and 0xE0		; print routine to the top of the box.
	ld l, a
	ld (v_row), hl		; Spectranet sysvar
	xor a
	ld (v_selrow), a	; reset row counter
	ld (v_selecteditem), a	; reset selected item number

	ex de, hl		; get first item to print
	ld a, (v_sellines)	; number of lines we can fit
	ld b, a
.printloop
	ld e, (hl)		; low order of string lookup
	inc hl
	ld d, (hl)		; high order of string lookup
	inc hl
	ld a, d
	or e			; is it zero?
	jr z, .doneprinting
	ex de, hl		; move string's address to HL
	push de			; save string pointer table address
	push bc			; save counter
	call F_cprint		; print the string
	pop bc
	pop de
	ex de, hl
	djnz .printloop
.doneprinting

	ld hl, (v_selstart)	; initialize the selection bar
	call F_fbuf2attr	; find address of attr cell
	ld (v_baraddr), hl
	xor a			; initialize bar position
	ld (v_barpos), a
	call F_putbar
	call F_inputloop
	ret

;------------------------------------------------------------------------
; F_

;------------------------------------------------------------------------
; F_cprint
; Constrained print routine. Print from the start column to the maximum
; column or until NULL, whichever is earliest.
; HL = pointer to string
F_cprint
	xor a
	ld (v_rowcount), a	; prevent 42 col routine scroll
	ld a, (v_startcolumn)	; get the 32 column position and
	ld b, a			; convert it to a 42 column start
	sra a
	sra a
	inc a
	add a, b
	ld (v_column), a	; set Spectranet 42 col print routine col
	ld b, 0
.loop
	ld a, (hl)
	and a
	jr z, .cr
	call PUTCHAR42
	inc hl
	inc b			; increment 'columns printed so far'
	ld a, (v_42colsperln)
	cp b			; reached the limit?
	jr nz, .loop
.cr
	ld a, '\n'
	call PUTCHAR42
	ret

;------------------------------------------------------------------------
; F_bytesperline
; Calculates bytes per line. HL = start address of the line.
F_bytesperline
	push bc
	ld a, l
	and 0x1F
	ld b, a
	ld a, (v_maxcolumn)
	sub b
	ld (v_movebytes), a	; store it as a 2 byte value
	xor a			; so it can be loaded into BC
	ld (v_movebytes+1), a	; in one go for LDIR.
	pop bc
	ret

;------------------------------------------------------------------------
; F_scrollarea
; Scroll an area of the screen.
; HL = pointer to first line to scroll
; B = number of lines to scroll
; C = 0 = scroll normal way, nonzero scroll reverse
F_scrollforward
	push bc			; save counter
	call .advance		; advance one line (need to scroll
	push hl			; box size minus 1)
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
	call .advance
	push hl
	jr nz, .moveloop

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

.advance
        ld a, l
        and 0xE0
        cp 0xE0                 ; about to go into the next third?
        jr z, .nnextthird
        ld a, 32
        add a, l                ; next line
        ld l, a
        ld b, 8                 ; number of iterations per line
	ret
.nnextthird
        ld a, l
        and 0x1F                ; clear 3 most significant bits
        ld l, a                 ; set LSB of pointer
        ld a, h
        add 8
        ld h, a                 ; set MSB of pointer
        ld b, 8                 ; move 8 lines
	xor a
	ret

F_scrollreverse	
	dec b
	push bc
	call .retreat		; up one line, scroll box size - 1
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
	call .retreat
	push hl	
	jr nz, .moveloop

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

.retreat
        ld a, l                 ; about to cross a third boundary?
        and 0xE0
        jr z, .nextthird
        ld a, l
        sub 32                  ; move up a line
        ld l, a
        ld b, 8
	ret
.nextthird
        ld a, l
        or 0xE0                 ; set top 3 bits of the pointer
        ld l, a                 ; set LSB of pointer
        ld a, h
        sub 8
        ld h, a                 ; set MSB of pointer
        ld b, 8                 ; move 8 lines
	xor a			; zero flag set
	ret

;--------------------------------------------------------------------------
; F_cleararea: Clears a defined area.
; HL = Start address
; B = Number of lines to clear
F_cleararea
	push bc			; save counter
	push hl
	ld b, 8			; clear 8 scanlines
.clearloop
	push bc			; save line counter
	ld d, h			 
	ld e, l
	inc e
	push hl
	ld bc, (v_movebytes)
	dec bc
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
	jr z, .savelastline	; all lines cleared

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

.savelastline
	ld (v_selend), hl	; save the bottom row address
	ret

;------------------------------------------------------------------------
; F_clearline
; Clears a line. HL = start address.
F_clearline
	ld b, 8
.clearloop
	push bc
	ld d, h
	ld e, l
	inc e
	push hl
	ld bc, (v_movebytes)
	dec bc
	xor a
	ld (hl), a
	ldir
	pop hl
	inc h
	pop bc
	djnz .clearloop
	ret

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
F_putbar_impl
	ld d, h
	ld e, l
	inc e
	ld a, (v_barlen)
	ld c, a
	ld b, 0
	ld (hl), SELECTED_ATTR	; Colour to draw
	ldir
	ret

;------------------------------------------------------------------------
; F_putbar
; Draws the bar at the current start address.
F_putbar
	ld hl, (v_baraddr)
	ld a, (v_barlen)
	jp F_putbar_impl

;------------------------------------------------------------------------
; F_fbuf2attr
; Convert pixel buffer addresses to attribute addresses
F_fbuf2attr
	ld a, l			; get LSB of frame buffer address
	and 0xE0		; mask out bottom bits
	rlca			; and move to lowest 3 bits
	rlca
	rlca
	ld e, a			; store in low order of DE
	ld a, h			; high order - 0x40, 0x48 or 0x50
	sub 0x40		; now 0x00, 0x08 or 0x10
	add a, e		; and add the current third-of-a-row
	ld e, a			; and store in the low order of DE
	ld d, 0			; zero the high order
	ex de, hl
	add hl, hl		; multiply by 32...2
	add hl, hl		; 4
	add hl, hl		; 8
	add hl, hl		; 16
	add hl, hl		; 32
	ld a, e			; now derive the column
	and 0x1F
	add a, l		; add it to the offset that was calculated
	ld l, a			; now HL = offset
	ld de, ATTR_BASE
	add hl, de		; and create the address
	ret

;------------------------------------------------------------------------
; F_inputloop
; Deal with keyboard input.
F_inputloop
.inputloop
	call GETKEY		; get the actual key
	push af			; save it
	call KEYUP		; and wait for keyup
	pop af
	cp 0x0A			; KEY_DOWN
	jr z, .bardown
	cp 0x0B			; KEY_UP
	jr z, .barup
	ret
.bardown
	ld a, (v_sellines)	; hit the bottom?
	dec a			; convert to 'index'
	ld b, a
	ld a, (v_barpos)
	cp b
	jr z, .scrolldown
	inc a
	ld (v_barpos), a	; update position
	ld a, (v_selecteditem)	; increment the selected item index
	inc a
	ld (v_selecteditem), a
	xor a
	call F_movebar
	jr .inputloop
.barup
	ld a, (v_barpos)
	and a
	jr z, .scrollup
	dec a
	ld (v_barpos), a
	ld a, (v_selecteditem)	; decrement the selected item index
	dec a
	ld (v_selecteditem), a
	inc a			; ensure A is nonzero
	call F_movebar
	jr .inputloop


.scrolldown
	ld a, (v_lastitemidx)	
	ld b, a			; compare the last item index
	ld a, (v_selecteditem)	; with the current
	cp b
	jr z, .inputloop	; already at the last item
	ld a, (v_selecteditem)	; Increment the selected item index.
	inc a
	ld (v_selecteditem), a
	rlca			; double it to calculate
	ld d, 0			; the pointer table address
	ld e, a		
	ld hl, (v_stringtable)	; get the string table start address
	add hl, de		; and calculate the current pointer
	ld e, (hl)		; load the pointer into DE
	inc hl
	ld d, (hl)
	push de			; save the pointer itself
	ld hl, (v_selstart)	; scroll the box
	ld a, (v_sellines)
	ld b, a
	call F_scrollforward

	ld hl, (v_selend)	; get end address
	call F_clearline	; clear the line in preparation for new text
	ld hl, (v_selend)
	ld a, l
	and 0xE0		; mask out bottom bits
	ld l, a
	ld (v_row), hl		; set print routine to bottom line row
	pop hl			; now get the string back
	call F_cprint
	jp .inputloop

.scrollup
	ld a, (v_selecteditem)	; check we've not hit zero
	and a
	jp z, .inputloop
	dec a
	ld (v_selecteditem), a	; update the selected item
	ld hl, (v_stringtable)	; string table start address
	rlca			; double A
	ld d, 0
	ld e, a
	add hl, de		; calculate current top string pointer
	ld e, (hl)
	inc hl
	ld d, (hl)
	push de			; save the string pointer
	ld hl, (v_selend)	; bottom line of the selection box
	ld a, (v_sellines)
	ld b, a
	call F_scrollreverse	; scroll up a line
	
	ld hl, (v_selstart)	; get top line address
	call F_clearline
	ld hl, (v_selstart)	; and again to set the print routine
	ld a, l
	and 0xE0		; mask out bottom 5 bits
	ld l, a
	ld (v_row), hl		; set the print routine's row address
	pop hl			; get the string pointer
	call F_cprint
	jp .inputloop

