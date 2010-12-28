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
.include	"sysvars.inc"
.include	"spectranet.inc"

; Determines what value port 0x7FFD should have on a 128K machine.
MAINSPSAVE:	equ 0x3000
TEMPSP:		equ 0x81FE
SAVERAM:		equ 0x3002
.text
;-----------------------------------------------------------------------
; F_detectpages
; Detects which 128K pages are in use. The .SNA0 format just supports the
; ROMs from 0x7FFD and not the ports used by the +3/+2A exclusively. This
; is unlikely to be a problem for the vast majority of programs.
; Returns with carry set if pages could not be detected.
.text
.globl F_detectpages
F_detectpages:
	; Posit that this is a 128K machine - the 128K flag will be
	; reset when we find out that it's not.
	ld a, 1
	ld (v_machinetype), a

        ; Detect the paged in ROM.
        ld hl, 0x8000                   ; Swap out a chunk of main RAM
        ld de, SAVERAM                  ; into Spectranet memory so that
        ld bc, 512                      ; the ROM can be examined
        ldir
        ld hl, F_romdetect              ; Copy the ROM detection routine
        ld de, 0x8000                   ; to main RAM.
        ld bc, F_romdetect_sz
        ldir
        ld (MAINSPSAVE), sp             ; save the stack pointer
        ld sp, TEMPSP                   ; and put the stack in main RAM
        call 0x8000                     ; Call the ROM detect routine
        ld sp, (MAINSPSAVE)             ; Restore the stack pointer
        push af                         ; save flags
        ld a, e                         ; get ROM flag
        ld (v_port7ffd), a
        ld hl, SAVERAM                  ; Restore the memory chunk that
        ld de, 0x8000                   ; we used.
        ld bc, 512
        ldir
        pop af                          ; restore flags so carry is set
        ret c

        ; Detect the RAM page in use
        call F_detectram
	ret c

	; Record the screen in use.
	ld bc, CTRLREG
	in a, (c)			; bit 4 is set to the screen state
	and 0x10			; mask it out then
	rrca				; shift it into bit 3 so it
	ld hl, v_port7ffd		; can be merged into
	or (hl)				; the port 0x3FFD storage.
	ld (hl), a
        ret

; THIS ROUTINE MUST BE COPIED TO RAM FIRST!
; Returns the value of port 7FFD bit 4 in the E register
; Returns the value of port 1FFD bit 2 in the D register
.globl F_romdetect
F_romdetect:
;        call PAGEOUT                    ; page out the Spectranet ROM
        ld a, (0x0008)                  ; examine 0x0008 in the ROM
        cp 0xFB                         ; ROM 0 for all models
        jr z, .editor2
        cp 0xC3                         ; ROM 1 - Plus 3
        jr z, .plusthreesyn2
        cp 0x50                         ; ROM 2 - Plus 3 DOS
        jr z, .plusthreedos2
        cp 0x2A                         ; BASIC (all models)
        jr nz, .unknown2
.basic2:
        ld de, 0x0210                   ; Bit 2 of 1FFD, bit 4 of 7FFD
        jr .exit2
.editor2:
        ld de, 0x0000                   ; Neither 1FFD nor 7FFD set
        jr .exit2
.plusthreedos2:
        ld de, 0x0200                   ; only 0x1FFD set
        jr .exit2
.plusthreesyn2:
        ld de, 0x0010                   ; only 0x7FFD set
.exit2:
        ld bc, CTRLREG
	in a, (c)			; get current value
        or 1	                        ; page in Spectranet ROM
        out (c), a
        ret
.unknown2:
	xor a
	ld (v_machinetype), a		; reset 128K flag
        scf
        jr .exit2

.globl F_romdetect_sz
F_romdetect_sz:  equ $-F_romdetect

;-------------------------------------------------------------------------
; F_detectram: See what RAM page is paged in.
.globl F_detectram
F_detectram:
        ; Next detect the RAM page. For this we need to copy a small
        ; chunk from 0xC000 in our memory, and then put a string into
        ; that RAM page. Then start flipping through RAM pages with
        ; port 0x7FFD.  
        ld hl, 0xC000                   ; Preserve the stuff at 0xC000
        ld de, SAVERAM
        ld bc, SNSTRINGLEN
        ldir
        ld hl, SNSTRING                 ; and place our string there.
        ld de, 0xC000
        ld bc, SNSTRINGLEN
        ldir

        xor a                           ; start at page 0
.detectloop4:
        ld bc, 0x7FFD                   ; port 0x7FFD
        out (c), a                      ; switch page
.snapcmp4:
        push af
        call .compare4
        jr nz, .next4
.continue4:
        pop de
        ld a, (v_port7ffd)              ; get current flags
        or d                            ; merge in the RAM page flags
        ld (v_port7ffd), a              ; Save the page.
        jr .restoreram4
.next4:
        pop af
        inc a                           ; go to the next page
        cp 0x08                         ; Gone through every page?
        jr nz, .detectloop4
        scf                             ; Oops - couldn't find the string!
        ret

.restoreram4:
        ; Check whether paging really was happening...
        ld a, d                         ; page is in D
        and a                           ; if it's not page zero
        jr nz, .restoreram24             ; then paging really happened
        inc a                           ; if not increment the page and
        and 0x07                        ; see if our string's still there
        ld bc, 0x7FFD
        out (c), a
        call .compare4
        ld a, (v_port7ffd)
        ld bc, 0x7FFD                   ; restore RAM page if it
        out (c), a                      ; actually changed
        jr nz, .restoreram24             ; and restore original RAM

	xor a
	ld (v_machinetype), a		; reset 128K flag
        scf                             ; return with carry set
.restoreram24:
        ld hl, SAVERAM                  ; Restore the original contents
        ld de, 0xC000                   ; of RAM.
        ld bc, SNSTRINGLEN
        ldir
        ret

        ; This routine looks for our string in RAM. Returns with Z
        ; set if the string was found.
.compare4:
        ld hl, 0xC000
        ld de, SNSTRING
        ld bc, SNSTRINGLEN
.cploop4:
        ld a, (de)
        cpi
        ret nz                          ; Not matched.
        inc de
        jp pe, .cploop4
        ret
.data
SNSTRING:        defb "Spectranet detect 7ffd"
SNSTRINGLEN:     equ $-SNSTRING


