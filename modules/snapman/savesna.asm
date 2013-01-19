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

; Save snapshots in SNA format.
.include	"fcntl.inc"
.include	"stat.inc"
.include	"snapheader.inc"
.include	"snapman.inc"
.include	"spectranet.inc"
.include	"sysvars.inc"

.text 
;--------------------------------------------------------------------------
; F_savesna48
; Save a 48K snapshot. Null terminated filename pointed to by HL.
UNPAGE	equ	0x007C
SAVERAM	equ	0x3600
MAINSPSAVE equ	0x35FE
TEMPSP	equ	0x81FE

.globl F_snaptest
F_snaptest: 
	ld hl, STR_saving
	call PRINT42

	ld hl, STR_filename
	ld de, 0x3000
	xor a
.loop1: 
	ldi
	cp (hl)
	jr nz,  .loop1
.done1: 
	ld (de), a
	ld hl, 0x3000
	call F_savesna
	jr c,  .borked1

	ld a, (v_border)		; Restore the border
	out (254), a
	call F_restorescreen		; Restore the screen
	ld a, (SNA_EIDI)		; Re.enable interrupts?
	and a				; No
	jr nz,  .retei1			; If yes, then EI on ret
	ld sp, NMISTACK-14		; Set SP to where the stack was
	pop af
	ex af, af'
	pop af
	pop bc
	pop de
	pop hl
	ld sp, (NMISTACK)
	jp UNPAGE			; RET
.borked1: 
	ld a, 2
	out (254), a
	ret

.retei1: 
	ld sp, NMISTACK-14
	pop af
	ex af, af'
	pop af
	pop bc
	pop de
	pop hl
	ld sp, (NMISTACK)
	jp UNPAGE-1			; EI; RET

;------------------------------------------------------------------------
; HL = pointer to filename string
; Entry to the NMI saves the folowing at NMISTACK-4:
; hl, de, bc, af, af'
.globl F_savesna
F_savesna: 
	ld de, O_CREAT | O_TRUNC | O_WRONLY
	ld bc, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH	; mode 0644
	call OPEN			; Open the snapshot file
	ret c
	ld (v_snapfd), a		; save the file descriptor

	ld hl, HEADER			; Clear down the header information
	ld de, HEADER+1			; temporary storage.
	ld bc, HEADERSZ-1
	ld (hl), l
	ldir

	ld hl, (STACK_HL)		; Start by saving the registers we can
	ld (SNA_HL), hl
	ld hl, (STACK_DE)
	ld (SNA_DE), hl
	ld hl, (STACK_BC)
	ld (SNA_BC), hl
	ld hl, (STACK_AFALT)
	ld (SNA_AFALT), hl
	ld hl, (STACK_AF)
	ld (SNA_AF), hl
	ld hl, (NMISTACK)		; SP when NMI happened
	ld (SNA_SP), hl
	ld (SNA_IX), ix
	ld (SNA_IY), iy
	exx				; do the alternate set
	ld (SNA_HLALT), hl
	ld (SNA_DEALT), de
	ld (SNA_BCALT), bc
	exx
	ld a, i				; also sets P/V flag if IFF2 is
	ld (SNA_I), a			; set (interrupts enabled)
	call pe,  .setei2
	
	ld a, (v_border)		; Copy the border colour into
	ld (SNA_BORDER), a		; the snapshot header.

	; Now something must be done to detect interrupt mode
	ld hl, 0x3600
	ld de, 0x3601
	ld bc, 258			; table is actually 0x100 bytes
	ld (hl), F_im2_lsb		; LSB of IM 2 routine.
	ldir
	ld a, 0x36			; MSB of the table
	ld i, a				; set the vector table

	ld hl, 0
	ld (v_intcount), hl		; reset IM 1 counter to detect IM 1
	ld hl,  .continue2		; "Return" address
	push hl				; on the stack so RETN
	retn				; takes us just to the next addr.

.continue2: 
	xor a
	ld (SNA_IM), a			; clear IM x
	ei
	halt				; wait for an interrupt
	ld a, (SNA_IM)			; Did the IM 2 routine update
	and a				; the interrupt mode?
	jr nz,  .donewithinterrupts2	; Done.

	inc a				 
	ld (SNA_IM), a			; set interrupt mode 1

	; Now it's all over bar the shouting.
