;
;Copyright (c) 2009 Dylan Smith
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

; Private variables for streams.
; They occupy the block at 0x1100.

flagaddr	equ 0x1100	; address of current flags being used
oneof_line	equ 0x1102	; Line to go to on EOF
onerror_line	equ 0x1104	; Line to go to on error
original_zx_prog equ 0x1106	; Original value of PROG
current_zx_prog	equ 0x1108	; Current value of PROG
v_curchan	equ 0x110A	; Current channel being serviced

stream_memptr	equ 0x1110	; Free memory block pointer
memptr_bottom	equ 0x1112	; Free memory block start, 32 bytes long
chmemptr_bottom	equ 0x1132	; Used memory block start, 32 bytes long

