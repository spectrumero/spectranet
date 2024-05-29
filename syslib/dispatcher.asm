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
.include	"spectranet.inc"
.include	"sysdefs.inc"
.include        "sysvars.inc"
.text

;--------------------------------------------------------------------------
; J_hldispatch and J_ixdispatch:
; Dispatches a page-in from the call table, and unpages when it's done
.globl J_hldispatch
J_hldispatch:
	ld (v_pagerws), hl	; save HL without disturbing the stack
	ld hl, PAGEOUT		; unpage address
	push hl			; this is now the return address
	ld hl, (v_pagerws)	; restore hl
	jp (hl)			; jump to routine.
.globl J_ixdispatch
J_ixdispatch:
	ld (v_pagerws), hl	; save HL without disturbing the stack
	ld hl, PAGEOUT
	push hl			; this is now the return address
	ld hl, (v_pagerws)	; restore hl
	jp (ix)			; jump to routine.

;-------------------------------------------------------------------------
; J_moduledispatch
; Finds the ROM module for the call to be handed off. The ROM ID is in
; H. The call number is in L. This routine just needs H (L is handled by
; the module)
.globl J_moduledispatch
J_moduledispatch:
	ex af, af'		; save af
	push hl			; save hl
	push bc			; save bc
	ld b, h			; get ROM module ID
	ld hl, vectors		; start of vector table
.findcall6: 
	ld a, (hl)		; get ROM ID from table
	and a			; check for terminator
	jr z,  .notfound6
	inc l			; increment table pointer
	cp b			; ROM ID to look for
	jr nz,  .findcall6
.found6: 
	ld a, l			; get vector address LSB
	sub vectors % 256 - 1	; subtract the base to get the ROM slot
	pop bc
	pop hl
	call F_pushpageB	; select the page and stack the existing
	ex af, af'		; get original AF value
	call 0x2010		; enter ROM module
	ex af, af'
	ld (v_hlsave), hl
	call F_poppageB
	ld hl, (v_hlsave)
	ex af, af'
	ret
.notfound6: 
	pop bc
	pop hl
	scf			; return with "function not found"
	ld a, -1
	ret

