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
; Set paging area A. Page in HL (chip in H, page in L)
F_setpageA
	push bc
	ld bc, 0x8000|CHIPSEL
	ld a, (v_chipsel)
	and 0xFC	; zero lower two bits
	or h		; insert chip select value
	ld (v_chipsel), a
	out (c), a
	ld a, l
	ld (v_pga), a	; store new page number
	ld c, PAGEA
	out (c), a	; page it in
	pop bc
	ret

; Set paging area B. As for area A.
F_setpageB
	push bc
	ld bc, 0x8000|CHIPSEL
	ld a, (v_chipsel)
	and 0xF3	; zero upper 2 bits of nibble
	rl h		; move chip select value into correct bits
	rl h		
	or h		; insert chip select value
	ld (v_chipsel), a
	out (c), a	
	ld a, l
	ld (v_pgb), a
	ld c, PAGEB
	out (c), a	; page it in
	ret

;--------------------------------------------------------------------------
; F_pushpageB
; Page in the page requested in HL, saving the last value on the stack.
; F_poppageB reverses the action.
F_pushpageB
	ld a, (v_chipsel)
	ld d, a
	ld a, (v_pgb)
	ld e, a
	call F_setpageB	; set the page in hardware
	pop hl		; get return address
	push de		; replace with saved page
	push hl		; restore return address
	ret

;--------------------------------------------------------------------------
; F_poppageB
; Get page area B values off the stack and restore the hardware to the
; state saved on the stack.
F_poppageB
	pop de		; get return address
	pop hl		; get paging settings
	push de		; restore return address
	ld a, l
	ld (v_pgb), a
	ld a, h
	and 0xFC	; mask out page A chip selects
	ld h, a		; save it
	ld a, (v_chipsel)
	and 0xF3	; mask out page B chip selects
	or h		; and merge with page B
	ld bc, 0x8000|CHIPSEL
	out (c), a	; restore hardware
	ld c, PAGEB
	out (c), a
	ret

