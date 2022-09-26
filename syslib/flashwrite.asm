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
;---------------------------------------------------------------------------
; Flash erase and write routines.
; Note that these routines can't actually be run from flash! They should
; be assembled to RAM instead.
.include	"sysdefs.inc"
.include	"sysvars.inc"
.text

;---------------------------------------------------------------------------
; F_FlashIdentify
; Attempt to identify the flash ROM IC present on the spectranet
; sets a system variable in SRAM containing the device ID which should be
; 0x20 for an Am29F010, or 0xB5/B6/B7 for an SST39SF010A/020A/040
.globl F_FlashIdentify
F_FlashIdentify:
	push bc
	ld bc, PAGEB
	ld a,5
	out (c),a	; flash A12-A15 bits to 5
	ld a, 0xAA	; unlock code 1
	ld (0x2555), a	; unlock addr 1
	ld a,2
	out (c),a	; flash A12-A15 bits to 2
	ld a, 0x55	; unlock code 2
	ld (0x2AAA), a	; unlock addr 2
    ld a,5
	out (c),a	; flash A12-A15 bits to 2
    ld a, 0x90	; ID code
	ld (0x2555), a	; ID
	ld a,0
	out (c),a	; flash A12-A15 bits to 0
    ld a, (0x0001)	; read device ID
    ld (v_flashid),a	; store device ID in SRAM
    ;ld (0x401F),a ; DEBUG
    ;ld a,0x55 ; DEBUG
    ;ld (0x411F),a ; DEBUG
    ld a, 0xF0	; reset code
	ld (0x0000),a	; reset flash
    ld a,(v_pgb)
    out (c),a	; restore page B
	pop bc
	ret

;---------------------------------------------------------------------------
; F_FlashEraseSector
; Simple flash writer for the Am29F010 and SST39SF010/020/040
; Erases one 16k sector or four 4k sectors based on detected device
;
; Parameters: A = page to erase (based on 4k Spectranet pages, but
; erases a 16k sector)
; Carry flag is set if an error occurs.
.globl F_FlashEraseSector
F_FlashEraseSector:
	; preserve page to start the erase from in C
	ld c,a

	call F_FlashIdentify

	ld a,(v_flashid)	; load flash type
	ld b,4 ; erase four 4k sectors
	
	; this could potentially give a false positive if a ROM contains these values in the second byte
	; a more robust check would be to also test the manufacturer ID is 0xBF (SST)
	cp 0xB5	; SST39SF010A
	jr z, .eraseLoop
	cp 0xB6	; SST39SF020A
	jr z, .eraseLoop
	cp 0xB7	; SST39SF040
	jr z, .eraseLoop

	ld b,1 ; else erase one 16k sector
.eraseLoop:
	call F_doErase
	inc c
	djnz .eraseLoop
	ret

F_doErase:
	push bc
	ld l,c
	ld bc, PAGEB
	ld a,5
	out (c),a	; flash A12-A15 bits to 5
	ld a, 0xAA	; unlock code 1
	ld (0x2555), a	; unlock addr 1
	ld a,2
	out (c),a	; flash A12-A15 bits to 2
	ld a, 0x55	; unlock code 2
	ld (0x2AAA), a	; unlock addr 2
	ld a,5
	out (c),a	; flash A12-A15 bits to 5
	ld a, 0x80	; erase cmd 1
	ld (0x2555), a	; erase cmd addr 1
	ld a, 0xAA	; erase cmd 2
	ld (0x2555), a	; erase cmd addr 2
	ld a,2
	out (c),a	; flash A12-A15 bits to 2
	ld a, 0x55	; erase cmd 3
	ld (0x2AAA), a	; erase cmd addr 3
	ld a,l
	out (c),a	; flash A12-A15 bits to 4k page number
	ld (v_pgb), a ; update pageB sysvar
	ld a, 0x30	; erase cmd 4
	ld (0x2000), a	; erase sector address
	pop bc
	ld hl, 0x2000
.wait1: 
	bit 7, (hl)	; test DQ7 - should be 1 when complete
	jr nz,  .complete1
	bit 5, (hl)	; test DQ5 - should be 1 to continue
	jr z,  .wait1
	bit 7, (hl)	; test DQ7 again
	jr z,  .borked1

.complete1: 
	or 0		; clear carry flag
	ret

.borked1: 
	scf		; carry flag = error
	ret

;---------------------------------------------------------------------------
; F_FlashWriteBlock
; Copies a block of memory to flash. The flash should be mapped into
; page area B.
; Parameters: HL = source start address
;             DE = destination start address
;             BC = number of bytes to copy
; On error, the carry flag is set.
.globl F_FlashWriteBlock
F_FlashWriteBlock: 
	ld a, (hl)	; get byte to write
	call F_FlashWriteByte
	ret c		; on error, return immediately
	inc hl		; point at next source address
	inc de		; point at next destination address
	dec bc		; decrement byte count
	ld a, b
	or c		; is it zero?
	jr nz, F_FlashWriteBlock
	ret

;---------------------------------------------------------------------------
; F_FlashWriteByte
; Writes a single byte to the flash memory.
; Parameters: DE = address to write
;              A = byte to write
; On return, carry flag set = error
; Page the appropriate flash area into one of the paging areas to write to
; it, and the address should be in that address space.
.globl F_FlashWriteByte
F_FlashWriteByte: 
	push hl
	push bc
	ld l, a		; save A
    
	ld bc, PAGEB
    
    ld a, 5
    out (c),a	; flash A12-A15 bits to 5
	ld a, 0xAA	; unlock 1
	ld (0x2555), a	; unlock address 1
    
    ld a, 2
    out (c),a	; flash A12-A15 bits to 2
	ld a, 0x55	; unlock 2
	ld (0x2AAA), a	; unlock address 2
    
    ld a, 5
    out (c),a	; flash A12-A15 bits to 5
	ld a, 0xA0	; Program
	ld (0x2555), a	; Program address
    
    ld a, (v_pgb)
    out (c),a	; restore page B
    
	ld a, l		; retrieve A
	ld (de), a	; program it

.wait3: 
	ld a, (de)	; read programmed address
	ld b, a		; save status
	xor l		
	bit 7, a	; If bit 7 = 0 then bit 7 = data	
	jr z,  .byteComplete3

	bit 5, b	; test DQ5
	jr z,  .wait3

	ld a, (de)	; read programmed address
	xor l		
	bit 7, a	; Does DQ7 = programmed data? 0 if true
	jr nz,  .borked3

.byteComplete3:
	pop bc
	pop hl
	or 0		; clear carry flag
	ret

.borked3: 
	pop bc
	pop hl
	scf		; error = set carry flag
	ret

;---------------------------------------------------------------------------
; F_writesector
; Writes 4 pages from the last 4 pages of RAM to flash, starting at the
; page specified in A
.globl F_writesector
F_writesector: 
	ex af, af'	; swap with alternate set
	ld a, 0xDC	; RAM page 0xDC
	ld b, 4		; number of pages
.loop4: 
	push bc
	call F_setpageA ; Page into area A
	inc a		; next page
	ex af, af'	; get flash page to program
	call F_setpageB
	inc a		; next page
	ex af, af'	; back to ram page for next iteration
	ld hl, 0x1000
	ld de, 0x2000
	ld bc, 0x1000
	push af
	call F_FlashWriteBlock
	jr c,  .failed4	; restore stack and exit
	pop af
	pop bc
	djnz  .loop4	; next page
	ret
.failed4: 		; restore stack, set carry flag
	pop af
	pop bc
	scf
	ret

UNPAGE	equ 0x007C

