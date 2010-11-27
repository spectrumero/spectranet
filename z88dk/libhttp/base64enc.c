/* 
 * The MIT License
 *
 * Copyright (c) 2010 Dylan Smith
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
*/

#include <http.h>

/* callee linkage only */
void base64enc(char *dst, char *src, unsigned int bufsz)
{
#asm
.F_base64enc
	pop hl		; return addr
	pop bc		; bufsz
	pop de		; source
	ex (sp), hl	; destination swapped with return addr
	ex de, hl	; source now in hl, dst in de

        ld a, b
        and a                   ; more than 255?
        jr z, lessthan256
        push bc
        ld b, 3
        call F_encodetriplet
        pop bc
        dec bc
        dec bc
        dec bc
        jr F_base64enc

.lessthan256
        ld b, c
.looplt256
        call F_encodetriplet
        ld a, b
        and a
        jr nz, looplt256
        ret

; HL = pointer to buffer
; DE = buffer to fill with result (must accept 4 bytes)
; B = bytes to encode (1..3)
.F_encodetriplet
                                ; first byte: rotate right two 
        ld c, 0                 ; positions, to make the first index.
        ld a, (hl)              ; Put the lowest two bits into C
        srl a                   ; which will be later used to form
        rr c                    ; the second index
        srl a
        rr c
        call convert
        ld (de), a
        inc de
        dec b
        jr z, padtwo
        inc hl
        ld a, (hl)              ; second byte to encode
        rl c                    ; put second index MSBs into the correct
        rl c                    ; position
        rra                     ; Move second indexes 4 LSBs into the
        rr c                    ; correct position, storing the rest
        rra                     ; in the upper 4 bits of C
        rr c
        rra
        rr c
        rra
        rr c
        call convert
        ld (de), a
        inc de
        dec b
        jr z, padone
        rrc c
        rrc c
        inc hl
        ld a, (hl)
        and 0xC0                ; mask out bottom 6 bits
        rlca
        rlca
        or c
        call convert
        ld (de), a
        inc de
        ld a, (hl)
        and 0x3F                ; bottom 6 bits only
        call convert
        ld (de), a
        dec b
        inc hl                  ; advance counters to the next byte
        inc de
        ret

        ; convert the value in A to the value specified by the LUT
.convert
        push de
        push hl
        ld hl, LUT_base64
        ld d, 0
        ld e, a
        add hl, de
        ld a, (hl)
        pop hl
        pop de
        ret

        ; two of the bits we need are in the two MSBs of C
.padtwo
        ld a, c
        rra
        rra
	call convert
	ld (de), a
        ld a, '='
        inc de
        ld (de), a
        inc de
        ld (de), a
        inc hl
        inc de
        ret

.padone
        ld a, c
        rrca
        rrca
	call convert
	ld (de), a
        inc de
        ld a, '='
        ld (de), a
        inc hl
        inc de
        ret

.LUT_base64
        defm "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        defm "abcdefghijklmnopqrstuvwxyz"
        defm "0123456789"
        defm "+/"
#endasm
}

