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

;--------------------------------------------------------------------------
; F_savesna48
; Save a 48K snapshot. Null terminated filename pointed to by HL.
UNPAGE	equ	0x007C
F_snaptest
	ld hl, STR_saving
	call PRINT42

	ld hl, STR_filename
	ld de, 0x3000
	xor a
.loop
	ldi
	cp (hl)
	jr nz, .loop
.done
	ld (de), a
	ld hl, 0x3000
	call F_savesna48
	jr c, .borked

	ld a, (SNA_EIDI)		; Re.enable interrupts?
	and a				; No
	jr nz, .retei			; If yes, then EI on ret
	ld sp, NMISTACK-14		; Set SP to where the stack was
	pop af
	ex af, af'
	pop af
	pop bc
	pop de
	pop hl
	ld sp, (NMISTACK)
	jp UNPAGE			; RET
.borked
	ld a, 2
	out (254), a
	ret

.retei
	ld sp, NMISTACK-14
	pop af
	ex af, af'
	pop af
	pop bc
	pop de
	pop hl
	ld sp, (NMISTACK)
	jp UNPAGE-1			; EI; RET


STR_saving defb "Saving snapshot.sna...\n",0
STR_filename defb "snapshot.sna",0


;
; Entry to the NMI saves the folowing at NMISTACK-4:
; hl, de, bc, af, af'
F_savesna48
	ld d, O_CREAT | O_TRUNC		; Flags
	ld e, O_WRONLY			; File mode
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
	ld a, i
	ld (SNA_I), a

	ld bc, CTRLREG			; read the border colour
	in a, (c)			; from the CPLD.
	and 0x07			; mask out all the high bits.
	ld (SNA_BORDER), a

	; Now something must be done to detect whether interrups were
	; enabled, and what interrupt mode we're in. Only IM1 and IM2
	; can really be used.
	; Make an IM2 vector table.
	ld hl, 0x3600
	ld de, 0x3601
	ld bc, 258			; table is actually 0x100 bytes
	ld (hl), F_im2 % 256		; LSB of IM 2 routine.
	ldir
	ld a, 0x36			; MSB of the table
	ld i, a				; set the vector table

	ld hl, 0
	ld (v_intcount), hl		; reset IM 1 counter to detect IM 1
	ld hl, .continue		; "Return" address
	push hl				; on the stack so RETN
	retn				; takes us just to the next addr.

.continue	
	ld a, 4				; posit that interrupts are
	ld (SNA_EIDI),a			; enabled.
	ld hl, 3000			; Waste enough T-states so
.loop	dec hl				; that at least one interrupt
	ld a, h				; will occur. (26 T-states per
	or l				; iteration)
	jr nz, .loop

	ld hl, (v_intcount)		; did the counter increase?
	ld a, h
	or l
	jr z, .notim1			; No interrupt occurred in IM 1

	ld a, 1
	ld (SNA_IM), a
	jr .donewithinterrupts

.notim1
	ld a, (SNA_IM)			; did the IM 2 routine record
	cp 2				; IM 2?
	jr z, .donewithinterrupts

	; Now we have to try it all over again after explicitly enabling
	; interrupts.
	xor a
	ld (SNA_EIDI), a		; interrupts weren't enabled
	ei
	ld hl, 3000			; Waste enough T-states so
.loop2	dec hl				; that at least one interrupt
	ld a, h				; will occur.
	or l
	jr nz, .loop2

	ld hl, (v_intcount)		; did intcount update?
	ld a, h
	or l
	jr z, .donewithinterrupts	; Done.

	ld a, 1
	ld (SNA_IM), a			; set interrupt mode 1

	; Now it's all over bar the shouting.
.donewithinterrupts
	di

	; Restore the I register
	ld a, (SNA_I)
	ld i, a

	; TODO: Something ought to be done with the R register, really.
	; Save the interrupts-and-stuff block.
	ld hl, HEADER
	ld bc, HEADERSZ
	ld a, (v_snapfd)
	call WRITE
	jr c, .writeerr

	; Save memory. First, restore screen memory so that it can be
	; saved to the file.
	ld a, 0xDA
        call SETPAGEA
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

	ld hl, 16384			; Start saving from this address
	ld bc, 49152			; For this many bytes
	call F_saveblock
	jr c, .writeerr

.writedone
	ld a, (v_snapfd)		; close the file
	call VCLOSE
	ret

.writeerr
	push af
	ld a, (v_snapfd)
	call VCLOSE
	pop af
	ret

;-----------------------------------------------------------------------
; F_saveblock
; Save a block of memory.
; HL = start address, BC = bytes to write, v_snapfd = fd to write to
F_saveblock
	ld d, b				; Set bytes remaining
	ld e, c				; in DE
.writeloop
	ld a, (v_snapfd)
	push hl
	push de
	call WRITE
	ret c
	pop de
	pop hl
	ex de, hl			; Calculate remaining bytes
	sbc hl, bc
	ret z				; and if none are left, leave.
	ex de, hl
	add hl, bc			; Calculate next address
	ld b, d				; set requested number of bytes
	ld c, e				; to write out.
	jr .writeloop
	ret

