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

; Spectranet firmware installer.
.section main
F_main:
	ld hl, 0
	add hl, sp
	ld (v_stack), hl		; save stack
	ld F_pagein			; page in and disable interrupts

	jp F_exit
.text
;---------------------------
; Erase all the sectors that we will occupy.
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
	jr c, .erasefail
	ld hl, STR_erase2
	call F_print
	ld a, 8
	call F_FlashEraseSector
	ret nc
.erasefail:
	ld hl, STR_erasefailed
	call F_print
	jp F_exit

F_writepages
	ld hl, STR_page0
	call F_print
	ld a, 0x00
	call F_setpageB
	ld hl, PAGE0
	ld de, 0x2000
	ld bc, PAGE0LEN
	call F_FlashWriteBlock
	jr c, .writefailed

	ld hl, STR_page1
	call F_print
	ld a, 0x01
	call F_setpageB
	ld hl, PAGE1
	ld de, 0x2000
	ld bc, PAGE1LEN
	call F_FlashWriteBlock
	jr c, .writefailed

	ld hl, STR_jumptable
	call F_print
	ld hl, JUMPTABLE
	ld de, 0x2F00
	ld bc, JUMPTABLELEN
	call F_FlashWriteBlock
	jr c, .writefailed

	ld hl, STR_page2
	call F_print
	ld a, 0x02
	call F_setpageB
	ld hl, PAGE2
	ld de, 0x2000
	ld bc, PAGE2LEN
	call F_FlashWriteBlock
	jr c, .writefailed

	ld hl, STR_page3
	call F_print
	ld a, 0x03
	call F_setpageB
	ld hl, PAGE3
	ld de, 0x2000
	ld bc, PAGE3LEN
	call F_FlashWriteBlock
	jr c, .writefailed

	ld hl, STR_basext
	call F_print
	ld a, 0x04
	call F_setpageB
	ld hl, BASEXT
	ld de, 0x2000
	ld bc, BASEXTLEN
	call F_FlashWriteBlock
	jr c, .writefailed

	ld hl, STR_streams
	call F_print
	ld a, 0x05
	call F_setpageB
	ld hl, STREAMS
	ld de, 0x2000
	ld bc, STREAMLEN
	call F_FlashWriteBlock
	jr c, .writefailed

	ld hl, STR_messages
	call F_print
	ld a, 0x06
	call F_setpageB
	ld hl, MESSAGES
	ld de, 0x2000
	ld bc, MESSAGESLEN
	call F_FlashWriteBlock
	jr c, .writefailed

	ld hl, STR_config
	call F_print
	ld a, 0x07
	call F_setpageB
	ld hl, CONFIG
	ld de, 0x2000
	ld bc, CONFIGLEN
	call F_FlashWriteBlock
	jr c, .writefailed
	
	ld hl, STR_snapman
	call F_print
	ld a, 0x08
	call F_setpageB
	ld hl, SNAPMAN
	ld de, 0x2000
	ld bc, SNAPMANLEN
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

