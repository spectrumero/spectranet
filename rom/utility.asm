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


; A collection of utility functions:
; F_rand16 - Generate a 16-bit random number
;

;========================================================================
; F_rand16
; Generate a 16 bit random number. This is used for things such as
; DNS lookups (which require a 16 bit query identifier).
; This was adapted from http://map.tni.nl/sources/external/z80bits.html#3.2
; which in turn was adapted from a game (not named).
;
; Pseudorandom number is returned in hl.
F_rand16
	push de
	push af
	ld de, (v_seed)
	ld a,d
	ld h,e
	ld l,253
	or a
	sbc hl,de
	sbc a,0
	sbc hl,de
	ld d,0
	sbc a,d
	ld e,a
	sbc hl,de
	jr nc, .rand
	inc hl
.rand	ld (v_seed),hl
	pop af
	pop de
	ret

