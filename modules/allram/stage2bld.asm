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
.include "spectranet.inc"
.include "ctrlchars.inc"
.text

.globl F_main
F_main:
	; need to move the stack pointer to Spectrum RAM for pageout.
	ld hl, 0
	add hl, sp
	ld (SPSAVE), hl
	ld sp, 0xFFFF

	call PAGEOUT

	ld hl, STAGE2
	ld de, 0
	ld bc, STAGE2END-STAGE2
	ldir

	ld a, (0x0000)
	ld (STAGE2END), a

	call PAGEIN
	; restore SP to Spectranet stack
	ld hl, (SPSAVE)
	ld sp, hl

	ld a, (STAGE2END)
	ld hl, STAGE2
	cp (hl)
	jr nz, .notok

	ld hl, STR_ok
	call PRINT42

.delay:
	ld bc, 0xFFFF
.delayloop:
	dec bc
	ld a, b
	or c
	jr nz, .delayloop
	ret

.notok:
	ld hl, STR_writeerr
	call PRINT42

	ld hl, STAGE2END+1
	ld a, (STAGE2END)
	call ITOA8
	ld hl, STAGE2END+1
	call PRINT42

	ld a, ','
	call PUTCHAR42
	
	ld hl, STAGE2END+1
	ld a, (STAGE2)
	call ITOA8
	ld hl, STAGE2END+1
	call PRINT42

	ld a, NEWLINE
	call PUTCHAR42
	jr .delay

.data
SPSAVE:	defw	0
STR_ok:	defb	"OK",NEWLINE,0
STR_writeerr:	defb "Got/expected: ",0
STAGE2:
.incbin "stage2img.bin"
STAGE2END:

