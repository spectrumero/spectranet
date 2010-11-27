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

; This code is used to set up the programmable trap.
; The programmable trap may be anywhere in memory. When the CPU fetches
; the instruction at the trap address, a non maskable interrupt is fired.
; Once this instruction is complete, the CPU jumps to the NMI address.

;=========================================================================
; F_settrap: Sets the programmable trap.
; Parameters:
;    hl = Address of a block of memory containing data to set up the trap.
;         Format:
;         byte 0   - Memory page for page B on trap (0 to do no paging)
;         byte 1,2 - Address to call when trap fires
;         byte 3,4 - Address that trap comes from
;         byte 5,6 - Address of the actual trap
.text
.globl F_settrap
F_settrap:
	ld de, v_trappage	; Copy trap details to sysvars
	ld a, (hl)		; check for 0xFF as the page
	cp 0xFF			; since this indicates 'current page B rom'
	jr z, .usecurrent1
	ldi			; copy page
.cprest1:
	ldi			; copy lsb of call address
	ldi			; copy msb of call address
	ldi			; call lsb of comefrom address
	ldi			; call msb of comefrom address

	; (hl) now points at the actual trap address. Note that OUTI
	; affects B so we have to reset it each time! B is pre-decremented.
	ld bc, TRAPSET		; Set trap address I/O port
	inc b
	outi			; set LSB of trap address
	inc b
	outi			; set MSB of trap address
	
	ld bc, CTRLREG		; Read the Spectranet control register
	in a, (c)
	or MASK_PROGTRAP_EN	; enable the programmable trap
	out (c), a		; write new register value
	ret

.usecurrent1:
	ld a, (v_pgb)
	ld (de), a
	inc de
	inc hl
	jr .cprest1

;--------------------------------------------------------------------------
; F_disabletrap
; Disables the programmable trap.
.globl F_disabletrap
F_disabletrap:
	ld bc, CTRLREG
	in a, (c)		; get current control register value
	res BIT_PROGTRAP_EN, a	; reset the trap enable bit
	out (c), a		; write register back
	ret

;--------------------------------------------------------------------------
; F_enabletrap
; Enables the programmable trap
.globl F_enabletrap
F_enabletrap:
	ld bc, CTRLREG
	in a, (c)		; get current control register value
	or MASK_PROGTRAP_EN	; set the trap enable bit
	out (c), a		; and write it back
	ret

;--------------------------------------------------------------------------
; J_pagetrapreturn
; Returns from a trap, restoring page area B, the stack, and unpaging
; the Spectranet
.globl J_pagetrapreturn
J_pagetrapreturn:
	call F_poppageB
;--------------------------------------------------------------------------
; J_trapreturn
; Returns from a trap, restoring the stack and unpaging the Spectranet
.globl J_trapreturn
J_trapreturn:
	pop af
	ex af, af'
	pop af
	pop bc
	pop de
	pop hl
	ld sp, (NMISTACK)	; restore SP
	push hl			; swap HL with the stack to put
	ld hl, PAGEOUT		; the page out address there for RETN
	ex (sp), hl		; restore hl, put page out on stack
	retn

