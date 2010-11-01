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
.include	"ctrlchars.inc"
.include	"spectranet.inc"
.include	"snapman.inc"
.include	"sysvars.inc"

;------------------------------------------------------------------------
; F_makeselection
; HL = start address of box
; B = number of lines the box has
; C = maximum column number (32 cols)
; DE = address of first item to show
.globl F_makeselection
F_makeselection: 
	ld (v_selstart), hl	; initialize variables
	ld (v_maxcolumn), bc	
	ld (v_stringtable), de
	ld (v_numitems), a

	call F_bytesperline	; initialize line length
		
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
.globl F_reinitselection
F_reinitselection: 
	call F_clearattrs
	call F_cleararea	; clear the box
	ld hl, (v_selstart)
	ld de, (v_stringtable)
	call F_puttext		; Fill the box with text.

	xor a
	ld (v_selrow), a	; reset row counter
	ld (v_selecteditem), a	; reset selected item number

	ld hl, (v_selstart)	; initialize the selection bar
	call F_fbuf2attr	; find address of attr cell
	ld (v_baraddr), hl	; initialize selection bar vars
	ld (v_barstart), hl
	xor a			; initialize bar position
	ld (v_barpos), a
	call F_putbar
	call F_findstr		; is the current filename in the box?
	ret nc			; no
	call F_setbarloc	; (TODO: Refine so that we can go direct
	ret			; to the location)

;------------------------------------------------------------------------
; F_cprint
; Constrained print routine. Print from the start column to the maximum
; column or until NULL, whichever is earliest.
; HL = pointer to string
.globl F_cprint
F_cprint: 
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
.loop3: 
	ld a, (hl)
	and a
	jr z,  .cr3
	call PUTCHAR42
	inc hl
	inc b			; increment 'columns printed so far'
	ld a, (v_42colsperln)
	cp b			; reached the limit?
	jr nz,  .loop3
.cr3: 
	ld a, NEWLINE
	call PUTCHAR42
	ret

;------------------------------------------------------------------------
; F_bytesperline
; Calculates bytes per line. HL = start address of the line.
.globl F_bytesperline
F_bytesperline: 
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
.globl F_scrollforward
F_scrollforward: 
	push bc			; save counter
	call  .advance5		; advance one line (need to scroll
	push hl			; box size minus 1)
	jr z,  .moveloopthird5
.moveloop5: 
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
	djnz  .moveloop5
.nextline5: 
	pop hl
	pop af			; get counter
	dec a
	ret z			; all lines scrolled

	push af			; save counter
	call  .advance5
	push hl
	jr nz,  .moveloop5

.moveloopthird5: 
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
	djnz  .moveloopthird5
	jr  .nextline5

.advance5: 
        ld a, l
        and 0xE0
        cp 0xE0                 ; about to go into the next third?
        jr z,  .nnextthird5
        ld a, 32
        add a, l                ; next line
        ld l, a
        ld b, 8                 ; number of iterations per line
	ret
.nnextthird5: 
        ld a, l
        and 0x1F                ; clear 3 most significant bits
        ld l, a                 ; set LSB of pointer
        ld a, h
        add a, 8
        ld h, a                 ; set MSB of pointer
        ld b, 8                 ; move 8 lines
	xor a
	ret

.globl F_scrollreverse
F_scrollreverse: 
	dec b
	push bc
	call  .retreat6		; up one line, scroll box size - 1
	push hl
	jr z,  .nextthird6
.moveloop6: 
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
	djnz  .moveloop6	
.nextline6: 
	pop hl
	pop af
	dec a			; decrement line counter
	ret z			; and leave if we've finished all lines

	push af			; store counter
	call  .retreat6
	push hl	
	jr nz,  .moveloop6

.moveloopthird6: 
	push bc
	ld a, l
	and 0x1F		; clear 3 bits of LSB
	ld e, a
	ld a, h
	add a, 0x08		; add 0x08 to the MSB of copy to pointer
	ld d, a			; DE now equals address of next row
	push hl
	ld bc, (v_movebytes)
	ldir
	pop hl
	inc h
	pop bc
	djnz  .moveloopthird6
	jr  .nextline6

.retreat6: 
        ld a, l                 ; about to cross a third boundary?
        and 0xE0
        jr z,  .nextthird6
        ld a, l
        sub 32                  ; move up a line
        ld l, a
        ld b, 8
	ret
.nextthird6: 
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
.globl F_cleararea
F_cleararea: 
	ld hl, (v_selstart)	; start of area
	ld bc, (v_maxcolumn)	; counter into B
	push bc			; save counter
	push hl
	ld b, 8			; clear 8 scanlines
.clearloop7: 
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
	djnz  .clearloop7
.nextline7: 
	pop hl
	pop af			; get counter
	dec a
	jr z,  .savelastline7	; all lines cleared

	push af			; save counter
	ld a, l
	and 0xE0
	cp 0xE0			; about to go into the next third?
	jr z,  .nextthird7
	ld a, 32
	add a, l		; next line
	ld l, a
	push hl
	ld b, 8			; number of iterations per line
	jr  .clearloop7

.nextthird7: 
	ld a, l
	and 0x1F		; clear 3 most significant bits
	ld l, a			; set LSB of pointer
	ld a, h
	add a, 8
	ld h, a			; set MSB of pointer
	push hl			; save HL
	ld b, 8			; move 8 lines
	jr  .clearloop7

.savelastline7: 
	ld (v_selend), hl	; save the bottom row address
	ret

;------------------------------------------------------------------------
; F_clearline
; Clears a line. HL = start address.
.globl F_clearline
F_clearline: 
	ld bc, (v_movebytes)	; put current box width in

; ...clears a line BC bytes long.
.globl F_clearline2
F_clearline2: 
	ld (v_clearbytes), bc	; our "how much to clear" var.
	ld b, 8
.clearloop9: 
	push bc
	ld d, h
	ld e, l
	inc e
	push hl
	ld bc, (v_clearbytes)
	dec bc
	xor a
	ld (hl), a
	ldir
	pop hl
	inc h
	pop bc
	djnz  .clearloop9
	ret

;------------------------------------------------------------------------
; F_movebar
; Moves selection bar down.
; A = 0 - move bar down
; Otherwise, it moves up.
.globl F_movebar
F_movebar: 
	call F_clearbar
	ld de, 32		; Next row
	and a			; Is A = 0?
	jr z,  .down10
	sbc hl, de
	jr  .move10
.down10: 
	add hl, de
.move10: 
	ld (v_baraddr), hl	; Save the new row pointer
.globl F_putbar_impl
F_putbar_impl: 
	ld d, h
	ld e, l
	inc e
	ld a, (v_barlen)
	ld c, a
	ld b, 0
	ld (hl), SELECTED_ATTR	; Colour to draw
	ldir
	ret
.globl F_clearbar
F_clearbar: 
	ld hl, (v_baraddr)	; current start address of bar
.globl F_clearbar2
F_clearbar2: 
	push af
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
	pop af
	ret

;------------------------------------------------------------------------
; F_putbar
; Draws the bar at the current start address.
.globl F_putbar
F_putbar: 
	ld hl, (v_baraddr)
	ld a, (v_barlen)
	jp F_putbar_impl

;------------------------------------------------------------------------
; F_fbuf2attr
; Convert pixel buffer addresses to attribute addresses
.globl F_fbuf2attr
F_fbuf2attr: 
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
; F_clearattrs
; Clears the entire background area
.globl F_clearattrs
F_clearattrs: 
	ld hl, (v_selstart)
	call F_fbuf2attr
	ld a, (v_sellines)
.clearloop16: 
	push hl
	call F_clearbar2
	ld bc, 32
	pop hl
	add hl, bc
	dec a
	and a
	jr nz,  .clearloop16
	ret

