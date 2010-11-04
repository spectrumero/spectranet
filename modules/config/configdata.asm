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
.include	"configdefs.inc"
.include	"sysvars.inc"
.include	"spectranet.inc"
.text

; Find, read and insert configuration data.
;	include "debug.asm"A
;-----------------------------------------------------------------------
; F_cond_copyconfig: Conditionally copy the configuration (if it's not
; been copied already)
.globl F_cond_copyconfig
F_cond_copyconfig:
        call F_getsysvar        ; see if we've already copied it
        inc hl
        ld a, 1
        cp (hl)                 ; if Z we've already made a copy
        ret z
        ld (hl), 1              ; Indicate a copy has been made.
	jp F_copyconfig

;-----------------------------------------------------------------------
; F_findsection: Finds where in memory a configuration section lives
; and returns the address in HL.
; Section ID to find is in DE.
; Carry is set if the section was not found.
.globl F_findsection
F_findsection: 
	call F_mappage
	call F_findsection_core
	jp F_leave

.globl F_findsection_core
F_findsection_core: 
	ld hl, CONFIG_BASE_ADDR		; Start here.
	ld a, (hl)
	inc hl
	or (hl)				; check that there's actually data
	jr z,  .notfound2			; no configuration data at all

.findloop2: 
	inc hl				; point to first section
	ld a, (hl)			; compare against DE
	inc hl
	cp e
	jr nz,  .findnext2
	ld a, (hl)
	cp d
	jr nz,  .findnext2
	inc hl				; HL points at the section size
	ld (v_configptr), hl		; save the pointer
	ret

.findnext2: 
	cp 0xFF				; Check we've not hit the end.
	jr z,  .checkend2
.findnext12: 
	inc hl
	ld c, (hl)			; LSB of the section size word
	inc hl
	ld b, (hl)			; MSB
	add hl, bc			; point HL at the next entry
	jr  .findloop2
.checkend2: 
	dec hl
	ld a, (hl)
	cp 0xFF
	jr z,  .notfound2
	inc hl				; undo the DEC operation
	jr  .findnext12

.notfound2: 
	scf
	ret

;-------------------------------------------------------------------------
; F_createsection: Creates a new empty section.
; DE = id of section to create
; Carry is set if the section can't be created.
.globl F_createsection
F_createsection: 
	call F_mappage
	push de
	call F_findsection_core		; does the section already exist?
	pop de
	jp nc, F_leave			; if so nothing to do.

	ld hl, (v_totalcfgsz)		; get total size
	ld bc, CONFIG_BASE_ADDR		; set the base address
	add hl, bc			; find last address
	ld (hl), e			; write section id
	inc hl
	ld (hl), d
	inc hl
	ld (v_configptr), hl		; set the current section ptr
	ld (hl), 0x00			; write size (zero bytes)
	inc hl
	ld (hl), 0x00
	inc hl
	ld (hl), 0xFF			; write terminator
	inc hl
	ld (hl), 0xFF
	ld hl, (v_totalcfgsz)		; update configuration size
	inc hl
	inc hl
	inc hl
	inc hl
	ld (v_totalcfgsz), hl

	jp F_leave

;-------------------------------------------------------------------------
; F_createnewconfig
; Creates a brand new empty config area.
.globl F_createnewconfig
F_createnewconfig: 
	call F_mappage

	xor a
	ld (CONFIG_BASE_ADDR+1), a	; msb of size
	cpl
	ld (CONFIG_BASE_ADDR+2), a	; 0xFFFF = terminator
	ld (CONFIG_BASE_ADDR+3), a
	ld a, 2
	ld (CONFIG_BASE_ADDR), a
	jp F_leave

;-------------------------------------------------------------------------
; F_getcfgstring: Get an item that is a string.
; A = id of item to get.
; DE = where to place the result
.globl F_getCFString
F_getCFString: 
	ex af, af'		; get arg
	call F_mappage

	push de
	call F_findcfgitem
	pop de
	jp c, F_leave	
	inc hl
