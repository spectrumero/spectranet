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
; Pager routines (which don't rely on storing anything on the Spectranet)
.include "spectranet.inc"
.include "sysdefs.inc"

.text

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

; set page B
.globl F_setpageB
F_setpageB:
   push bc
   ld bc, PAGEB
   out (c), a
   pop bc
   ret

