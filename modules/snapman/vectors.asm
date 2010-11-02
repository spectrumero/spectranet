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

; Snapshot manager extensions vector table
.include	"snapheader.inc"
.section vectors
.vectorstart:
        defb 0xAA               ; This is a code ROM
        defb 0xFB               ; ROM ID = 0xFC
        defw F_init             ; RESET vector
        defw 0xFFFF             ; the next few vectors are reserved
        defw 0xFFFF
        defw 0xFFFF
        defw 0xFFFF
        defw 0xFFFF
        defw STR_ident          ; Pointer to a string that identifies this mod
        jp F_modulecall
.fillstart:
	.fill 0x20-(.fillstart-.vectorstart), 1, 0xFF

.section isr
;-----------------------------------------------------------------------
; F_im2 - Detect interrupt mode 2 ISR
.globl F_im2
.globl F_im2_lsb
F_im2_lsb	equ 0x20
F_im2: 
        push af
        ld a, 2
        ld (SNA_IM), a
        pop af
        reti

.text
.globl F_modulecall
F_modulecall: 
	ld a, l
	and a			; call 0 = start UI
	jp z, F_startui
	cp 1
	jp z, F_loadsnap_modcall
	scf
	ret	

