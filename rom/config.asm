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

;
; The routines here copy the flash writer into RAM, and calls the flash
; writer.
	include "flashwrite.sym"
fwstart
	incbin "flashwrite.out"
fwend

;-------------------------------------------------------------------------
; F_saveconfig
; Copies the flash writer into RAM, calculates the new CRC for the config
; area, and then calls the flash writer.
; The config area in RAM should be already paged into page area A (chip 3
; page 0x1F)
F_saveconfig
	; copy the flash writer to RAM.
	ld hl, fwstart
	ld de, fwdest	; defined in flashwrite.asm
	ld bc, fwend-fwstart 
	ldir

	ld de, CONF_RAM	; calculate CRC on updated config values
	ld bc, 254	; up to 254 bytes worth (remaining 2 bytes are CRC)
	call F_crc16	; HL set to CRC
	ld (CONFIGCRC_RAM), hl
	call F_writeconfig
	ret

;-------------------------------------------------------------------------
; F_copyconfig
; This copies the last 16k sector of flash to the last 4 pages of RAM.
; This allows the configuration to be edited. (The next step is to erase
; the last 16k sector, then copy back the updated configuration plus the
; existing content in the remainder of the last sector of flash).
F_copyconfig
	ld a, 0xDC	; chip 3 page 0x1C - RAM
	call F_setpageA	; page it into page area A
	ld a, 0x1C	; chip 0 page 0x1C - flash
	call F_pushpageB	; it's likely this is being called from page B
	ld hl, 0x2000	; and copy
	ld de, 0x1000
	ld bc, 0x1000
	ldir
	ld a, 0xDD	; chip 3 page 0x1D - RAM
	call F_setpageA	; page it into page area A
	ld a, 0x1D	; chip 0 page 0x1D - flash
	call F_setpageB	; page it into page area B
	ld hl, 0x2000	; and copy
	ld de, 0x1000
	ld bc, 0x1000
	ldir
	ld a, 0xDE	; chip 3 page 0x1E - RAM
	call F_setpageA	; page it into page area A
	ld a, 0x1E	; chip 0 page 0x1E - flash
	call F_setpageB	; page it into page area B
	ld hl, 0x2000	; and copy
	ld de, 0x1000
	ld bc, 0x1000
	ldir
	ld a, 0xDF	; chip 3 page 0x1F - RAM
	call F_setpageA	; page it into page area A
	ld a, 0x1F	; chip 0 page 0x1F - flash
	call F_setpageB	; page it into page area B
	ld hl, 0x2000	; and copy
	ld de, 0x1000
	ld bc, 0x1000
	ldir

	call F_poppageB	; restore state of page B
	ret



