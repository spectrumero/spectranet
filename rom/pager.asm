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


; Paging functions.
; These functions abstract the pager, which is a CPLD function. They also
; take care of ensuring modifying one paging area doesn't affect the other.
;
; Set paging area A. Page to load in A.
F_setpageA
	push bc
	ld bc, PAGEA
	ld (v_pga), a	; save the page we've just paged.
	out (c), a	; page it in
	pop bc
	ret

; Set paging area B. As for area A.
F_setpageB
	push bc
	ld bc, PAGEB
	ld (v_pgb), a
	out (c), a	; page it in
	pop bc
	ret

; Set paging area A and push the page currently selected onto the stack.
; A = new page to select
F_pushpageA
	ld (v_pagerws), hl
	ld hl, (v_pga)		; get current page (and the adjacent byte)
	ex (sp), hl		; stack it
	push hl			; put the return address back
	call F_setpageA		; set the new page
	ld hl, (v_pagerws)	; restore hl
	ret

; Restore page area A from the stack
F_poppageA
	ld (v_pagerws), hl
	pop hl			; get the return address
	ex (sp), hl		; get the page to restore
	ld a, l			; the page itself being in L
	call F_setpageA		; restore the page
	ld hl, (v_pagerws)
	ret
	
; Set paging area B and push the page currently selected onto the stack.
; A = new page to select
F_pushpageB
	ld (v_pagerws), hl
	ld hl, (v_pgb)		; get current page (and the adjacent byte)
	ex (sp), hl		; stack it
	push hl			; put the return address back
	call F_setpageB		; set the new page
	ld hl, (v_pagerws)	; restore hl
	ret

; Restore page area B from the stack
F_poppageB
	ld (v_pagerws), hl
	pop hl			; get the return address
	ex (sp), hl		; get the page to restore
	ld a, l			; the page itself being in L
	call F_setpageB		; restore the page
	ld hl, (v_pagerws)
	ret
	
;--------------------------------------------------------------------------
; J_hldispatch and J_ixdispatch:
; Dispatches a page-in from the call table, and unpages when it's done
J_hldispatch
	ld (v_pagerws), hl	; save HL without disturbing the stack
	ld hl, UNPAGE		; unpage address
	push hl			; this is now the return address
	ld hl, (v_pagerws)	; restore hl
	jp (hl)			; jump to routine.
J_ixdispatch
	ld (v_pagerws), hl	; save HL without disturbing the stack
	ld hl, UNPAGE
	push hl			; this is now the return address
	ld hl, (v_pagerws)	; restore hl
	jp (ix)			; jump to routine.

;-------------------------------------------------------------------------
; J_moduledispatch
; Finds the ROM module for the call to be handed off. The ROM ID is in
; H.
J_moduledispatch
	ex af, af'		; save af
	push hl			; save hl
	push bc			; save bc
	ld b, h			; get ROM module ID
	ld hl, vectors		; start of vector table
.findcall
	ld a, (hl)		; get ROM ID from table
	and a			; check for terminator
	jr z, .notfound
	cp b			; ROM ID to look for
	jr nz, .findcall
.found
	ld a, l			; get vector address LSB
	sub vectors % 256 - 2	; subtract the base to get the ROM slot
	pop bc
	pop hl
	call F_pushpageB	; select the page and stack the existing
	ex af, af'		; get original AF value
	call 0x2010		; enter ROM module
	call F_poppageB
	ret
.notfound
	scf			; return with "function not found"
	ld a, -1
	ret

