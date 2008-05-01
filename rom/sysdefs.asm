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

; Sysdefs.asm
;
; Miscellaneous system defines.
;
CHIPSEL		equ 0xED	; CPLD memory chip select register (4 bit) (wo)
PAGEA		equ 0xE9	; CPLD page area A 4k page (8 bit) (wo)
PAGEB		equ 0xEB	; CPLD page area B 4k page (8 bit) (wo)
CTRLREG		equ 0xEF	; CPLD control register (rw)

; Initialization stack - until the Spectrum has initialized its main
; ROM we don't really know what we have, but there's definitely some
; RAM here.
INITSTACK	equ 0xFFFF

; Vectors in flash rom pages
ROM_INIT_VECTOR	equ 0x2000
RST8_VECTOR	equ 0x2002
INT_VECTOR	equ 0x2004
RESRVD2_VECTOR	equ 0x2006
RESRVD3_VECTOR	equ 0x2008
RESRVD4_VECTOR	equ 0x200A
RESRVD5_VECTOR	equ 0x200C
RESRVD6_VECTOR	equ 0x200E
ROM_SIG_CRC	equ 0x2010

