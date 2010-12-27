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

; Definitions

v_totalcfgsz		equ 0x8400	; Total configuration size location
CONFIG_BASE_ADDR	equ 0x8400	; Base address of the config data
MAXCFGSZ		equ 0xEFF	; last 256 byte page for core...
CFG_RAM_PAGE		equ 0xDF
CFG_FLASH_PAGE		equ 0x1F
INTERPWKSPC		equ 0x9000
v_configptr		equ 0x8300
v_hlsave		equ 0x8302
v_pga			equ 0x8304
v_pgb			equ 0x8305
FLASHPROGSTART		equ 0x0000
FLASHPROGLEN		equ 0x0002

