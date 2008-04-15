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

; Simple menu system routines.

;--------------------------------------------------------------------------
; F_genmenu
; Generates a menu screen.
; Parameters: HL = pointer to menu structure, that should be a null terminated
; list of pointers to strings that define the choices.
F_genmenu
	ld b, 'A'	; first option is 'A'
.loop
	ld e, (hl)	; get pointer into DE
	inc hl
	ld d, (hl)
	inc hl
	ld a, d
	or e		; check to see whether we've just got the last one
	ret z
	ld a, '['
	call F_putc_5by8	; print [
	ld a, b
	call F_putc_5by8	; print the option
	ld a, ']'
	call F_putc_5by8	; print ]
	ld a, ' '
	call F_putc_5by8	; and one space separator
	ex de, hl		; get string pointer into hl
	call F_print		; print the menu option
	ex de, hl		; move the menu pointer back
	ld a, '\n'		; print a CR
	call F_putc_5by8
	inc b			; update option character
	jr .loop