;------------------------------------------------------------------------
; F_inputloop
; Deal with keyboard input.
.globl F_inputloop
F_inputloop: 
.inputloop17: 
	call GETKEY		; get the actual key
        ld hl, 0x1000           ; wait some more time so that 
.loop17:                           ; multi key contacts on Spectrum + / 128
        dec hl                  ; membranes all make. Use a delay loop
        ld a, h                 ; rather than halt so this routine works
        or l                    ; with interrupts disabled.
        jr nz,  .loop17

	call GETKEY		; to close all the contacts...
	push af			; save it
	call KEYUP		; and wait for keyup
	pop af
	cp 0x0A			; KEY_DOWN
	jr z,  .bardown17
	cp 0x0B			; KEY_UP
	jr z,  .barup17
	ret
.bardown17: 
	ld a, (v_sellines)	; hit the bottom?
	dec a			; convert to 'index'
	ld b, a
	ld a, (v_barpos)
	cp b
	jr z,  .scrolldown17
	ld a, (v_numitems)	; check we're not at the end
	and a
	jr z,  .inputloop17	; no items
	dec a
	ld b, a
	ld a, (v_selecteditem)	
	cp b
	jr z,  .inputloop17	; selection is at the end
	inc a			; increment selection
	ld (v_selecteditem), a
	ld a, (v_barpos)	
	inc a
	ld (v_barpos), a	; update position
	xor a
	call F_movebar
	jr  .inputloop17
.barup17: 
	ld a, (v_barpos)
	and a
	jr z,  .scrollup17
	dec a
	ld (v_barpos), a
	ld a, (v_selecteditem)	; decrement the selected item index
	dec a
	ld (v_selecteditem), a
	inc a			; ensure A is nonzero
	call F_movebar
	jr  .inputloop17


.scrolldown17: 
	ld a, (v_numitems)	
	and a
	jr z,  .inputloop17	; no items
	dec a
	ld b, a			; compare the last item index
	ld a, (v_selecteditem)	; with the current
	cp b
	jr z,  .inputloop17	; already at the last item
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
	jp  .inputloop17

.scrollup17: 
	ld a, (v_selecteditem)	; check we've not hit zero
	and a
	jp z,  .inputloop17
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
	jp  .inputloop17

;--------------------------------------------------------------------------
; F_setbarloc
; Sets the bar location to a determined point in the list (which must
; already be initialized, along with the selection box)
; A = index of string to select
.globl F_setbarloc
F_setbarloc: 
	ld b, a			; save 'goto' location

	; first find out whether the bar is going to remain within
	; what can be seen already.
	ld hl, v_sellines
	ld a, (v_barpos)	; get the current position of the bar
	ld c, a
	ld a, (hl)		; number of lines in the selection box
	sub c			; subtract the current bar position
	ld c, a			; save this value
	ld a, (v_selecteditem)	; get the selected item index
	add a, c		; and calculate the index of the bottom item
	cp b			; Is the request for an item past what
	jr c,  .newselection18	; we can see on the screen?
	jr z,  .newselection18
	ld c, (hl)		; get the number of lines in the box
	sub c			; and calculate index of top item
	cp b			; is out of bounds low.
	jr c,  .movebar18

.newselection18: 
	push bc			; save desired index
	call F_cleararea	; clear the box ready to repaint it
	ld hl, (v_stringtable)	; calculate new position in the string
	pop bc
	ld a, b			
	ld (v_selecteditem), a	; (first save the new selected item)
	rlca			; by doubling the index
	ld e, a			; and adding it to the table start
	ld d, 0
	add hl, de
	ex de, hl		; put string pointer in DE
	ld hl, (v_selstart)	; first line of selection box
	call F_puttext
	xor a			; move bar to the top
	jp F_putbarat		; (only need this if putbarat is moved)

.movebar18: 
	; The item is actually visible already - select it.
	ld c, a			; then calculate where the bar actually
	ld a, b			; should be relative to the top
	sub c			; of the box.
	ld hl, v_selecteditem	; save the selected item
	ld (hl), b