.donewithinterrupts2: 
	di

	; Restore the I register
	ld a, (SNA_I)
	ld i, a

	; Detect whether we're saving a 48K or a 128K snapshot
	ld a, (v_machinetype)		
	and 1				; Bit 1 set = 128K
	jr nz,  .save128snap2

	call  .savemain2			; save header and memory
.writedone2: 
	ld a, (v_snapfd)		; close the file
	call VCLOSE
	ret

.writeerr2: 
	push af
	ld a, (v_snapfd)
	call VCLOSE
	pop af
	ret
.setei2: 
	ld a, 4
	ld (SNA_EIDI), a
	ret

.save128snap2: 
	; copy port 0x7FFD value to the header
	ld a, (v_port7ffd)
	ld (SNA_7FFD), a

	; adjust header suitably for 128K snapshots
	ld hl, (SNA_SP)			; The stack pointer must be
	ld e, (hl)			; adjusted and the PC must be
	inc hl				; obtained.
	ld d, (hl)			; PC now in DE
	inc hl
	ld (SNA_SP), hl			; Set the snapshot SP.
	ld (SNA_PC), de			; Set the PC
	xor a
	ld (SNA_TRDOS), a		; TRDOS always 0
	call  .savemain2			; the header + 48K
	jr c,  .writeerr2

	ld hl, SNA_PC			; Save the 128K second header
	ld bc, 4			; (4 bytes long)
	ld a, (v_snapfd)
	call WRITE
	jr c,  .writeerr2

	; Save the 128K pages at 0xC000.
	ld a, (SNA_7FFD)		; Skip the page we've aready
	and 7				; saved (as it was in 0xC000)
	ld e, a
	xor a				; start from page 0
.save128loop2: 
	cp e				; skip the page that was already
	jr z,  .next2			; saved, also skip pages 2 and 5
	cp 0x02
	jr z,  .next2
	cp 0x05
	jr z,  .next2
	ld bc, 0x7FFD			; set the page we want to save
	out (c), a

	push af
	push de
	ld hl, 0xC000
	ld bc, 0x4000
	ld a, (v_snapfd)
	call WRITE
	jr c,  .writeerr1282
	pop de
	pop af
.next2: 
	inc a
	cp 0x08				; all pages have been saved
	jr nz,  .save128loop2
	ld a, (SNA_7FFD)		; restore 128K paging but with
	and 0xF7			; but ensure the normal screen
	ld bc, 0x7FFD			; is in use for the NMI menu
	out (c), a
	jr  .writedone2

.writeerr1282: 
	pop de
	pop de				; don't overwrite AF
	jr  .writeerr2

.savemain2: 
	; TODO: Something ought to be done with the R register, really.
	; Save the interrupts-and-stuff block.
	ld hl, HEADER
	ld bc, HEADERSZ
	ld a, (v_snapfd)
	call WRITE
	ret c

	; Save screen RAM.
	call F_savesavedscreen

	ld hl, 23296			; Start saving from this address
	ld bc, 42240			; For this many bytes
	ld a, (v_snapfd)
	call WRITE
	ret

;----------------------------------------------------------------------
; F_savesavedscreen
; Save the screen that was copied to 0xDA:000 to 0xDB:AFF
.globl F_savesavedscreen
F_savesavedscreen: 
	ld a, 0xDA			; first page
	call PUSHPAGEA			; set it and save current page
	ld hl, 0x1000
	ld bc, 0x1000
	ld a, (v_snapfd)
	call WRITE
	jr c,  .restoreerr3
	ld a, 0xDB
	call SETPAGEA
	ld hl, 0x1000
	ld bc, 0xB00
	ld a, (v_snapfd)
	call WRITE
.restoreerr3: 
	call POPPAGEA			; restore original page
	ret

.globl F_restorescreen
F_restorescreen: 
	ld a, 0xDA
	call PUSHPAGEA
	ld hl, 0x1000
	ld de, 0x4000
        ld bc, 0x1000
        ldir
        ld a, 0xDB
        call SETPAGEA
        ld hl, 0x1000
        ld de, 0x5000
        ld bc, 0xB00
        ldir
	call POPPAGEA
        ret

