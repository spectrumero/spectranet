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
.text

; Get an error message.
.globl F_getmessage
F_getmessage: 
	ld a, l			; Get message ID from caller.
	bit 7, a		; MSB set?
	jr z,  .lowtable1
	ld hl, STR_HITABLE
        ld bc, HITABLE_LEN
	sub HITABLE_LOWEST
	jr  .continue1
.lowtable1: 
        ld hl, STRING_TABLE     ; pointer at start of table
        ld bc, ERR_TABLE_LEN
.continue1: 
        and a                   ; code 0 (success?)
        ret z                   ; return now.
	push de			; Save destination address
        ld d, a                 ; set counter
        xor a                   ; reset A to search for terminator
.findloop1: 
        cpir                    ; find next null
        jp po,  .nomsg1           ; cpir ran out of data?
        dec d                   ; decrement loop counter
        jr nz,  .findloop1        ; if Z is not set go for another run

	pop de			; get destination address back
	xor a
.strcpy1: 
	ldi
	cp (hl)			; End of the string?
	jr nz,  .strcpy1
	ld (de), a		; stick the null on the end
	ret

.nomsg1: 
	pop de
	scf
	ret
