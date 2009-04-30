;The MIT License
;
;Copyright (c) 2009 Dylan Smith
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

; These functions just wrap the character output routines, giving a
; ROM 0 entry point to get to them.

;--------------------------------------------------------------------------
; F_putc_5by8 
; Print characters 42 columns per line.
; The 'core' of the putchar routine, F_print calls this directly (handling
; the paging itself)
; The routine could probably do with improvement.
F_putc_5by8
	call F_pr_getroutine
	call F_putc_5by8_impl
	jp F_pr_restore

;--------------------------------------------------------------------------
; F_print: Prints a null terminated string.
; Parameters: HL = pointer to string
F_print
	call F_pr_getroutine
	call F_print_impl
	jp F_pr_restore

;--------------------------------------------------------------------------
; F_clear: Clears the screen to spectranet UI colours.
F_clear
	call F_pr_getroutine
	call F_clear_impl
	jp F_pr_restore

;--------------------------------------------------------------------------
; F_backspace:  Perform a backspace (move current character position 1
; back and delete the right most character).
F_backspace
	call F_pr_getroutine
	call F_backspace_impl
	jp F_pr_restore

;--------------------------------------------------------------------------
; The following routines just fetch and restore the ROM page where the
; output routines are kept.
F_pr_getroutine
	push af
	ld a, (v_pga)		; save page A value
	ld (v_pr_pga), a
	ld a, DATAROM
	call F_setpageA		; fetch the data rom
	pop af
	ret

F_pr_restore
	push af
	ld a, (v_pr_pga)
	call F_setpageA
	pop af
	ret
