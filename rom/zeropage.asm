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

; ZEROPAGE ENTRY POINTS
; This file should be included first in "rom.asm"; it sets the org.
;
; RST 0xNN instructions - This is where all the restarts live:
; 00	Reset
; 08	Entry point for BASIC traps
; 10	CALLBAS restart for BASIC extensions
; 18
; 20
; 28
; 30
; 38	Maskable interrupt service routine
; 
; NMI entry point at 0x0066
; Unpage entry point at 0x007C

	org 0x0000
RESET
	di		; This should be done already for a real reset.
	jp J_reset

	block 0x08-$,0xFF
TRAPBAS
	jp do_rst8
	block 0x10-$,0xFF
CALLBAS
	ld (v_hlsave), hl
	ld (v_desave), de
	pop hl
	jp do_callbas

	block 0x38-$,0xFF
INTERRUPT
	reti		; TODO - do something!

	block 0x66-$,0xFF
NMI
	retn

	block 0x7C-$,0xFF
	; When unpaging, put the address where you want to end up on
	; the stack, and the RET instruction will set the PC to this address.
UNPAGE
	ret

