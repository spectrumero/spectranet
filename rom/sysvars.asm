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


; The system variables live in chip 4 page 0 which is permanently mapped
; to 0x3000-0x3FFF. Specifically, they live in the upper part of this memory,
; the lower part being available as general purpose workspace.

		org 0x3F00
v_column	defb 0		; Current column for 42 col print.
v_row		defw 0		; Current row address for print routine
v_rowcount	defb 0		; current row number
v_pr_wkspc	defb 0		; Print routine workspace
v_pga		defb 0		; Current memory page in area A
v_pgb		defb 0		; Current memory page in area B
v_chipsel	defb 0		; Current chip select (lower 4 bits)
v_sockptr	defw 0		; Socket register address
v_copylen	defw 0		; Socket copied bytes
v_copied	defw 0		; Socket bytes copied so far

; Socket mappings. These map a file descriptor (see the BSD socket library)
; to a hardware socket. The reason that hardware sockets are not used
; directly is that it'll make it mean a lot of dependent code would need
; a total rewrite if the hardware got changed. W5100 sockets work differently
; to the standard BSD library, and in any case, we don't want to limit
; ourselves to that particular IP implementation in any case.
;
; Most significant bits are flag bits.
;
v_fd1hwsock	defb 0		; hardware socket number
v_fd2hwsock	defb 0
v_fd3hwsock	defb 0
v_fd4hwsock	defb 0
v_fd5hwsock	defb 0
MAX_FDS		equ 5		; maximum number of file descriptors

; General purpose small workspace reserved for ROM routines (for short strings,
; numbers etc.)
v_workspace	defb 0,0,0,0,0,0,0,0
v_bufptr	defw 0		; buffer pointer

; Jump table entries. First two are three bytes long (JP xxxx). Last can
; only fit a JR xx.
		block 0x3FF8-$,0xff
jtable1		defb 0,0,0
jtable2		defb 0,0,0
jtable3		defb 0,0

