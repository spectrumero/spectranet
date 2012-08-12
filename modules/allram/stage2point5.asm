;The MIT License
;
;Copyright (c) 2012 Dylan Smith
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
.include "spectranet.inc"
.include "fcntl.inc"

; This code is copied to 0x8000. It then loads a ROM image to 0x0000.
.text
.globl F_main
F_main:
	ld sp, 0xFFFF
	call PAGEIN

	; Open a ROM image file (or stage 3 bootloader), read only, from
	; the mounted filesystem.
	ld hl, STR_stage3
	ld de, O_RDONLY
	ld bc, 0x00
	call OPEN
	jp c, E_openfail
	ld (fd), a

	; Read up to 16K 
	ld de, BUF_image
	ld bc, 16384
	call READ
	jp c, E_readfail

	; Close the file
	ld a, (fd)
	call VCLOSE

	; Page out and start the ROM.
	call PAGEOUT
	ld hl, BUF_image
	ld de, 0x0000
	ld bc, 16384
	ldir

	jp 0x0000

E_openfail:
	ld hl, STR_openfail
	call PRINT42
	halt

E_readfail:
	ld hl, STR_readfail
	call PRINT42
	halt

.data
STR_openfail:	defb "Failed to open boot.img",0
STR_readfail:	defb "Failed to read boot.img",0
STR_stage3:	defb "boot.img",0
fd:	defb 0
BUF_image:

