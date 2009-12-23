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
; Handle user interaction for the snapshot manager.

; Create the user interface and enter the input loop.
F_startui

F_mainloop
	call F_inputloop	; call UI control input loop, wait for a key
	ld b, a			; save the keypress in B
	ld c, 0			; use C as a counter
	ld hl, INPUTTABLE
.getactionloop
	ld a, (hl)
	and a			; check for "end of list"
	jr z, F_mainloop	; invalid key, ignore it
	cp b			; See if the key press is recognised.
	jr z, .handlekey
	inc c			; inc. counter
	jr .getactionloop
.handlekey
	rlc c			; double the counter to form the offset
	ld b, 0			; in BC
	ld hl, INPUTADDRS	; Calculate the address of the address
	add hl, bc		; that we need to find
	ld e, (hl)		; and get its LSB
	inc hl
	ld d, (hl)		; and MSB
	ex de, hl		; put it in hl
	ld de, .return
	push de			; effectively, we want to CALL (HL)
	jp (hl)
.return
	ld a, (v_inputflags)
	bit 0, a		; signal to leave?
	jr z, F_mainloop	; ...no, so continue
	res 0, a
	ld (v_inputflags), a	; reset the flag
	ret

;------------------------------------------------------------------------
; F_exit
; Leave the main input loop, by setting the 'done' flag.
F_exit
	ld a, (v_inputflags)
	set 0, a
	ld (v_inputflags), a
	ret

;------------------------------------------------------------------------
; F_userinput
; HL = pointer to prompt string
; DE = pointer to buffer in which to return the data
;  C = size of input buffer
F_userinput
        push bc
        push hl
        ld bc, 0x1600           ; line 24, col 0
        call F_printat          ; HL now is the address of the line
        pop hl                  ; prompt to print
        call PRINT42
        pop bc
        push de                 ; save buffer address
        call INPUTSTRING
        ld bc, 0x1600           ; set the position again...
        call F_printat
        ld bc, 32
        call F_clearline2       ; ...to clear the line
        pop hl
        ld a, (hl)
        and a                   ; return with Z set if nothing entered
        ret

;----------------------------------------------------------------------
; F_switchdirview
; Switch between directory and file views.
F_switchdirview
	ld a, (v_viewflags)
	xor 1			; flip "dir view" bit
	ld (v_viewflags), a	; and save
	rra			; push lsb into the carry flag
	jr nc, .showdir		; switch from file to dir view
	ld de, v_filetable
.makesel
	ld hl, UI_BOXSTART	; start address of the box
	ld bc, UI_BOXDIMENSION	; box dimensions
	jp F_makeselection 	; make the selection and return.
.showdir
	ld de, v_dirtable
	jr .makesel
	
