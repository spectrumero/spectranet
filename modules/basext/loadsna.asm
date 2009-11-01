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

; Functions to load .SNA (snapshot) files

; SNA file definitions
HEADER		equ 0x3000
SNA_I		equ HEADER
SNA_HLALT	equ HEADER+1
SNA_DEALT	equ HEADER+3
SNA_BCALT	equ HEADER+5
SNA_AFALT	equ HEADER+7
SNA_HL		equ HEADER+9
SNA_DE		equ HEADER+11
SNA_BC		equ HEADER+13
SNA_IY		equ HEADER+15
SNA_IX		equ HEADER+17
SNA_EIDI	equ HEADER+19
SNA_R		equ HEADER+20
SNA_AF		equ HEADER+21
SNA_SP		equ HEADER+23
SNA_IM		equ HEADER+25
SNA_BORDER	equ HEADER+26
HEADERSZ	equ 27

;---------------------------------------------------------------------------
; F_loadsna48: Load a 48K snapshot. File handle is in (v_snapfd)
; On error carry is set and A=errno
; On success, snapshot is launched (effectively, we don't return)
F_loadsna48
	di			; don't want the stack getting meddled by int
	ld a, (v_snapfd)
	ld de, HEADER		; where to put the header
	ld bc, 27		; length of the header
	call READ		; read it
	jp c, J_snapdie

	ld de, 16384		; Now fill memory from the frame buffer on
	ld bc, 49152		; size of RAM
	ld hl, 49152		; use HL as a bytes remaining counter
.readloop
	ld a, (v_snapfd)
	push hl
	call READ
	pop hl
	jp c, J_snapdie
	sbc hl, bc		; calculate bytes remaining
	ld b, h			; set requested bytes to remaining
	ld c, l
	jr nz, .readloop
	
	ld a, (v_snapfd)	; close the fd
	call VCLOSE

	; At this point we've successfully loaded the snapshot file.
	; Set register values.
	ld sp, 0x3100		; Temporary stack
	ld hl, (SNA_AFALT)	; Load alternate registers
	push hl
	pop af
	ld hl, (SNA_HLALT)
	ld de, (SNA_DEALT)
	ld bc, (SNA_BCALT)
	exx
	ex af, af'
	ld de, (SNA_DE)
	ld bc, (SNA_BC)
	ld ix, (SNA_IX)
	ld iy, (SNA_IY)
	ld a, (SNA_IM)		; Set the interrupt mode
	and a
	jr nz, .im1
	im 0
	jr .imdone
.im1	cp 1
	jr nz, .im2
	im 1
	jr .imdone
.im2	im 2
.imdone
	ld a, (SNA_I)		; Set the I register
	ld i, a
	ld a, (SNA_BORDER)	; Set the border colour
	out (254), a
	ld hl, (SNA_AF)		; Set AF
	push hl
	pop af
	ld hl, SNA_EIDI		; Interrupt state
	bit 2, (hl)		; nz = enable interrupts
	jr z, .noei		; interrupts are currently disabled anyway
	ld hl, (SNA_HL)		; Set HL
	ld sp, (SNA_SP)		; and SP, finally EI and return via UNPAGE
	ei			; and EI at the last possible moment.
	jp 0x007C
.noei	
	ld hl, (SNA_HL)			
	ld sp, (SNA_SP)		; Snapshot's stack pointer
	jp 0x007C		; unpage
	
J_snapdie
	push af			; preserve error status
	ld a, (v_snapfd)
	call VCLOSE
	pop af
	ret
	
