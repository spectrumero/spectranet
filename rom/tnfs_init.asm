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
.include	"ctrlchars.inc"
.include	"tnfs_defs.inc"
.include	"tnfs_sysvars.inc"

; Initialization routines
.text
.globl F_init
F_init:
	call F_inetinit		; Initialize the interface - note not a
				; TNFS function but in this area for practical
				; reasons.

        ld a, (v_pgb)           ; Who are we?
        call RESERVEPAGE        ; Reserve a page of static RAM.
        jr c, .failed1
        ld b, a                 ; save the page number
        ld a, (v_pgb)           ; and save the page we got
        rlca                    ; in our 8 byte area in sysvars
        rlca                    ; which we find by multiplying our ROM number
        rlca                    ; by 8.
        ld h, 0x39              ; TODO - definition for this.
        ld l, a
        ld a, b
        ld (hl), a              ; put the page number in byte 0 of this area.

	call F_fetchpage
	ld hl, 0x1000
	ld de, 0x1001
	ld bc, 0xFFF
	ld (hl), l
	ldir

	; initialize poll time values
	ld a, tnfs_polltime
	ld (v_tnfs_initpolltime), a

	call F_restorepage
	
        ld hl, STR_init
        call PRINT42
        ret
.failed1:
        ld hl, STR_allocfailed
        call PRINT42
        ret
.data
STR_allocfailed: defb    "tnfs: No memory pages available",NEWLINE,0
STR_init:        defb    "TNFS 1.01 initialized",NEWLINE,0
.text
;-----------------------------------------------------------------------------
; F_fetchpage
; Gets our page of RAM and puts it in page area A.
.globl F_fetchpage
F_fetchpage:
	push af
	push hl
	ld a, (v_pgb)		; get our ROM number and calculate
	rlca			; the offset in sysvars
	rlca
	rlca
	ld h, 0x39		; address in HL
	ld l, a
	ld a, (hl)		; fetch the page number
	and a			; make sure it's nonzero
	jr z, .nopage2
	inc l			; point hl at "page number storage"
	ex af, af'
	ld a, (v_pga)
	ld (hl), a		; store current page A
	ex af, af'
	call SETPAGEA		; Set page A to the selected page
	pop hl
	pop af
	or a			; ensure carry is cleared
	ret
.nopage2:
	pop hl			; restore the stack
	pop af
	ld a, 0xFF		; TODO: ENOMEM return code
	scf
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
	ld a, (v_pgb)		; calculate the offset...
	rlca
	rlca
	rlca
	inc a			; +1
	ld h, 0x39
	ld l, a
	ld a, (hl)		; fetch original page
	call SETPAGEA		; and restore it
	pop hl
	pop af
	ret

