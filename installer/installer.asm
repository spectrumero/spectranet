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

.text
;---------------------------
; Erase all the sectors that we will occupy.
.globl F_erase
F_erase:
	ld hl, STR_erase0
	call F_print
	xor a
	call F_FlashEraseSector
	jr c, .erasefail
	ld hl, STR_erase1
	call F_print
	ld a, 4
	call F_FlashEraseSector
	ret nc
.erasefail:
	ld hl, STR_erasefailed
	call F_print
	jp F_exit

.globl F_writepages
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
	jp c, .writefailed

	ld hl, STR_jumptable
	call F_print
	ld hl, JUMPTABLE
	ld de, 0x2F00
	ld bc, JUMPTABLELEN
	call F_FlashWriteBlock
	jp c, .writefailed

	ld hl, STR_basext
	call F_print
	ld a, 0x04
	call F_setpageB
	ld hl, BASEXT
	ld de, 0x2000
	ld bc, BASEXTLEN
	call F_FlashWriteBlock
	jp c, .writefailed

	ld hl, STR_streams
	call F_print
	ld a, 0x05
	call F_setpageB
	ld hl, STREAMS
	ld de, 0x2000
	ld bc, STREAMSLEN
	call F_FlashWriteBlock
	jp c, .writefailed

	ld hl, STR_messages
	call F_print
	ld a, 0x06
	call F_setpageB
	ld hl, MESSAGES
	ld de, 0x2000
	ld bc, MESSAGESLEN
	call F_FlashWriteBlock
	jp c, .writefailed

	ld hl, STR_config
	call F_print
	ld a, 0x07
	call F_setpageB
	ld hl, CONFIG
	ld de, 0x2000
	ld bc, CONFIGLEN
	call F_FlashWriteBlock
	jp c, .writefailed
	
	ld hl, STR_save2
	call F_print
	ld a, 0x08
	call F_copysectortoram		; copy the flash sector
	
	ld hl, STR_erase2
	call F_print
	ld a, 0x08
	call F_FlashEraseSector
	jp c, .erasefail

	ld hl, STR_snapman
	call F_print
	ld a, 0x08
	call F_setpageB
	ld hl, SNAPMAN
	ld de, 0x2000
	ld bc, SNAPMANLEN
	call F_FlashWriteBlock	; write 
	jr c, .writefailed
	
	ld hl, STR_page9
	call F_print
	ld a, 0x09
	call F_setpageB
	ld a, 0xDD
	call F_setpageA
	call F_writepageAtopageB
	jr c, .writefailed
	
	ld hl, STR_pageA
	call F_print
	ld a, 0x0A
	call F_setpageB
	ld a, 0xDE
	call F_setpageA
	call F_writepageAtopageB
	jr c, .writefailed
	
	ld hl, STR_pageB
	call F_print
	ld a, 0x0B
	call F_setpageB
	ld a, 0xDF
	call F_setpageA
	call F_writepageAtopageB
	ret nc

.writefailed:
	ld hl, STR_writefailed
	call F_print
	jp F_exit

.globl F_writepageAtopageB
F_writepageAtopageB:
	ld hl, 0x1000
	ld de, 0x2000
	ld bc, 0x1000
	call F_FlashWriteBlock	; write 
	ret

;--------------------
; F_copysectortoram
; Copies 4 pages of flash to RAM.
; Parameter: A = first page.
.globl F_copysectortoram
F_copysectortoram:
	ex af, af'			; save ROM page
	ld a, 0xDC			; first RAM page
	ld b, 4				; pages to copy
.copyloop14:
	push bc
	call F_setpageB			; RAM into area B
	inc a
	ex af, af'			; ROM page into A
	call F_setpageA			; page it in
	inc a
	ex af, af'			; for the next iteration.
	ld hl, 0x1000			; copy the page
	ld de, 0x2000
	ld bc, 0x1000
	ldir
	pop bc
	djnz .copyloop14
	ret

;---------------------
; Restore stack and leave.
.globl F_exit
F_exit:
	ld sp, (v_stack)
	ld bc, CTRLREG
	xor a
	out (c), a
	ei
	ret

.globl F_pagein
F_pagein:
	di
	ld bc, CTRLREG
	ld a, 1
	out (c), a
	ret

.globl F_print
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
STR_erase1:	defb "Erasing sector 1",NEWLINE,0
STR_erase2:	defb "Erasing sector 2",NEWLINE,0
STR_save2:	defb "Saving sector 2",NEWLINE,0
STR_erasefailed: defb "Erase failed.",NEWLINE,0
STR_page0:	defb "Writing page 0", NEWLINE,0
STR_page1:	defb "Writing page 1", NEWLINE,0
STR_page2:	defb "Writing page 2", NEWLINE,0
STR_page3:	defb "Writing page 3", NEWLINE,0
STR_jumptable:	defb "Writing jump table", NEWLINE,0
STR_basext:	defb "Adding basext module",NEWLINE,0
STR_streams:	defb "Adding streams module", NEWLINE,0
STR_messages:	defb "Adding messages module",NEWLINE,0
STR_config:	defb "Adding config module",NEWLINE,0
STR_snapman:	defb "Adding snapman module",NEWLINE,0
STR_writefailed: defb "Write failed.",NEWLINE,0

STR_page9:	defb "Restoring page 9", NEWLINE,0
STR_pageA:	defb "Restoring page A", NEWLINE,0
STR_pageB:	defb "Restoring page B", NEWLINE,0


.bss
.globl v_stack
v_stack:	defw 0

