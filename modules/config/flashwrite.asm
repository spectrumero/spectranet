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

FLASHPROGSTART:
.globl F_updateflash
F_updateflash: 
        di
        ld a, (v_pga)
        push af
        ld a, (v_pgb)
        push af
        ld a, 0x1C              ; last sector of flash
        call F_FlashEraseSector
        jr c,  .cleanup1
        ld a, 0x1C              ; start page to write
        call F_writesector
.cleanup1: 
        ex af, af'              ; preserve flags
        pop af
        call SETPAGEB
        pop af
        call SETPAGEA
        ex af, af'
        ei
        ret

