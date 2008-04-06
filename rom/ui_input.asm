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

; User Interface input routines - handling the keyboard.
; The keyboard routines use the main ZX ROM to decode key strokes.
; They are designed to hopefully work without needing the ZX ROM itself to
; have initialized (and so can work when the Spectranet has run its RESET
; routine, but before the ZX ROM has done the same).
; The routines are designed to work regardless of the maskable interrupt
; state.

;===========================================================================
; Definitions - special keys returned by K_DECODE (and therefore F_getkey)
KEY_TRUEVID	equ 0x04
KEY_INVVID	equ 0x05
KEY_CAPSLOCK	equ 0x06
KEY_EDIT	equ 0x07
KEY_LEFT	equ 0x08
KEY_RIGHT	equ 0x09
KEY_DOWN	equ 0x0A
KEY_UP		equ 0x0B
KEY_BACKSPACE	equ 0x0C
KEY_ENTER	equ 0x0D
KEY_EXTEND	equ 0x0E
KEY_GRAPH	equ 0x0F

;===========================================================================
; F_getkey:
; Waits for a key to be pressed, and returns the key in A.
; The routine returns the key on keydown. The calling routine should then
; wait for keyup before getting the next key.
F_getkey
.loop
	rst CALLBAS
	defw ZX_KEY_SCAN	; scan the keyboard
	rst CALLBAS
	defw ZX_K_TEST		; test for key press
	jr nc, .loop
	ld e, a			; partially decoded key is in A, copy it to E
	ld d, 8			; not in 'K' cursor mode
	ld c, 0			; FLAGS = 0
	rst CALLBAS
	defw ZX_K_DECODE	; decode keypress into actual ascii value
	ret

;===========================================================================
; F_keyup:
; Waits for the keyboard not being pressed anywhere that will generate
; a character.
F_keyup
.loop
	rst CALLBAS
	defw ZX_KEY_SCAN	; scan the keyboard
	rst CALLBAS
	defw ZX_K_TEST
	jr c, .loop		; carry set = key being pressed
	ret