;	jp F_putbarat		; and move the bar to its proper place.

;-------------------------------------------------------------------------
; F_putbarat: Draws the bar at the specified relative location in A
.globl F_putbarat
F_putbarat: 
	call F_clearbar		; clear the existing bar
	
	ld (v_barpos), a	; save the bar position
	ld l, a			; get the offset by
	ld h, 0
	add hl, hl		; multiplying the relative bar
	add hl, hl		; position by 32.
	add hl, hl
	add hl, hl
	add hl, hl
	ex de, hl
	ld hl, (v_barstart)	; get the bar's start address
	add hl, de		; and add the offset
	ld (v_baraddr), hl	; set current address
	jp F_putbar_impl	; and paint it

;--------------------------------------------------------------------------
; F_puttext
; Puts the text in the selection box.
; HL = address of first character cell
; DE = pointer to the first item in the string table to print
.globl F_puttext
F_puttext: 
	ld a, l			; Initialize the position of the 42 col
	and 0xE0		; print routine to the top of the box.
	ld l, a
	ld (v_row), hl		; Spectranet sysvar

	ex de, hl		; get first item to print
	ld a, (v_sellines)	; number of lines we can fit
	ld b, a
.printloop20: 
	ld e, (hl)		; low order of string lookup
	inc hl
	ld d, (hl)		; high order of string lookup
	inc hl
	ld a, d
	or e			; is it zero?
	ret z
	ex de, hl		; move string's address to HL
	push de			; save string pointer table address
	push bc			; save counter
	call F_cprint		; print the string
	pop bc
	pop de
	ex de, hl
	djnz  .printloop20
	ret

;--------------------------------------------------------------------------
; F_getselected
; Returns a pointer to the selected item in HL
.globl F_getselected
F_getselected: 
	ld a, (v_numitems)	; check there's something there
	and a
	ret z			; if nothing return with Z set
	ld hl, (v_stringtable)	; start address of the current string table
	ld a, (v_selecteditem)	; get what's under the selection
	rlca			; muliply by 2
	ld e, a
	ld d, 0
	add hl, de		; point at the entry
	ld e, (hl)		; address of the string itself
	inc hl
	ld d, (hl)
	ex de, hl
	ret

;-------------------------------------------------------------------------
; F_addstring
; Adds a string to the selection
.globl F_addstring
F_addstring: 
	push hl			; save pointer
	ld a, (v_numitems)	; Make room in the string table
	cp 0x7F			; but make sure there is room.
	jr z,  .noroom22
	rlca			; - find the last entry

	ld hl, (v_stringtable)
	ld d, 0
	ld e, a
	add hl, de		; HL = last table entry
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl			; de now has the last string address
	
	push hl
	ex de, hl
	xor a			; find the end of the string
	ld b, a
	ld c, a
	cpir			; hl now equals the end of the string

	ex de, hl
	pop hl			; new string table entry
	ld (hl), e
	inc hl
	ld (hl), d
	inc hl
	ld (hl), a		; put the null on the end
	inc hl
	ld (hl), a

	pop hl			; get string pointer
.strcpy22: 
	ld a, (hl)
	ld (de), a
	and a
	jr z,  .redraw22
	inc hl
	inc de
	jr  .strcpy22
.redraw22: 
	ld a, (v_numitems)
	inc a
	ld (v_numitems), a	; update last item index
	call F_reinitselection	; TODO - just repaint the end
	ld a, (v_numitems)
	dec a
	call F_setbarloc
	ret

.noroom22: 
	pop hl	
	scf
	ret

