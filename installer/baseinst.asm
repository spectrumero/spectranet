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
.include	"ctrlchars.inc"
.include	"spectranet.inc"

; Spectranet firmware installer.
.section main
F_main:
	ld hl, 0
	add hl, sp
	ld (v_stack), hl		; save stack
	call F_pagein			; page in and disable interrupts

	call F_erase
	call F_writepages

	jp F_exit
.text
;---------------------------
; Erase all the sectors that we will occupy.
F_erase:
	ld hl, STR_erase0
	call F_print
	xor a
	call F_FlashEraseSector
	ret nc
.erasefail:
	ld hl, STR_erasefailed
	call F_print
	jp F_exit

F_writepages:
	ld hl, STR_page0
	call F_print
	ld a, 0x00
	call F_setpageB
	ld hl, PAGE0
	ld de, 0x2000
	ld bc, PAGE0LEN
	call F_FlashWriteBlock
	jp c, .writefailed

	ld hl, STR_page1
	call F_print
	ld a, 0x01
	call F_setpageB
	ld hl, PAGE1
	ld de, 0x2000
	ld bc, PAGE1LEN
	call F_FlashWriteBlock
	jp c, .writefailed

	ld hl, STR_page2
	call F_print
	ld a, 0x02
	call F_setpageB
	ld hl, PAGE2
	ld de, 0x2000
	ld bc, PAGE2LEN
	call F_FlashWriteBlock
	jp c, .writefailed

	ld hl, STR_page3
	call F_print
	ld a, 0x03
	call F_setpageB
	ld hl, PAGE3
	ld de, 0x2000
	ld bc, PAGE3LEN
	call F_FlashWriteBlock
	jr c, .writefailed

	ld hl, STR_jumptable
	call F_print
	ld hl, JUMPTABLE
	ld de, 0x2F00
	ld bc, JUMPTABLELEN
	call F_FlashWriteBlock

	ret nc

.writefailed:
	ld hl, STR_writefailed
	call F_print
	jp F_exit

;---------------------
; Restore stack and leave.
F_exit:
	ld sp, (v_stack)
	ld bc, CTRLREG
	xor a
	out (c), a
	ei
	ret

F_pagein:
	di
	ld bc, CTRLREG
	ld a, 1
	out (c), a
	ret

F_print:
.loop:
	ld a, (hl)
	and a
	ret z
	call F_putc_5by8_impl
	inc hl
	jr .loop

.data
STR_erase0:	defb "Erasing sector 0",NEWLINE,0
STR_erasefailed: defb "Erase failed.",NEWLINE,0
STR_page0:	defb "Writing page 0", NEWLINE,0
STR_page1:	defb "Writing page 1", NEWLINE,0
STR_page2:	defb "Writing page 2", NEWLINE,0
STR_page3:	defb "Writing page 3", NEWLINE,0
STR_jumptable:	defb "Writing jump table", NEWLINE,0
STR_writefailed: defb "Write failed.",NEWLINE,0

.bss
v_stack:	defw 0

