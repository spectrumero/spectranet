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

ZX_PRINT_A_1	equ 0x0010	; Prints a character to the current stream
ZX_GET_CHAR	equ 0x0018	; The 'collect a character' restart
ZX_NEXT_CHAR	equ 0x0020	; The 'collect next character' restart
ZX_GET_ERR	equ 0x007B	; page in ROM, ld a, (hl); ret
ZX_CLS_LOWER	equ 0x0D6E	; clear the last two lines of the screen
ZX_ERRMSG_RET	equ 0x1349	; return to ZX ROM print error msg routine
ZX_SET_MIN	equ 0x16B0	; Reset editing areas
ZX_SET_WORK	equ 0x16BF	; Clear workspace and calculator stack
ZX_SET_STK	equ 0x16C5	; Clear the calculator stack
ZX_RECLAIM_2	equ 0x19E8	; Reclaim bytes pointed to by HL
ZX_E_LINE_NO	equ 0x19FB	; Read the line number of the line being edited
ZX_STMT_R_1	equ 0x1B7D	; Fetch new line number unless a further stmt
ZX_STMT_NEXT	equ 0x1BF4	; Get next statement (or finish with error C)
ZX_NEXT_2NUM	equ 0x1C79	; Evaluate next 2 numbers 
ZX_FIND_INT2	equ 0x1E99	; Find 2 byte integer

; Keyboard routines.
ZX_KEY_SCAN	equ 0x028E	; Finds keyboard 'scan code'
ZX_K_TEST	equ 0x031E	; Tests what key is being pressed
ZX_K_DECODE	equ 0x0333	; Decodes K_TEST's output into a character


