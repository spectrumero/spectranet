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
SNA_PC		equ HEADER+27		; 128K .SNA file - program counter
SNA_7FFD	equ HEADER+29		; value of port 0x7FFD
SNA_TRDOS	equ HEADER+30		; TR-DOS flag

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
	call F_readblock
	jp c, J_snapdie
	
	ld a, (v_snapfd)	; close the fd
	call VCLOSE

J_unloadheader
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
	ld a, 2
	out (254), a
	ld a, (v_snapfd)
	call VCLOSE
	pop af
	ret

;-------------------------------------------------------------------------
; F_readblock: Read a big block of data into memory
; DE = address to start putting data
; BC = number of bytes
; On error returns with carry set.
F_readblock
	ld h, b			; Use hl as a bytes remaining counter
	ld l, c
.readloop
	ld a, (v_snapfd)
	push hl
	call READ
	pop hl
	ret c
	sbc hl, bc		; calculate bytes remaining
	ld b, h			; set requested bytes to remaining
	ld c, l
	jr nz, .readloop
	ret

;-------------------------------------------------------------------------
; F_loadsna128 - Loads a 128K snapshot.
; File descriptor in (v_snapfd)
; On error carry is set and A=errno
; On success, snapshot is launched (effectively, we don't return)
F_loadsna128
	ld a, (v_snapfd)
	ld de, HEADER		; where to put the header
	ld bc, HEADERSZ		; length of the header
	call READ
	jp c, J_snapdie

	ld a, 0			; reset port 7FFD
	ld bc, 0x7FFD
	out (c), a
	ld de, 16384		; load the first 32K
	ld bc, 32768
	call F_readblock
	jp c, J_snapdie

	; I think it was a bit pointless making 128K snapshots compatible
	; with 48K by putting the first 48K in without having saved the
	; contents of port 0x7FFD. But this is what we have.
	; Because of this we must seek forwards 16K, get the information
	; we need to find out where to put the data for 0xC000-0xFFFF
	ld a, (v_snapfd)
	ld de, 0		; seek forwards
	ld hl, 16384		; by 16 kilobytes
	ld c, SEEK_CUR		; from the current position
	call LSEEK
	jp c, J_snapdie

	ld de, SNA_PC		; now load the remaining metadata
	ld bc, 4		; which is 4 bytes long
	ld a, (v_snapfd)
	call READ
	jp c, J_snapdie

	; Load the pages except the paged page, and pages 2 and 5
	ld d, 0			; start with page 0
.pageloadloop
	ld a, (SNA_7FFD)	; find out what page is paged in 0xC000
	and 7			; to know which to skip loading
	cp d
	jr z, .next
	ld a, d
	cp 2			; also skip pages 2 and 5
	jr z, .next
	cp 5
	jr z, .next

	ld bc, 0x7FFD		; now page in the page that should be
	out (c), d		; loaded.
	push de
	ld de, 0xC000		; the pageable area starts at 0xC000
	ld bc, 16384		; for 16K
	call F_readblock
	pop de
	jp c, J_snapdie
.next
	inc d			; increment page number
	ld a, d
	cp 8			; finished?
	jr nz, .pageloadloop

	; Now load the reaming page - for this we need to seek backwards
	; to where it's stored... given that SNA files can be of two lengths
	; seeking from the start is the best.
	ld de, 0		; seek to 32K from the start
	ld hl, HEADERSZ + 32768	; plus the size of the header.
	ld c, SEEK_SET
	ld a, (v_snapfd)
	call LSEEK
	jp c, J_snapdie

	ld a, (SNA_7FFD)	; set port 0x7FFD
	ld bc, 0x7FFD
	out (c), a
	ld de, 0xC000		; load the remaining page
	ld bc, 16384
	call F_readblock
	jp c, J_snapdie

	ld a, (v_snapfd)	; Close the file, nothing more to
	call VCLOSE		; be loaded.
	ld sp, (SNA_SP)		; 128K snapshots don't put the return
	ld hl, (SNA_PC)		; address on the stack, but we have to
	push hl			; to be able to exit to the right address.
	ld (SNA_SP), sp
	jp J_unloadheader

	