.cpstring5: 
	ldi
	ld a, (hl)
	and a
	jr nz,  .cpstring5
.addnull5: 
	ld (de), a		; put the NULL on the end
	jp F_leave

;-------------------------------------------------------------------------
; F_getCFWord: Get a 2 byte configuration item into HL
; A = id of the item.
.globl F_getCFWord
F_getCFWord: 
	ex af, af'		; get arg
	call F_mappage

	call F_findcfgitem
	jp c, F_leave
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
	jp F_leave

;-------------------------------------------------------------------------
; F_getCFByte: Get a 1 byte configuration item into A
; A = id of the item
.globl F_getCFByte
F_getCFByte: 
	ex af, af'		; get arg
	call F_mappage

	call F_findcfgitem
	jp c, F_leave
	inc hl
	ld a, (hl)
	jp F_leave

;-------------------------------------------------------------------------
; F_addCFByte: Add 1 byte configuration item.
; A = id of the item
; C = value to add
.globl F_addCFByte
F_addCFByte: 
	push af
	and 0xC0
	cp 0x80			; check that this is a valid byte id
	jr nz,  .error8
	push bc
	ld hl, (v_configptr)	; set HL to where room is to be made
	inc hl
	inc hl			; point at address where we want to add it
	push hl
	ld bc, 2		; how much room is needed
	call F_makeroom
	pop hl
	pop bc
	jr c,  .error8
	pop af
	ld (hl), a		; id of the item
	inc hl
	ld (hl), c		; value of the item
	jp F_leave

.error8: 
	pop af
	scf
	jp F_leave

;-------------------------------------------------------------------------
; F_addCFWord: Add 2 byte configuration item.
; A = id of the item
; BC = value to add
.globl F_addCFWord
F_addCFWord: 
	push af
	and 0xC0
	cp 0xC0			; check that this is a valid word id
	jr nz,  .error9
	push bc
	ld hl, (v_configptr)	; set HL to where room is to be made
	inc hl
	inc hl			; point at address where we want to add it
	push hl
	ld bc, 3		; how much room is needed
	call F_makeroom
	pop hl
	pop bc
	jr c,  .error9
	pop af
	ld (hl), a		; id of the item
	inc hl
	ld (hl), c		; value of the item
	inc hl
	ld (hl), b
	jp F_leave

.error9: 
	pop af
	scf
	jp F_leave

;-------------------------------------------------------------------------
; F_addCFString: Adds a string value. Null terminated string should be
; pointed to by DE, with its ID in A
.globl F_addCFString
F_addCFString: 
	ex af, af'		; get arg
	call F_mappage
	call F_addCFString_core
	jp F_leave

.globl F_addCFString_core
F_addCFString_core: 
	push de
	push af
	and 0xC0
	and a			; check that this is a valid string id
	jr nz,  .error11

	ex de, hl
	ld bc, 0xFF
	cpir			; find the NULL
	ld a, c
	cpl			; turn low order of BC into string length
	ld c, a			; BC = length
	push bc
	inc bc			; add 1 to give space for id
	ld hl, (v_configptr)
	inc hl
	inc hl			; point at address where we want to add it
	push hl
	call F_makeroom
	pop hl			; get address of 1st byte of new space
	pop bc
	jr c,  .error11
	pop af
	ld (hl), a
	inc hl
	ex de, hl
	pop hl			; get string's address
	
	ldir			; copy the string
	ret
.error11: 
	pop af
	pop de
	ret

;-------------------------------------------------------------------------
; F_setCFString
; Config strings can be variable length so we delete it first and recreate
; it.
.globl F_setCFString
F_setCFString: 
	ex af, af'
	call F_mappage
	push af
	push de
	call F_rmcfgitem_core	; if it already exists it must be removed
	pop de
	pop af
	call F_addCFString_core
	jp F_leave

