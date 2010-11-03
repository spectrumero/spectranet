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
.text
.globl F_copyconfig
F_copyconfig: 
	call F_getsysvar	; see if we've already copied it
	inc hl
	ld a, 1
	cp (hl)			; if Z we've already made a copy
	ret z
	ld (hl), 1		; Indicate a copy has been made.
	
        ld hl, .copier1  ; first, copy to RAM workspace
        ld de, 0x3000   ; fixed workspace page at 0x3000
        ld bc, copiersz
        ldir
        jp 0x3000
.copier1: 
        ld a, 0xDC      ; chip 3 page 0x1C - RAM
        call SETPAGEA   ; page it into page area A
        ld a, 0x1C      ; chip 0 page 0x1C - flash
        call PUSHPAGEB  ; and mapped into area B
        ld hl, 0x2000   ; and copy
        ld de, 0x1000
        ld bc, 0x1000
        ldir
        ld a, 0xDD      ; chip 3 page 0x1D - RAM
        call SETPAGEA   ; page it into page area A
        ld a, 0x1D      ; chip 0 page 0x1D - flash
        call SETPAGEB   ; page it into page area B
        ld hl, 0x2000   ; and copy
        ld de, 0x1000
        ld bc, 0x1000
        ldir
        ld a, 0xDE      ; chip 3 page 0x1E - RAM
        call SETPAGEA   ; page it into page area A
        ld a, 0x1E      ; chip 0 page 0x1E - flash
        call SETPAGEB   ; page it into page area B
        ld hl, 0x2000   ; and copy
        ld de, 0x1000
        ld bc, 0x1000
        ldir
        ld a, 0xDF      ; chip 3 page 0x1F - RAM
        call SETPAGEA   ; page it into page area A
        ld a, 0x1F      ; chip 0 page 0x1F - flash
        call SETPAGEB   ; page it into page area B
        ld hl, 0x2000   ; and copy
        ld de, 0x1000
        ld bc, 0x1000
        ldir
        call POPPAGEB   ; reset page B settings before returning (to page B!)

        ret             ; configuration settings are in RAM mapped in page AA
.copierend1:
copiersz	equ .copierend1 - .copier1

