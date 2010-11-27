;The MIT License
;
;Copyright (c) 2010 Dylan Smith
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

; Includes the binary objects needed for the base 4 pages
.data
.globl PAGE0
PAGE0:
.incbin "page0.bin"
.globl PAGE0LEN
PAGE0LEN:	equ $-PAGE0
.globl PAGE1
PAGE1:
.incbin "page1.bin"
.globl PAGE1LEN
PAGE1LEN:	equ $-PAGE1
.globl PAGE2
PAGE2:
.incbin "page2.bin"
.globl PAGE2LEN
PAGE2LEN:	equ $-PAGE2
.globl PAGE3
PAGE3:
.incbin "page3.bin"
.globl PAGE3LEN
PAGE3LEN:	equ $-PAGE3
.globl JUMPTABLE
JUMPTABLE:
.incbin "jumptable.bin"
.globl JUMPTABLELEN
JUMPTABLELEN:	equ $-JUMPTABLE


