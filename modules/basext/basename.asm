;The MIT License
;
;Copyright (c) 2011 Dylan Smith
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

; The basename function

.include        "defs.inc"
.include        "fcntl.inc"
.include        "spectranet.inc"

;-----------------------------------------------------------------------
; F_basename
; Points HL at the start of the filename in a directory path.
; HL = start of string to search
.globl F_basename
F_basename:
	ld bc, 256
	xor a			; find the end of the string
	cpir			; HL now points at null terminator
	ld a, c
	cpl
	ld b, a	
.findslash:
	dec hl
	ld a, (hl)
	cp '/'			; directory separator
	jr z, .foundslash
	djnz .findslash		; if no / is found, the string is a filename
	ret
.foundslash:
	inc hl			; restore HL to byte after the /
	ret

;-----------------------------------------------------------------------
; F_catpath
; Add the string pointed to by DE to the string pointed to by HL, including
; any slashes if needed.
.globl F_catpath
F_catpath:
	ld bc, 256
	xor a
	cpir			; find the null terminator
	dec hl			; point at null terminator
	ld a, c			; test for empty string
	cp 0xFF
	jr z, .catpath
	dec hl			; point at final char of string
	cp '/'			; separator?
	inc hl			; move past last char
	jr z, .catpath
	ld (hl), '/'		; add the separator
	inc hl
.catpath:
	ld a, (de)		; now copy the file part of the other string
	ld (hl), a
	inc hl
	inc de
	and a			; have we hit the terminator?
	jr nz, .catpath
	ret

	

