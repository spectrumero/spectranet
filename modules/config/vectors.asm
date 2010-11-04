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

; Filesystem Configuration Utility module

; This is a ROM module.
.section vectors
sig:     defb 0xAA               ; This is a ROM module
romid:   defb 0xFE               ; ID = 0xFE
reset:   defw F_init             ; reset vector
mount:   defw 0xFFFF             ; not a filesystem
         defw 0xFFFF
         defw 0xFFFF
         defw 0xFFFF
         defw 0xFFFF
idstr:   defw STR_ident          ; ROM identity string

modcall:
	ex af, af'		; preserve any args in A
	xor a
	cp l			; 0x00? Configuration menu.
	jp z, F_if_configmain	; TODO: modcalls other than this

	inc a
	cp l			; 0x01
	jp z, F_cond_copyconfig

	inc a
	cp l			; 0x02
	jp z, F_findsection

	inc a
	cp l			; 0x03
	jp z, F_getCFString

	inc a
	cp l			; 0x04
	jp z, F_getCFByte

	inc a
	cp l			; 0x05
	jp z, F_getCFWord

	inc a
	cp l
	jp z, F_createsection	; 0x06

	inc a
	cp l			; 0x07
	jp z, F_commitConfig
	
	inc a
	cp l
	jp z, F_setCFByte	; 0x08
	
	inc a
	cp l
	jp z, F_setCFWord	; 0x09
	
	inc a
	cp l	
	jp z, F_setCFString	; 0x0A

	inc a
	cp l	
	jp z, F_abandonConfig	; 0x0B

	ld a, l
	cp 0xFF			; 0xFF
	jp z, F_createnewconfig

	ld a, 0xFF
	scf
	ret

