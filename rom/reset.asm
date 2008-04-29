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

; Initialization routines that are run on reset.
;
; The first thing that's done is to page in the configuration area into
; paging area B. This is nominally in the last page of the flash chip
; (page 0x20, chip 0). From this we can figure out what we're supposed
; to do next.
;
J_reset
	ld sp, INITSTACK	; temporary stack when booting
	ld hl, 0x3000		; Clear down the fixed RAM page.
	ld de, 0x3001
	ld bc, 0xFFF
	ld (hl), 0
	ldir

	; Initialize some system variables that matter.
	ld hl, 0x4000
	ld (v_row), hl		; print routine's row address
	call F_clear		; clear the screen
	ld hl, STR_bootmsg	
	call F_print		; show the boot message

	; Initialize the jump table by copying it to our RAM.
	ld hl, JUMPTABLE_COPYFROM
	ld de, 0x3E00		; jump table start
	ld bc, JUMPTABLE_SIZE
	ldir

	; Copy the page-in instructions (for the CALL trap)
	ld hl, UPPER_ENTRYPT
	ld de, 0x3FF8
	ld bc, UPPER_ENTRYPT_SIZE
	ldir

	; This is a rather poor way of generating a random number seed,
	; but it's the best we can do given Spectrum hardware. On power
	; up or after each reset, the machine's memory will be in a slightly
	; random state, so we'll CRC it to generate a seed.
	ld de, 23552		; start from the sysvars area
	ld bc, 0x1000
	call F_crc16
	ld (v_seed), hl		; save the CRC in the seed.

	call F_initroms		; Initialize any ROM modules we may have
	ld hl, 0		; We're done so put 0x0000 
	push hl			; on the stack, and
	jp UNPAGE		; unpage (a ret instruction)

;------------------------------------------------------------------------
; F_initroms
; Pages each 4k page of flash, checking for a boot vector in each.
; When a boot vector is found, that address is CALLed. That ROM then
; gets an opportunity to do whatever initialization it needs to do.
; Note this is how the W5100 actually gets configured - for the 
; Spectranet to work at all, the Spectranet utility ROM must occupy some
; page somewhere in the flash chip and get initialized.
F_initroms
	ld hl, 1	; start from page 1 - page 0 is the fixed page.
.initloop
	ld a, 0x20	; last ROM?
	cp l
	ret z		; finished
	push hl
	call F_checkromsig	; Z = valid signature found
	pop hl
	inc hl
	jr nz, .initloop	; No valid ROM signature
	push hl
	ld hl, (ROM_INIT_VECTOR) ; get initialization vector from ROM
	ld a, 0x20		; MSB of paging area B
	cp h			; does the vector point somewhere useful?
	jr nz, .returnaddr	; no - skip calling it
	ld de, .returnaddr	; get return address
	push de			; stack it to simulate CALL
	jp (hl)			; and call it
.returnaddr	
	pop hl
	jr .initloop

STR_bootmsg
	defb "Spectranet (beta)\n",0

