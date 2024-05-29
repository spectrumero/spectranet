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
.text

; Paging functions.
; These functions abstract the pager, which is a CPLD function. They also
; take care of ensuring modifying one paging area doesn't affect the other.
;
; Set paging area A. Page to load in A.
.globl F_setpageA
F_setpageA: 
	push bc
	ld bc, PAGEA
	ld (v_pga), a	; save the page we've just paged.
	out (c), a	; page it in
	pop bc
	ret

; Set paging area B. As for area A.
.globl F_setpageB
F_setpageB: 
	push bc
	ld bc, PAGEB
	ld (v_pgb), a
	out (c), a	; page it in
	pop bc
	ret

; Set paging area A and push the page currently selected onto the stack.
; A = new page to select
.globl F_pushpageA
F_pushpageA: 
	ld (v_pagerws), hl
	ld hl, (v_pga)		; get current page (and the adjacent byte)
	ex (sp), hl		; stack it
	push hl			; put the return address back
	call F_setpageA		; set the new page
	ld hl, (v_pagerws)	; restore hl
	ret

; Restore page area A from the stack
.globl F_poppageA
F_poppageA: 
	ld (v_pagerws), hl
	pop hl			; get the return address
	ex (sp), hl		; get the page to restore
	ld a, l			; the page itself being in L
	call F_setpageA		; restore the page
	ld hl, (v_pagerws)
	ret
	
; Set paging area B and push the page currently selected onto the stack.
; A = new page to select
.globl F_pushpageB
F_pushpageB: 
	ld (v_pagerws), hl
	ld hl, (v_pgb)		; get current page (and the adjacent byte)
	ex (sp), hl		; stack it
	push hl			; put the return address back
	call F_setpageB		; set the new page
	ld hl, (v_pagerws)	; restore hl
	ret

; Restore page area B from the stack
.globl F_poppageB
F_poppageB: 
	ld (v_pagerws), hl
	pop hl			; get the return address
	ex (sp), hl		; get the page to restore
	ld a, l			; the page itself being in L
	call F_setpageB		; restore the page
	ld hl, (v_pagerws)
	ret
	
