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
	ei
	reti		; TODO - do something!

	block 0x66-$,0xFF
NMI
	; stack everything that will be changed.
	push hl
	push de
	push bc
	push af
	ex af, af'
	push af
	ld hl, 10
	add hl, sp	; hl now points at return address
	jr NMI2

	block 0x7C-$,0xFF
	; When unpaging, put the address where you want to end up on
	; the stack, and the RET instruction will set the PC to this address.
UNPAGE
	ret
NMI2
	ld bc, CTRLREG		; test for trap enable
	in a, (c)
	and MASK_PROGTRAP_EN
	jr z, .nmimenu		; not enabled
	ld a, (v_trapcomefrom)	; get comefrom address LSB
	cp (hl)			; equal to low order?
	jr nz, .nmimenu		; no
	inc hl			; return address MSB
	ld a, (v_trapcomefrom+1) ; comefrom MSB
	cp (hl)			; equal to high order?
	jr nz, .nmimenu		; no

	; Set up the environment ready to handle the trap.
	ld a, (v_trappage)	; get the page to page in
	and a			; if it's zero though, ignore it.
	call nz, F_pushpageB	; page in requested page, stacking current
	ld hl, (v_trapaddr)	; no paging to be done - just get the call addr
	jp (hl)			; jump to it
	
.nmimenu
	ld a, 0x02		; Utility ROM
	call F_setpageB
	call F_pagezxbasic	; ensure the BASIC ROM is paged in
	ld hl, (NMI_VECTOR)	; Test NMI_VECTOR
	ld a, 0xFF
	cp h			; FF = unset
	jr z, .nmidone
	ld de, .nmidone		; get return address
	push de			; save it, so subsequent RET comes back
	jp (hl)			; jump to the NMI vector
.nmidone
	call F_pagezxrestore	; restore original 128K paging settings
	pop af
	ex af, af'
	pop af
	pop bc
	pop de
	ld hl, UNPAGE		; munge the stack so that RETN goes via unpage
	ex (sp), hl
	retn

