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
.include	"spectranet.inc"
.include	"sysvars.inc"

.text 
;-------------------------------------------------------------------------
; F_init: Initialize the snapshot manager.
.globl F_init
F_init: 
	call F_allocpage
	jr c,  .failed1
	ld hl, STR_initialized
	call PRINT42
	ret
.failed1: 
	ld hl, STR_failed
	call PRINT42
	ret

; Claim our memory page, functions to fetch etc.
; Note: Ought to be a library function.

.globl F_allocpage
F_allocpage: 
	ld a, (v_pgb)		; Find our identity
	call RESERVEPAGE
	ret c			; Failed to reserve a page!
	ld b, a			; Save the returned page number
	ld a, (v_pgb)		; Multiply our page number by 8
	rlca			; which gets our index in the fixed
	rlca			; sysvars in 0x3900
	rlca
	ld h, 0x39		; set the MSB
	ld l, a			; and the LSB
	ld (hl), b		; then save the page we got
	inc l			; point at next byte
	ld a, (v_pga)
	ld (hl), a		; save current page A
	ld a, b			; and page in the new page
	call SETPAGEA

	ld hl, 0x1000		; clear the memory
	ld de, 0x1001
	ld bc, 0xFFF
	ld (hl), l
	ldir

	xor a			
	ret

;-----------------------------------------------------------------------------
; F_fetchpage
; Gets our page of RAM and puts it in page area A.
.globl F_fetchpage
F_fetchpage: 
        push af
        push hl
        ld a, (v_pgb)           ; get our ROM number and calculate
        rlca                    ; the offset in sysvars
        rlca
        rlca
        ld h, 0x39              ; address in HL
        ld l, a
        ld a, (hl)              ; fetch the page number
        and a                   ; make sure it's nonzero
        jr z,  .nopage3
        inc l                   ; point hl at "page number storage"
        ex af, af'
        ld a, (v_pga)
        ld (hl), a              ; store current page A
        ex af, af'
        call SETPAGEA           ; Set page A to the selected page
        pop hl
        pop af
        or a                    ; ensure carry is cleared
        ret
.nopage3: 
        pop hl                  ; restore the stack
        pop af
        ld a, 0xFF              ; TODO: ENOMEM return code
        scf
        ret

;---------------------------------------------------------------------------
; F_isallocated
; Tests to see if we have a memory page allocated already.
; Returns nonzero if we have a page
.globl F_isallocated
F_isallocated: 
	push hl
	ld a, (v_pgb)		; get our ROM number
	rlca			; multiply by 8 to find our
	rlca			; fixed sysvars area
	rlca
	ld h, 0x39		; MSB
	ld l, a			; LSB
	ld a, (hl)		; Get the hypothetical page number
	and a			; Test for zero
	pop hl
	ret

;---------------------------------------------------------------------------
; F_restorepage
; Restores page A to its original value.
.globl F_leave
F_leave: 
.globl F_restorepage
F_restorepage: 
        push af
        push hl
        ld a, (v_pgb)           ; calculate the offset...
        rlca
        rlca
        rlca
        inc a                   ; +1
        ld h, 0x39
        ld l, a
        ld a, (hl)              ; fetch original page
        call SETPAGEA           ; and restore it
        pop hl
        pop af
        ret

