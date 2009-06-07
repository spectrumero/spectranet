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

; Filesystem system variables

; Directory entry pointers
v_dirptr1	equ 0x1000
v_dirptr2	equ 0x1001
v_dirptr3	equ 0x1002
v_dirptr4	equ 0x1003
v_dirptr5	equ 0x1004
v_dirptr6	equ 0x1005
v_dirptr7	equ 0x1006
v_dirptr8	equ 0x1007
v_dirptr9	equ 0x1008

v_bytesread	equ 0x1009		; bytes read during a read op, 2 bytes

; File pointers
v_fptr1		equ 0x1010
v_fptr2		equ 0x1012
v_fptr3		equ 0x1014
v_fptr4		equ 0x1016
v_fptr5		equ 0x1018
v_fptr6		equ 0x101A
v_fptr7		equ 0x101C
v_fptr8		equ 0x101E
v_fptr9		equ 0x1020

PTRCTROFFS	equ 0x12

; File counters
v_fctr1		equ 0x1022
v_fctr2		equ 0x1024
v_fctr3		equ 0x1026
v_fctr4		equ 0x1028
v_fctr5		equ 0x102A
v_fctr6		equ 0x102C
v_fctr7		equ 0x102E
v_fctr8		equ 0x1030
v_fctr9		equ 0x1032

