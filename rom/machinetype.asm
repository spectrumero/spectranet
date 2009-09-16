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

; Determine the machine type.

; F_machinetype: Determine what kind of machine this is with regards to
; the ROMs - is this a 48/128K/grey +2, or a +3/black +2? The black +2
; and +3 have a different arrangement of ROMs for interpreting BASIC
; which has a profound effect on what we need to do to interpret BASIC...
F_machinetype
	ld hl, F_mtype_impl	; copy the routine out of the
	ld de, 0x6000		; ROM memory map area
	ld bc, MTYPE_LEN
	ldir
	jp 0x6006

F_mtype_impl
STR_syn defb "Syntax"
	call 0x7C		; Page ROM out
	ld bc, 0x1FFD		; set 1ffd to 0x00
	xor a
	out (c), a
	ld b, 0x7f		; set bit 4 of 0x7ffd
	ld a, 0x10
	out (c), a		; page ROM 1

	ld b, 6
	ld hl, 0x6000
	ld de, 0x0000
.loop
	ld a, (de)
	cp (hl)
	jr nz, .notplusthree
	inc hl
	inc de
	djnz .loop
	ld h, 1			; value to eventually set
	jr .done

.notplusthree
	ld h, 0			; value to eventually set

.done
	ld b, 0x7f
	xor a			; reset 0x7ffd
	out (c), a

	ld bc, 0x80EF		; Spectranet CPLD register
	in a, (c)		; Read register
	set 0, a		; set pagein bit
	out (c), a		; page in

	ld a, h			; retrieve value
	ld (v_plusthree), a
	ret

MTYPE_LEN equ $-F_mtype_impl

