;The MIT License
;
;Copyright (c) 2020 Dylan Smith
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

; Minimal utility for getting the flash ID bytes.
; Assumes that only the CPLD and flash chip are available and avoids
; Spectranet RAM.
.include "spectranet.inc"
.include "sysdefs.inc"

.section main
.globl F_main
F_main:
   ld a, 2
   call 0x1601       ; set channel to main screen

   ld hl, STR_intro
   call F_print

   call F_pagein

   ; set page 5 for 0x5555
   ld a, 5
   call F_setpageA
   
   ld a, 0xAA
   ld (0x1555), a    ; flash 0x5555

   ld a, 2
   call F_setpageA

   ld a, 0x55
   ld (0x1AAA), a    ; flash 0x2AAA

   ld a, 5
   call F_setpageA

   ld a, 0x90
   ld (0x1555), a    ; flash 0x5555

   ld hl, (0x0000)   ; manufacturer/device id
   ld (v_devid), hl  ; save it in Spectrum RAM

   ld a, 0xF0        ; exit software id
   ld (0x0000), a

   call F_pageout

   ld hl, STR_mfgid
   call F_print
   ld a, (v_devid)
   call F_inttohex8
   call F_print
   ld a, 0x0d
   rst 16

   ld hl, STR_devid
   call F_print
   ld a, (v_devid+1)
   call F_inttohex8
   call F_print
   ld a, 0x0d
   rst 16

   ret

; pagein/pageout routines
.globl F_pagein
F_pagein:
   di
   ld bc, CTRLREG
   ld a, 1
   out (c), a
   ret

.globl F_pageout
F_pageout:
   ld bc, CTRLREG
   xor a
   out (c), a
   ei
   ret

; set page A
.globl F_setpageA
F_setpageA:
   push bc
   ld bc, PAGEA
   out (c), a
   pop bc
   ret

; print routine - hl=string pointer to null-terminated string
; uses Spectrum ROM
.globl F_print
F_print:
   ld a, (hl)
   and a
   ret z
   rst 16
   inc hl
   jr F_print

; make a hex string from a byte
.globl F_inttohex8
F_inttohex8:
	push af
	push bc
	ld hl, v_workspace
	ld b, a
	call	.Num1
	ld a, b
	call	.Num2
	xor a
	ld (hl), a	; add null
	pop bc
	pop af
	ld hl, v_workspace
	ret

.Num1:	rra
	rra
	rra
	rra
.Num2:	or	0xF0
	daa
	add	a,0xA0
	adc	a,0x40

	ld	(hl),a
	inc	hl
	ret

.data
STR_intro:     defb "Getting flash id...",0x0d,0
STR_mfgid:     defb "Manufacturer: ",0
STR_devid:     defb "Device      : ",0

.bss
v_devid:       defw 0
v_workspace:   defw 0,0,0,0


