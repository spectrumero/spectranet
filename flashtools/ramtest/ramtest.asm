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
;
; Minimal utility to check that RAM works.
.include "spectranet.inc"
.include "sysdefs.inc"

.section main
.globl F_main
F_main:
   ld a, 2
   call 0x1601       ; set channel to main screen

   ld hl, STR_intro  ; print intro msg
   call F_print

   call F_pagein     ; page in Spectranet, disable interrupts
   
   ld a, 0xC0        ; first page of RAM
.writeloop:
   call F_setpageA
   ld (0x1000), a    ; store page id in first byte of page
   inc a
   cp 0xE0           ; finished?
   jr nz, .writeloop

   ld a, 0xC0        ; back to first page to prepare for read back
   ld hl, v_readback ; place to copy bytes read back
.readloop:
   call F_setpageA
   push af
   ld a, (0x1000)
   ld (hl), a
   pop af
   inc hl
   inc a
   cp 0xE0           ; finished?
   jr nz, .readloop

   call F_pageout    ; get access to ROM routines again

   ld hl, STR_expected
   call F_print

   ld hl, v_readback
   ld b, 0x20
.resultprint:
   ld a, (hl)
   push hl
   call F_inttohex8
   call F_print
   ld a, ' '
   rst 16
   pop hl
   inc hl
   djnz .resultprint

   ld a, 0x0d
   rst 16
   ret
   
.data
STR_intro:     defb "Static RAM basic function test",0x0d,0
STR_expected:  defb "Expected: count from C0 to DF",0x0d,0

.bss
v_readback:    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

