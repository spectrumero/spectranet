;The MIT License
;
;Copyright (c) 2010 Dylan Smith
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

; Basstart.asm runs module functions that should be run once BASIC has
; shown the copyright message. The basstart function gets called from
; a trap.

F_basstart
	call DISABLETRAP	; release the trap

	; we have to do a bit of a trick here, page this page into area
	; A (because modules live in area B, where we want to call).
	ld a, (v_pgb)
	call SETPAGEA
	jp F_basstart_go-0x1000
F_basstart_go
	ld hl, vectors
.searchloop
	ld a, (hl)
	and a			; last entry done?
	jr z, .done
	inc hl
	push hl

	ld a, l
	sub vectors % 256 - 1
	call SETPAGEB

	ld hl, (BASSTART_VECTOR)	; check for a valid vector
	ld a, h			; by examining the MSB and finding
	and 0xF0		; if it is between 0x20-0x2F
	cp 0x20
	jr nz, .continue	; not 0x20, try the next one.

	ld de, .continue-0x1000	; set up the return point
	push de			; on the stack so RET comes here
	jp (hl)			; and jump to the vector address	
.continue
	pop hl
	jr .searchloop
.done
	jp PAGETRAPRETURN

;-------------------------------------------------------------------------
; F_basstart_setup
; Set the execution trap.
F_basstart_setup
	ld hl, STARTTRAPBLOCK
	jp SETTRAP
STARTTRAPBLOCK
	defb	0xFF		; this page
	defw	F_basstart	; function to call
	defw	0x1299		; stacked address at time of NMI
	defw	0x1296		; address to trap with NMI


