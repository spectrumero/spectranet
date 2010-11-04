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
TRAPSET		equ 0x023B	; CPLD programmable trap (write only)
PAGEA		equ 0x003B	; CPLD page area A 4k page (8 bit) (wo)
PAGEB		equ 0x013B	; CPLD page area B 4k page (8 bit) (wo)
;CTRLREG		equ 0x033B	; CPLD control register (rw)

; Control register bit mask
MASK_PAGEIN	equ 1		; I/O pagein (read/write)
MASK_EXECTRAP	equ 2		; Execution trap (read only) 1 if true
MASK_CALLTRAP	equ 4		; Call trap (read only) 1 if true
MASK_PROGTRAP_EN equ 8		; Programmable trap enabled (r/w) 1 if true

; ...and bit positions
BIT_PAGEIN	equ 0
BIT_EXECTRAP	equ 1
BIT_CALLTRAP	equ 2
BIT_PROGTRAP_EN	equ 3

; Initialization stack - until the Spectrum has initialized its main
; ROM we don't really know what we have, but there's definitely some
; RAM here.
INITSTACK	equ 0xFFFF

; Vectors in flash rom pages
ROM_INIT_VECTOR	equ 0x2002
MOUNT_VECTOR	equ 0x2004
INT_VECTOR	equ 0x2006
NMI_VECTOR	equ 0x2008
BASSTART_VECTOR	equ 0x200A
RESRVD4_VECTOR	equ 0x200C
RESRVD5_VECTOR	equ 0x200E

; Page definitions
LOWEST_PAGE	equ 0xC1

