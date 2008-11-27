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

; Page allocation routines, that allows code (mostly ROM modules) to reserve
; a page of static RAM in some kind of orderly way.
;
; The last 6 pages of RAM are used for temporary workspace and can't be
; reserved. (Anyone can use them, though, but another module or program
; can also write there). The first page (0xC0) is permanently mapped to
; 0x3000-0x3FFF and can't be reserved either.
;
; The rest of RAM should only be used after being reserved to ensure that
; you don't trample on the workspace of a ROM module. Reservation routines
; are here and work on the level of 1 page (4K).

;---------------------------------------------------------------------------
; F_reservepage
; Reserves a page. On entry, pass the ROM ID that is making the request in A.
; Pass 0xFF if it's just a general program, and not a module.
; On return, A contains the page reserved. If no pages are free the carry
; flag is set.
F_reservepage
	ld b, 25		; number of RAM pages that can be reserved
	ld hl, pagealloc	; search the page allocation table for a page 
	ex af, af'		; save A
.searchloop
	ld a, (hl)		; examine current page
	and a			; is it zero (unallocated) ?
	jr z, .pagefound
	djnz .searchloop
	scf			; if we get here no free pages were found.
	ret
.pagefound
	ex af, af'		; get originally passed value
	ld (hl), a		; mark the page allocated
	ld a, l			; calculate the page
	sub pagealloc % 256 	; by looking at the table position
	add LOWEST_PAGE		; and adding the lowest possible page
	ret

;--------------------------------------------------------------------------
; F_freepage
; Frees a page. Pass the page number in A.
F_freepage
	ld hl, pagealloc
	sub LOWEST_PAGE		; find offset in table
	add a, l		; add table base address
	ld l, a			; now hl points to it
	ld (hl), 0		; clear it
	ret	
