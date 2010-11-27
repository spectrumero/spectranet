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
.include	"zxsysvars.inc"
.include	"zxrom.inc"
.include	"defs.inc"
.include	"ctrlchars.inc"
.include	"spectranet.inc"
.include	"streamvars.inc"
.text
; Handle BASIC flow control

.globl F_eofhandler
F_eofhandler:
	call F_fetchpage
	ld hl, (oneof_line)
	ld (ZX_NEWPPC), hl	; set line number
	xor a
	ld (ZX_NSPPC), a	; reset NSPPC
	call F_leave
	call F_showzxstack
	jp EXIT_SUCCESS

; Munge the stack to cause the program to continue.
.globl F_basic_continue
F_basic_continue:
	ld hl, (ZX_RAMTOP)
	dec hl
	dec hl
	ld (hl), 0x13		; MAIN-4 MSB
	dec hl
	ld (hl), 0x03		; MAIN-4 LSB
	dec hl
	ld (ZX_ERR_SP), hl	; clear the ZX stack
	ld hl, 0x1BB0		; report 0 OK routine
	push hl
	ei
	jp 0x007C		; and page out via this address.

.globl F_showzxstack
F_showzxstack:
	push ix
	push hl
	push de
	push bc
	push af
	ld a, NEWLINE
	call PUTCHAR42

	ld ix, (ZX_ERR_SP)
	ld b, 8
.loop3:
	push bc
	ld hl, 0x3000
	push ix
	pop de
	ld a, d
	call ITOH8
	ld hl, 0x3000
	call PRINT42
	
	ld hl, 0x3000
	push ix
	pop de
	ld a, e
	call ITOH8
	ld hl, 0x3000
	call PRINT42

	ld a, ':'
	call PUTCHAR42
	
	ld hl, 0x3000
	ld a, (ix+1)
	call ITOH8
	ld hl, 0x3000
	call PRINT42
	
	ld hl, 0x3000
	ld a, (ix+0)
	call ITOH8
	ld hl, 0x3000
	call PRINT42

	ld a, NEWLINE
	call PUTCHAR42

	inc ix
	inc ix
	ld hl, (ZX_RAMTOP)
	pop bc
	djnz .loop3

	pop af
	pop bc
	pop de
	pop hl
	pop ix
	ret

