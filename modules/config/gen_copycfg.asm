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

; F_copyconfig
; This copies the last 16k sector of flash to the last 4 pages of RAM.
; This allows the configuration to be edited. (The next step is to erase
; the last 16k sector, then copy back the updated configuration plus the
; existing content in the remainder of the last sector of flash).
.include	"spectranet.inc"
.include	"sysdefs.inc"

PAGEINSECTOR equ CONFIG_PAGE&3
SECTORSTART equ CONFIG_PAGE&0xFC

.text
.globl F_copyconfig
F_copyconfig: 
        ld hl, .copier1  ; first, copy to RAM workspace
        ld de, 0x3000   ; fixed workspace page at 0x3000
        ld bc, copiersz
        ldir
        jp 0x3000
.copier1: 
        ; copy flash erase sector to SRAM, ensuring that CONFIG_PAGE gets
        ; copied last, even if CONFIG_PAGE has been changed from the last
        ; page of an erase sector.
        ld a, FLASH_COPY_PAGES+(PAGEINSECTOR-3)&3
        call SETPAGEA   ; page it into page area A
        ld a, SECTORSTART+(PAGEINSECTOR-3)&3
        call PUSHPAGEB  ; and mapped into area B
        ld hl, 0x2000   ; and copy
        ld de, 0x1000
        ld bc, 0x1000
        ldir
        ld a, FLASH_COPY_PAGES+(PAGEINSECTOR-2)&3
        call SETPAGEA   ; page it into page area A
        ld a, SECTORSTART+(PAGEINSECTOR-2)&3
        call SETPAGEB   ; page it into page area B
        ld hl, 0x2000   ; and copy
        ld de, 0x1000
        ld bc, 0x1000
        ldir
        ld a, FLASH_COPY_PAGES+(PAGEINSECTOR-1)&3
        call SETPAGEA   ; page it into page area A
        ld a, SECTORSTART+(PAGEINSECTOR-1)&3
        call SETPAGEB   ; page it into page area B
        ld hl, 0x2000   ; and copy
        ld de, 0x1000
        ld bc, 0x1000
        ldir
        ld a, FLASH_COPY_PAGES+PAGEINSECTOR ; location of config data mirror
        call SETPAGEA   ; page it into page area A
        ld a, CONFIG_PAGE   ; location of non volatile config data in flash
        call SETPAGEB   ; page it into page area B
        ld hl, 0x2000   ; and copy
        ld de, 0x1000
        ld bc, 0x1000
        ldir
        call POPPAGEB   ; reset page B settings before returning (to page B!)

        ret             ; configuration settings are in RAM mapped in page AA
.copierend1:
copiersz	equ .copierend1 - .copier1