;-------------------------------------------------------------------------
; F_setCFWord
; Set or change a word value.
; A = byte ID, BC = new value
.globl F_setCFWord
F_setCFWord: 
	ex af, af'
	call F_mappage
	push af
	push bc
	call F_findcfgitem
	pop bc
	jp c,  .add13			; not found, add it
	pop af
	inc hl				; point at word's LSB
	ld (hl), c
	inc hl
	ld (hl), b
	jp F_leave
.add13: 
	pop af
	jp F_addCFWord

;-------------------------------------------------------------------------
; F_setCFByte
; Change a byte value.
; A = byte ID, C = new value
.globl F_setCFByte
F_setCFByte: 
	ex af, af'
	call F_mappage
	push af
	push bc
	call F_findcfgitem		; get the address of the byte 
	pop bc
	jr c,  .add14			; Not found, add it
	pop af
	inc hl				; point at value
	ld (hl), c
	jp F_leave
.add14: 
	pop af
	jp F_addCFByte

;-------------------------------------------------------------------------
; F_findcfgitem
; A = cfg item to find
; Finds a configuration item with the supplied ID.
; Returns with HL set to the address of the item on success. Carry set
; on error.
.globl F_findcfgitem
F_findcfgitem: 
	ld hl, (v_configptr)
	ld c, (hl)			; LSB of section size
	inc hl
	ld b, (hl)			; MSB of section size
	inc hl

.findloop15: 
	ld e, a				; save A
	ld a, b
	or c				; check that the section is not done
	jr z,  .notfound15
	ld a, e				; restore A
	cp (hl)				; Is this the section we're after?
	ret z				; Found - return.

	bit 7, (hl)			; String value?
	jr z,  .skipstring15

	bit 6, (hl)			; Word or byte?
	inc hl
	dec bc
	inc hl
	dec bc
	jr z,  .findloop15			; byte is skipped at this stage
	inc hl
	dec bc
	jr  .findloop15			; word is skipped at this stage
.skipstring15: 
	ld e, a				; save A
	inc hl
	dec bc
	xor a				; find the next NULL terminator
	cpir
	ld a, e
	jr  .findloop15

.notfound15: 
	scf
	ret

;-------------------------------------------------------------------------
; F_rmcfgitem
; A = config item to remove
.globl F_rmcfgitem
F_rmcfgitem: 
	ex af, af'			; retrieve arg in A
	call F_mappage
	call F_rmcfgitem_core
	jp F_leave

.globl F_rmcfgitem_core
F_rmcfgitem_core: 
	call F_findcfgitem
	ret c				; Not found
	bit 7, (hl)			; String value?
	jr z,  .rmstring17
	bit 6, (hl)			; Word or byte?
	jr z,  .compact217
	ld bc, 3
	call F_compact
	ret
.compact217: 
	ld bc, 2
	call F_compact
	ret
.rmstring17: 
	push hl				; find the length of the
	ld bc, 0xFF			; string.
	xor a
	cpir
	ld a, c
	cpl
	ld c, a
	pop hl
	call F_compact
	ret

;-------------------------------------------------------------------------
; F_compact
; Compact the configuration area by BC bytes, deleting the item (that's BC
; bytes long) at HL.
.globl F_compact
F_compact: 
	ex de, hl
	ld ix, (v_configptr)
	ld l, (ix+0)
	ld h, (ix+1)
	sbc hl, bc			; set area bytes to new value
	ld (ix+0), l
	ld (ix+1), h
	
	ld h, d
	ld l, e
	adc hl, bc			; where to start copying from

	push hl
	push de
	ld hl, (v_totalcfgsz)		; get total configuration size
	ld de, CONFIG_BASE_ADDR
	adc hl, de			; last byte address
	inc hl				; plus terminator bytes
	inc hl
	pop de
	sbc hl, de			; how many bytes until the end
	push hl
	ld hl, (v_totalcfgsz)		; reduce the size of the
	sbc hl, bc			; total configuration
	ld (v_totalcfgsz), hl
	pop bc
	pop hl

	ldir				; shift everything down
	ret

