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
	ld a, DATAROM		; key scan routines live here
	call F_pushpageA
.loop
	call key_scan
	call key_test
	jr nc, .loop
	ld e, a			; partially decoded key is in A, copy it to E
	ld d, 8			; not in 'K' cursor mode
	ld c, 0			; FLAGS = 0
	call key_code		; decode keypress into actual ascii value
	ld c, a
	call F_poppageA		; restore original page A
	ld a, c
	ret

;===========================================================================
; F_keyup:
; Waits for the keyboard not being pressed anywhere that will generate
; a character.
F_keyup
	ld a, DATAROM		; key scan routines live here
	call F_pushpageA
.loop
	call key_scan
	call key_test
	jr c, .loop		; carry set = key being pressed
	call F_poppageA
	ret

;===========================================================================
; F_inputstring:
; Get a string from the keyboard, and null terminate.
; Parameters: DE = pointer to memory to store the string.
;              C = size of buffer (string length + 1, for the null terminator)
F_inputstring
	ei
	ld b, c			; save length in b
	ld (v_stringptr), de	; save the pointer
	ld (v_stringlen), bc	; save the string lengths
.inputloop
	ld a, '_'		; cursor - possible TODO - flashing cursor?
	call F_putc_5by8	; display it
.keyloop
	call F_keyup		; wait for keyup before doing anything
	call F_getkey		; wait for a key to be pressed.
	halt			; and do it for long enough that all the
	halt			; contacts on multilayer membranes are
	call F_getkey		; closed.
	cp KEY_ENTER		; enter pressed?
	jr z, .enter		; handle enter
	cp KEY_BACKSPACE	; backspace pressed?
	jr z, .backspace	; handle it
	cp ' '			; space - lowest printable character
	jp m, .keyloop		; do nothing for non-printable char
	ex af, af'
	ld a, (v_stringlen)	; get remaining buffer size back
	cp 1			; and if only one byte is left,
	jr z, .keyloop		; don't accept more input.
	call F_backspace	; backspace over the cursor
	ex af, af'		; get keypress back
	ld hl, (v_stringptr)	; get current string pointer
	ld (hl), a		; save entered key
	inc hl			; update pointer
	ld (v_stringptr), hl	; save pointer
	call F_putc_5by8	; and print the char
	ld a, (v_stringlen)	; get the remaining byte count
	dec a			; decrement it
	ld (v_stringlen), a	; save remaining length	
	jr .inputloop		; and wait for the next key.	
.backspace
	ld bc, (v_stringlen)	; is the cursor at the start
	ld a, c			; of the string?
	cp b			
	jr z, .keyloop		; yes - so just wait for another key.

	; To update the screen, the cursor and the character behind
	; it must be removed, hence two calls to F_backspace.
	inc a			; increase the remaining byte count
	ld (v_stringlen), a	; and save it
	ld hl, (v_stringptr)	; get the string pointer
	dec hl			; rewind the string pointer
	ld (v_stringptr), hl	; save it
	call F_backspace	; remove cursor
	call F_backspace	; remove last character
	jr .inputloop
.enter
	call F_backspace	; erase the cursor
	ld hl, (v_stringptr)	; get the string pointer
	ld (hl), 0		; put the null terminator on the string
	ret

