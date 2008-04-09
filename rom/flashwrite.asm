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
; Note that these routines should be copied to RAM before being called.
; They can't run from flash because they would interrupt the process
; of writing the flash while running. (Or worse still overwrite themselves)
;
; These routines should be assembled independently of the ROM code, and
; the resulting sym file and binary object included by the ROM assembly.
;
	org 0x3B00	; use the temporary buffer space

;---------------------------------------------------------------------------
; F_FlashEraseSector
; Simple flash writer for the Am29F010 (and probably any 1 megabit flash
; with 16kbyte sectors)
;
; Parameters: A = page to erase (based on 4k Spectranet pages, but
; erases a 16k sector)
; Carry flag is set if an error occurs.
F_FlashEraseSector
	; Page in the appropriate sector first 4k into page area B.
	ld h, 0		; flash is chip 0
	ld l, a		; page to erase in A
	call F_setpageB	; page into page area B

	ld a, 0xAA	; unlock code 1
	ld (0x555), a	; unlock addr 1
	ld a, 0x55	; unlock code 2
	ld (0x2AA), a	; unlock addr 2
	ld a, 0x80	; erase cmd 1
	ld (0x555), a	; erase cmd addr 1
	ld a, 0xAA	; erase cmd 2
	ld (0x555), a	; erase cmd addr 2
	ld a, 0x55	; erase cmd 3
	ld (0x2AA), a	; erase cmd addr 3
	ld a, 0x30	; erase cmd 4
	ld (0x2000), a	; erase sector address

	ld hl, 0x2000
.wait
	bit 7, (hl)	; test DQ7 - should be 1 when complete
	jr nz, .complete
	bit 5, (hl)	; test DQ5 - should be 1 to continue
	jr z, .wait
	bit 7, (hl)	; test DQ7 again
	jr z, .borked

.complete
	or 0		; clear carry flag
	ret

.borked	
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
F_FlashWriteBlock
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
F_FlashWriteByte
	push bc
	ld c, a		; save A

	ld a, #AA	; unlock 1
	ld (0x555), a	; unlock address 1
	ld a, 0x55	; unlock 2
	ld (0x2AA), a	; unlock address 2
	ld a, 0xA0	; Program
	ld (0x555), a	; Program address
	ld a, c		; retrieve A
	ld (de), a	; program it

.wait
	ld a, (de)	; read programmed address
	ld b, a		; save status
	xor c		
	bit 7, a	; If bit 7 = 0 then bit 7 = data	
	jr z, .byteComplete

	bit 5, b	; test DQ5
	jr z, .wait

	ld a, (de)	; read programmed address
	xor c		
	bit 7, a	; Does DQ7 = programmed data? 0 if true
	jr nz, .borked

.byteComplete
	pop bc
	or 0		; clear carry flag
	ret

.borked
	pop bc
	scf		; error = set carry flag
	ret

;-------------------------------------------------------------------------
; F_copyconfig
; This copies the last 16k sector of flash to the last 4 pages of RAM.
; This allows the configuration to be edited. (The next step is to erase
; the last 16k sector, then copy back the updated configuration plus the
; existing content in the remainder of the last sector of flash).
F_copyconfig
	ld hl, 0x031C	; chip 3 page 0x1C - RAM
	call F_setpageA	; page it into page area A
	ld hl, 0x001C	; chip 0 page 0x1C - flash
	call F_setpageB	; page it into page area B
	ld hl, 0x2000	; and copy
	ld de, 0x1000
	ld bc, 0x1000
	ldir
	ld hl, 0x031D	; chip 3 page 0x1D - RAM
	call F_setpageA	; page it into page area A
	ld hl, 0x001D	; chip 0 page 0x1D - flash
	call F_setpageB	; page it into page area B
	ld hl, 0x2000	; and copy
	ld de, 0x1000
	ld bc, 0x1000
	ldir
	ld hl, 0x031E	; chip 3 page 0x1E - RAM
	call F_setpageA	; page it into page area A
	ld hl, 0x001E	; chip 0 page 0x1E - flash
	call F_setpageB	; page it into page area B
	ld hl, 0x2000	; and copy
	ld de, 0x1000
	ld bc, 0x1000
	ldir
	ld hl, 0x031F	; chip 3 page 0x1F - RAM
	call F_setpageA	; page it into page area A
	ld hl, 0x001F	; chip 0 page 0x1F - flash
	call F_setpageB	; page it into page area B
	ld hl, 0x2000	; and copy
	ld de, 0x1000
	ld bc, 0x1000
	ldir
	ret

;---------------------------------------------------------------------------
; F_writeconfig
; Erases the last flash sector and copies the last four 4k pages from
; RAM to the last four 4k pages of flash. The RAM should contain what
; was in the last four pages of flash plus the modified configuration.
; The carry flag is set on error.
F_writeconfig
	ld hl, 0x031C	; RAM page 0x1C
	call F_setpageA	; Page into area A
	ld hl, 0x001C	; flash page 0x1C
	call F_setpageB	; Page into area B
	ld hl, 0x1000
	ld de, 0x2000
	ld bc, 0x1000
	call F_FlashWriteBlock
	ret c		; on error, bale out
	ld hl, 0x031D	; RAM page 0x1D
	call F_setpageA	; Page into area A
	ld hl, 0x001D	; flash page 0x1D
	call F_setpageB	; Page into area B
	ld hl, 0x1000
	ld de, 0x2000
	ld bc, 0x1000
	call F_FlashWriteBlock
	ret c		; on error, bale out
	ld hl, 0x031E	; RAM page 0x1E
	call F_setpageA	; Page into area A
	ld hl, 0x001E	; flash page 0x1E
	call F_setpageB	; Page into area B
	ld hl, 0x1000
	ld de, 0x2000
	ld bc, 0x1000
	call F_FlashWriteBlock
	ret c		; on error, bale out
	ld hl, 0x031F	; RAM page 0x1F
	call F_setpageA	; Page into area A
	ld hl, 0x001F	; flash page 0x1F
	call F_setpageB	; Page into area B
	ld hl, 0x1000
	ld de, 0x2000
	ld bc, 0x1000
	call F_FlashWriteBlock
	ret

	include "pager.asm"	; we need our own copy of the pager code

	; This is just a safety measure to make sure we won't run off
	; the end of the temporary buffer space and all over the jump
	; table.
	block 0x3DFF-$,0xFF

; Define system variables that we need
v_pga		equ 0x3F05
v_pgb		equ 0x3F06
v_chipsel 	equ 0x3F07
	
	include "sysdefs.asm"	; defines

