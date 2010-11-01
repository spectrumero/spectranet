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

; Functions to load  .SNA0 (snapshot) files
.include	"snapheader.inc"
.include	"snapman.inc"
.include	"fcntl.inc"
.include	"spectranet.inc"

;------------------------------------------------------------------------
; F_loadsnap
; Determine if the filename passed in HL is a snapshot file we can handle
; and call the correct routine to handle it. On error, it returns.
; If no error is encountered, the snapshot is run.
.globl F_loadsnap_modcall
F_loadsnap_modcall: 
	ex de, hl
	push hl			; if called from another program set the
	ld de, v_curfilename	; current filename in case the user enters
	call F_strcpy		; the UI.
	pop hl
.globl F_loadsnap
F_loadsnap: 
        ; simple detection - look at the size to see if it's 48K or 128K
        push hl                 ; save the filename pointer
        ld de, v_statinfo       ; where to put the data from stat
        call STAT
        pop hl
        ret c                   ; can't stat the file

        ld d, 0                 ; no flags
        ld e, O_RDONLY          ; file mode = RO
        call OPEN               ; open the snapshot
        ret c                   ; and return on error.
        ld (v_snapfd), a        ; save the FD

        ld (v_stacksave), sp    ; Save the current stack pointer
        ld sp, v_snapstack      ; Set the stack for snapshot loading.

        ld hl, (v_statinfo+8)	; Less than 64K in size?
        ld a, h
        or l
        jr z,  .fortyeight2

        call F_loadsna128       ; Load a 128K snapshot
        ld sp, (v_stacksave)    ; Restore the stack
        ret
.fortyeight2: 
        call F_loadsna48
        ld sp, (v_stacksave)
        ret

;---------------------------------------------------------------------------
; F_loadsna48: Load a 48K snapshot. File handle is in (v_snapfd)
; On error carry is set and A=errno
; On success, snapshot is launched (effectively, we don't return)
.globl F_loadsna48
F_loadsna48: 
	di			; don't want the stack getting meddled by int
	ld a, (v_snapfd)
	ld de, HEADER		; where to put the header
	ld bc, 27		; length of the header
	call READ		; read it
	jp c, J_snapdie

	call F_readscreen	; Read the screen memory
	jp c, J_snapdie

	ld de, 23296		; Now fill memory from the frame buffer on
	ld bc, 42240		; size of RAM
	ld a, (v_snapfd)
	call READ
	jp c, J_snapdie
	
	ld a, (v_snapfd)	; close the fd
	call VCLOSE

.globl J_unloadheader
J_unloadheader:
	; At this point we've successfully loaded the snapshot file.
	; First deal with the screen.
	call F_restorescreen

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
	jr nz,  .im13
	im 0
	jr  .imdone3
.im13: cp 1
	jr nz,  .im23
	im 1
	jr  .imdone3
.im23: im 2
.imdone3: 
	ld a, (SNA_I)		; Set the I register
	ld i, a
	ld a, (SNA_BORDER)	; Set the border colour
	out (254), a
	ld hl, (SNA_AF)		; Set AF
	push hl
	pop af
	ld hl, SNA_EIDI		; Interrupt state
	bit 2, (hl)		; nz = enable interrupts
	jr z,  .noei3		; interrupts are currently disabled anyway
	ld hl, (SNA_HL)		; Set HL
	ld sp, (SNA_SP)		; and SP, finally EI and return via UNPAGE
	ei			; and EI at the last possible moment.
	jp 0x007C
.noei3: 
	ld hl, (SNA_HL)			
	ld sp, (SNA_SP)		; Snapshot's stack pointer
	jp 0x007C		; unpage

.globl J_snapdie	
J_snapdie:
	push af			; preserve error status
	ld a, 2
	out (254), a
	ld a, (v_snapfd)
	call VCLOSE
	pop af
	ret

;-------------------------------------------------------------------------
; F_readscreen: Read the screen memory into Spectranet RAM
.globl F_readscreen
F_readscreen: 
	ld a, 0xDA		; first page
	call PUSHPAGEA		; switch and store page number
	ld de, 0x1000
	ld bc, 0x1000
	ld a, (v_snapfd)
	call READ
	jr c,  .restoreerr4
	ld a, 0xDB
	call SETPAGEA
	ld de, 0x1000
	ld bc, 0xB00
	ld a, (v_snapfd)
	call READ
.restoreerr4: 
	call POPPAGEA
	ret

;-------------------------------------------------------------------------
; F_loadsna128 - Loads a 128K snapshot.
; File descriptor in (v_snapfd)
; On error carry is set and A=errno
; On success, snapshot is launched (effectively, we don't return)
.globl F_loadsna128
F_loadsna128: 
	ld a, (v_snapfd)
	ld de, HEADER		; where to put the header
	ld bc, HEADERSZ		; length of the header
	call READ
	jp c, J_snapdie

	ld a, 0			; reset port 7FFD
	ld bc, 0x7FFD
	out (c), a
	call F_readscreen
	jp c, J_snapdie
	ld de, 23296		; load the remainder of the lowest 32K 
	ld bc, 25856		; of RAM
	ld a, (v_snapfd)
	call READ
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
.pageloadloop5: 
	ld a, (SNA_7FFD)	; find out what page is paged in 0xC000
	and 7			; to know which to skip loading
	cp d
	jr z,  .next5
	ld a, d
	cp 2			; also skip pages 2 and 5
	jr z,  .next5
	cp 5
	jr z,  .next5

	ld bc, 0x7FFD		; now page in the page that should be
	out (c), d		; loaded.
	push de
	ld de, 0xC000		; the pageable area starts at 0xC000
	ld bc, 16384		; for 16K
	ld a, (v_snapfd)
	call READ
	pop de
	jp c, J_snapdie
.next5: 
	inc d			; increment page number
	ld a, d
	cp 8			; finished?
	jr nz,  .pageloadloop5

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
	ld a, (v_snapfd)
	call READ
	jp c, J_snapdie

	ld a, (v_snapfd)	; Close the file, nothing more to
	call VCLOSE		; be loaded.
	ld sp, (SNA_SP)		; 128K snapshots don't put the return
	ld hl, (SNA_PC)		; address on the stack, but we have to
	push hl			; to be able to exit to the right address.
	ld (SNA_SP), sp
	jp J_unloadheader

	
