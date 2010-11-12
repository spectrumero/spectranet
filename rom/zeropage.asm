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
.include	"sysdefs.inc"
.include	"sysvars.inc"
.include	"spectranet.inc"

; ZEROPAGE ENTRY POINTS
; This file should be included first in "rom.asm0"; it sets the org.
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
.section rst0
RESET:
	di		; This should be done already for a real reset.
	jp J_reset

.section rst8
TRAPBAS:
	jp do_rst8
.section rst10
CALLBAS:
	ld (v_hlsave), hl
	ld (v_desave), de
	pop hl
	jp do_callbas
.section rst28
MODULECALL_NOPAGE:
	jp J_moduledispatch
.section rst30
MODULECALL:
	call J_moduledispatch
	ex (sp), hl		; throw away return to 0x3FF9
	pop hl			
	jr UNPAGE		; unpage and return to caller
.section isr
INTERRUPT:			; 0x0038
	push hl
	ld hl, (v_intcount)	; really, just to indicate that an
	inc hl			; interrupt took place
	ld (v_intcount), hl
	pop hl
	ei
	reti			; TODO - do something!

.section nmi			; 0x0066
	ld (NMISTACK), sp	; save SP
	ld sp, NMISTACK-4	; set up new stack

	; stack everything that will be changed.
	push hl
	push de
	push bc
	push af
	ex af, af'
	push af
	ld hl, (NMISTACK)	; HL = address of the return address
	jr NMI2

	; When unpaging, put the address where you want to end up on
	; the stack, and the RET instruction will set the PC to this address.
.section unpage			; 0x007B
	ei
UNPAGE:
	ret
.text
NMI2:
	ld bc, CTRLREG		; test for trap enable
	in a, (c)
	and MASK_PROGTRAP_EN
	jr z, .nmimenu0		; not enabled
	ld a, (v_trapcomefrom)	; get comefrom address LSB
	cp (hl)			; equal to low order?
	jr nz, .nmimenu0		; no
	inc hl			; return address MSB
	ld a, (v_trapcomefrom+1) ; comefrom MSB
	cp (hl)			; equal to high order?
	jr nz, .nmimenu0		; no

	; Set up the environment ready to handle the trap.
	ld a, (v_trappage)	; get the page to page in
	and a			; if it's zero though, ignore it.
	call nz, F_pushpageB	; page in requested page, stacking current
	ld hl, (v_trapaddr)	; no paging to be done - just get the call addr
	jp (hl)			; jump to it
	
.nmimenu0:
	ld a, 0x02		; Utility ROM
	call F_setpageB
	ld hl, (NMI_VECTOR)	; Test NMI_VECTOR
	ld a, 0xFF
	cp h			; FF = unset
	jr z, .nmidone0
	ld de, .nmidone0		; get return address
	push de			; save it, so subsequent RET comes back
	jp (hl)			; jump to the NMI vector
.nmidone0:
	pop af
	ex af, af'
	pop af
	pop bc
	pop de
	pop hl
	ld sp, (NMISTACK)	; restore stack pointer
	push hl			; munge the stack
	ld hl, UNPAGE		; so that RETN goes via unpage
	ex (sp), hl
	retn

