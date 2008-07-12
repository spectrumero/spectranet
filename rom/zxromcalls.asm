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

; Various entry points into the ZX Spectrum main ROM.
; The equ strings are essentially as found in "The Complete Spectrum ROM
; Disassembly", but prepended with 'ZX' so that when browsing the code 
; it's immediately obvious where they come from.

; Fetch the hook/error code
ZX_GET_ERR	equ 0x007B	; page in ROM, ld a, (hl); ret

; Keyboard routines.
ZX_KEY_SCAN	equ 0x028E	; Finds keyboard 'scan code'
ZX_K_TEST	equ 0x031E	; Tests what key is being pressed
ZX_K_DECODE	equ 0x0333	; Decodes K_TEST's output into a character