;-------------------------------------------------------------------------
; F_makeroom
; Makes some space for a new configuration item.
; BC = how much to make
.globl F_makeroom
F_makeroom: 
	; update sizes
	ld hl, (v_totalcfgsz)
	ld (v_hlsave), hl		; save it for later
	adc hl, bc
	call F_checkcfgsize
	ret c
	ld (v_totalcfgsz), hl
	ld ix, (v_configptr)
	ld l, (ix+0)
	ld h, (ix+1)
	adc hl, bc
	ld (ix+0), l
	ld (ix+1), h

	; calculate how many bytes to move
	ld de, (v_hlsave)		; get original size
	ld hl, CONFIG_BASE_ADDR
	adc hl, de			; last address
	inc hl				; including the terminator
	ld (v_hlsave), hl		; save this value for later
	ld de, (v_configptr)		; put new room at the start
	inc de				; of the section
	inc de
	sbc hl, de			; hl = number of bytes to move 
	ld d, b				; amount of room to make
	ld e, c
	ld b, h				; number of bytes to move
	ld c, l
	
	; calculate destination address
	ld hl, (v_hlsave)		; get last address
	adc hl, de			; hl = destination address
	ex de, hl
	ld hl, (v_hlsave)		; get last address (now source)
	inc bc
	lddr				; move the data

	ret

	; returns with C set if the size is too great.
.globl F_checkcfgsize
F_checkcfgsize: 
	ld a, MAXCFGSZ/256
	cp h
	ret c
	ret nz
	ld a, MAXCFGSZ%256
	cp l
	ret

;------------------------------------------------------------------------
; F_abandonConfig: Abandon the RAM copy of the configuration (mark it
; uncopied, so further accesses to config go to flash)
.globl F_abandonConfig
F_abandonConfig: 
	call F_getsysvar
	inc hl
	ld (hl), 0		; reset "RAM copy" flag
	ret	

;------------------------------------------------------------------------
; F_commitConfig: Commits the configuration in RAM to flash.
.globl F_commitConfig
F_commitConfig: 
	call F_getsysvar	; make sure that a RAM copy has been made
	inc hl
	ld a, 1
	cp (hl)
	jr nz,  .notpaged22
	ld (hl), 0		; clear down "RAM copy" flag

	; copy the flash programmer
	ld hl, FLASHPROGSTART
	ld de, 0x3000
	ld bc, FLASHPROGLEN
	ldir

	; call the flash programmer and we should be done.
	call 0x3000

	ret

.notpaged22: 		; do not write flash if it hasn't already
	scf			; been copied to RAM.
	ret

;------------------------------------------------------------------------
; F_mappage
; Maps the page. If we've copied the configuration, RAM should be mapped,
; if not, flash.
.globl F_mappage
F_mappage: 
	push af
	push hl
	call F_getsysvar
	ld a, (v_pga)
	ld (hl), a		; save current page A in private area
	inc hl
	ld a, (hl)		; has a shadow copy been made?
	cp 1			; 1 = yes
	jr nz,  .getflash23

	ld a, CFG_RAM_PAGE	; set page A to the flash config
	call SETPAGEA

	pop hl
	pop af
	ret

.getflash23: 
	ld a, CFG_FLASH_PAGE
	call SETPAGEA
	pop hl
	pop af
	ret

.globl F_getsysvar
F_getsysvar: 
	ld a, (v_pgb)		; what's our page?
	rlca
	rlca
	rlca
	ld h, 0x39		; address of module's private workspace
	ld l, a
	ret			; hl points at private area

.globl F_leave
F_leave: 
	push af
	push hl
	call F_getsysvar
	ld a, (hl)
	call SETPAGEA
	pop hl
	pop af
	ret

	
