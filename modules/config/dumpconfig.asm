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
.include	"spectranet.inc"
.include	"configdefs.inc"
.include	"ctrlchars.inc"
.text
	call PAGEIN
	call CLEAR42

	ld a, CFG_FLASH_PAGE
	call SETPAGEA
.start0: 
	ld hl, str_size
	call PRINT42
	ld hl, CONFIG_BASE_ADDR
	call F_printint16
	inc hl
	inc hl
.configsections0: 
	ld a, (hl)
	inc hl
	ld c, (hl)
	inc a
	inc c
	or c
	jp z,  .done0
	dec hl

	push hl
	ld hl, str_section
	call PRINT42
	pop hl
	call F_printint16
	inc hl
	inc hl

	push hl
	ld hl, str_sectionsize
	call PRINT42
	pop hl
	call F_printint16

	ld c, (hl)		; get the section size into BC and store
	inc hl
	ld b, (hl)
	inc hl			; hl now at first byte of config
	ld (v_remaining), bc
.sectionloop0: 
	ld a, b
	or c			; read whole section?
	jr z,  .configsections0	; go back to the conig sections loop

	bit 7, (hl)
	jr z,  .string0		; bit 7 = 0 = string
	bit 6, (hl)
	jr nz,  .word0		; bit 6 = 0 = byte
	
	push hl
	ld hl, str_byteid
	call PRINT42
	pop hl
	call F_printint8
	inc hl
	push hl
	ld hl, str_byte
	call PRINT42
	pop hl
	call F_printint8
	inc hl			; point at next element
	ld bc, (v_remaining)
	dec bc
	dec bc
	ld (v_remaining), bc	; update remaining bytes
	jr  .sectionloop0

.string0: 
	push hl
	ld hl, str_stringid
	call PRINT42
	pop hl
	call F_printint8
	inc hl
	push hl
	ld hl, str_string
	call PRINT42
	pop hl

	ld bc, (v_remaining)
	dec bc
.printloop0: 
	ld a, (hl)
	and a
	jr z,  .printdone0
	call PUTCHAR42
	inc hl
	dec bc
	and a			; string end?
	jr  .printloop0
.printdone0: 
	inc hl
	dec bc
	ld (v_remaining), bc	; update remaining
	jr  .sectionloop0

.word0: 
	push hl
	ld hl, str_wordid
	call PRINT42
	pop hl
	call F_printint8
	inc hl
	push hl
	ld hl, str_word
	call PRINT42
	pop hl
	call F_printint16
	inc hl
	inc hl
	ld bc, (v_remaining)
	dec bc
	dec bc
	dec bc
	ld (v_remaining), bc
	jp  .sectionloop0
	
	
.done0: 
	ld hl, str_end
	call PRINT42
J_exit:
	jp PAGEOUT

; print 16 bits pointed to by HL
.globl F_printint16
F_printint16: 
	push hl
	inc hl
	ld a, (hl)
	ld hl, workspace
	call ITOH8
	ld hl, workspace
	call PRINT42
	pop hl
.globl F_printint8
F_printint8: 		; and just do 8 bits
	push hl
	ld a, (hl)
	ld hl, workspace
	call ITOH8
	ld hl, workspace
	call PRINT42
	pop hl
	ret

.globl F_dumpbytes
F_dumpbytes: 
	ld hl, 0x1000
	ld b, 0x20
.loop3: 
	push bc
	push hl
	ld a, (hl)
	ld hl, workspace
	call ITOH8
	ld hl, workspace
	call PRINT42
	pop hl
	pop bc
	inc hl
	djnz  .loop3
	ret
.data
str_size:	defb "Config size: ",0
str_section:	defb NEWLINE,NEWLINE,"--- SectionID: ",0
str_sectionsize: defb NEWLINE,"Secsize : ",0
str_stringid:	defb NEWLINE,"StringID: ",0
str_string:	defb NEWLINE,"String  : ",0
str_byteid:	defb NEWLINE,"ByteID  : ",0
str_byte:	defb " Byte: ",0
str_wordid:	defb NEWLINE,"WordID  : ",0
str_word:	defb " Word: ",0
str_end:	defb NEWLINE,"---End of configuration.",0
.bss
v_remaining:	defw 0
workspace:	defb 0

