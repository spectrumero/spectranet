; The MIT License
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

; BAISC streams support
; Vector table
.include	"defs.inc"
.section vectors
	defb 0xAA		; This is a code ROM
        defb STREAM_ROM_ID      ; Rom ID 0x01
        defw F_init             ; RESET vector
        defw 0xFFFF             ; the next few vectors are reserved
        defw 0xFFFF
        defw 0xFFFF
        defw 0xFFFF
        defw 0xFFFF
        defw STR_ident          ; Pointer to a string that identifies this mod
	jp J_modcall		; we have a module call routine
.data
STR_ident:
	defb "Streams 1.01",0