;-------------------------------------------------------------------------
; F_printat: Move PRINT42 location.
; B = row
; C = column
.globl F_printat
F_printat: 
	ld a, b	
	and 0x18		; find the third of the screen
	add a, 0x40		; add MSB of the screen address
	ld h, a
	ld a, b
	and 0x07		; find where we are within that 1/3rd
	rlca			; multiply by 32
	rlca
	rlca
	rlca
	rlca
	ld l, a			; MSB of framebuffer address
	ld (v_row), hl		; set row address
	ld a, c
	ld (v_column), a	; set column address
	ret

;------------------------------------------------------------------------
; F_loading
; Show "Loading..."
.globl F_loading
F_loading: 
	ld bc, 0x1600
	call F_printat
	ld hl, STR_loading
	call PRINT42
	ret
.globl F_clearloading
F_clearloading: 
	ld bc, 0x1600
	call F_printat
	ld bc, 32
	call F_clearline2
	ret
.globl F_saving
F_saving: 
	ld bc, 0x1600
	call F_printat
	ld hl, STR_saving
	call PRINT42
	ret

;-----------------------------------------------------------------------
; F_putcurfile
; Prints the currently file name.
.globl F_printcurfile
F_printcurfile: 
	ld bc, 0x1500
	call F_printat
	ld bc, 32
	call F_clearline2
	ld hl, STR_curfile
	call PRINT42
	ld hl, v_curfilename
	ld a, (hl)
	and a
	jr z,  .none27
	call PRINT42
	ret
.none27: 
	ld hl, STR_nofile
	call PRINT42
	ret

;------------------------------------------------------------------------
; F_printcwd
; Prints the current working directory
.globl F_printcwd
F_printcwd: 
	ld bc, 0x1404
	call F_printat
	ld bc,  MAXDIRSTR
	inc l
	inc l
	inc l			; put HL in the right place for clearline
	call F_clearline2	; clear out the existing string
	ld de, WORKSPACE
	call GETCWD		; ask the filesystem where we are
	ld hl, WORKSPACE
	call F_strlen
	cp MAXDIRSTR		; too long to fit in the bit of screen?
	jr nc,  .truncstr28
	call PRINT42		; no, so just print it
	ret
.truncstr28: 
	sub MAXDIRSTR
	ld c, a			; should be starting form.
	ld b, 0
	add hl, bc
	add a, 3
	cp MAXDIRSTR		; still too long with the ... added?
	call nc,  .truncmore28
	push hl
	ld hl, STR_dotdotdot
	call PRINT42
	pop hl
	call PRINT42
	ret
.truncmore28: 
	sub MAXDIRSTR
	ld c, a
	add hl, bc
	ret
.data
STR_dotdotdot: .asciz "..."
.text

;------------------------------------------------------------------------
; F_strlen
; String length returned in A for the string at HL
.globl F_strlen
F_strlen: 
	push hl
	xor a
	ld bc, 0x100
.loop29: 
	cpir
	ld a, c
	cpl
	pop hl
	ret
	
;------------------------------------------------------------------------
; F_makestaticUI
.globl F_makestaticui
F_makestaticui: 
	ld hl, UI_STRINGS
.loop30: 
	ld b, (hl)		; get screen position to print at
	inc hl
	ld c, (hl)
	inc hl
	ld a, c
	and b
	cp 0xFF			; end of table?
	ret z

	push hl
	call F_printat		; position the 42 col print routine
	pop hl
	call PRINT42		; print the string
	inc hl			; point HL at the start of the next item
	jr  .loop30

;-----------------------------------------------------------------------
; F_findstring
; Finds the index of a string in the box, returns it in A.
; Carry flag set if the string was found.
.globl F_findstr
F_findstr: 
	ld hl, (v_stringtable)
	ld c, 0			; counter
.findloop31: 
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld (v_hlsave), hl
	ld a, e
	or d
	ret z
	ld hl, v_curfilename	; string to find
	ld a, (hl)		; unset?
	and a
	ret z
	push bc
	call F_strcmp		; is this the string?
	pop bc
	jr z,  .found31
	inc c
	ld hl, (v_hlsave)
	jr  .findloop31
.found31: 
	ld a, c
	scf
	ret
