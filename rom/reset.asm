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
.include	"sysvars.inc"
.include	"sysdefs.inc"
.include	"spectranet.inc"
.include	"w5100_defs.inc"
.include	"flashconf.inc"
.include	"ctrlchars.inc"
.include	"stdmodules.inc"
.include	"page3.xinc"

; Locations in the data rom that need to be copied.
; The jump table lives in the first 256 bytes of ROM3
JUMPTABLE_COPYFROM: 	equ 0x1F00
JUMPTABLE_SIZE:		equ 0xF8
UPPER_ENTRYPT:		equ 0x1FF8
UPPER_ENTRYPT_SIZE:	equ 0x08

; Initialization routines that are run on reset.
;
; The first thing that's done is to page in the configuration area into
; paging area B. This is nominally in the last page of the flash chip
; (page 0x20, chip 0). From this we can figure out what we're supposed
; to do next.
;
.text
.globl J_reset
J_reset:
	; a delay loop to allow the rubber key machine's very slow reset
	; circuit to become quiescent.
	ld bc, 0xFFFF
.delay0:	
	ld (ix+7), a		; a nice long instruction
	dec bc
	ld a, b
	or c
	jr nz, .delay0
	
	; Clear upper page.
	ld sp, NMISTACK		; use our own memory for the stack
	ld hl, 0x3000		; Clear down the fixed RAM page.
	ld de, 0x3001
	ld bc, 0xFFF
	ld (hl), l
	ldir

	; Set up the VFS jump point
	ld a, 0xC3
	ld (VFSJUMP), a
	ld a, 0x20
	ld (VFSJUMP+2), a

	call F_clear		; clear the screen
	ld hl, STR_bootmsg	
	call F_print		; show the boot message
	ld hl, bldstr
	call F_print

	; Initialize some system variables that need it.

	; This is a rather poor way of generating a random number seed,
	; but it's the best we can do given Spectrum hardware. On power
	; up or after each reset, the machine's memory will be in a slightly
	; random state, so we'll CRC it to generate a seed.
	ld de, 23552		; start from the sysvars area
	ld bc, 0x1000
	call F_crc16
	ld (v_seed), hl		; save the CRC in the seed.

	; Set all sockets to the closed state.
	ld hl, v_fd1hwsock	; set all sockets to closed
	ld de, v_fd1hwsock+1
	ld bc, MAX_FDS
	ld (hl), 0x80		; MSB set = closed socket
	ldir

	; Set pollall() 'last file descriptor' to the first fd
	ld a, v_fd1hwsock % 256
	ld (v_lastpolled), a

	; Utility ROM is the default page for handing nmi vector
	ld a, 0x02
	ld (v_nmipage), a

	; Set an initial local port number for connect()
	call F_rand16
	set 6, h		; make sure we start with a highish number
	ld (v_localport), hl	; set initial local port address

	; Initialize any ZX bits that need to be done.
;	call F_zxinit		; not required at present

	ld a, 0x03		; ROM page where jumptable lives
	call F_setpageA		; and page into paging area A.

	; Initialize the jump table by copying it to our RAM.
	ld hl, JUMPTABLE_COPYFROM
	ld de, 0x3E00		; jump table start
	ld bc, JUMPTABLE_SIZE
	ldir

	; Copy the page-in instructions (for the CALL trap)
	ld hl, UPPER_ENTRYPT
	ld de, 0x3FF8
	ld bc, UPPER_ENTRYPT_SIZE
	ldir

	ld hl, J_rst8handler	; Set the RST8 handler vector
	ld (v_rst8vector), hl
	ld hl, TABLE_basext	; Set the BASIC extension table pointer
	ld (v_tabletop), hl
	
	call F_initroms		; Initialize any ROM modules we may have
	ld hl, AUTOMOUNT	; call the automounter
	rst MODULECALL_NOPAGE

	; Detect machine type
;	ld a, 0x03		; ROM with detect routine
;	call F_setpageB
;	call F_machinetype

	ld a, 3			; Page where F_basstart lives
	call F_setpageB
	call F_basstart_setup
	call F_clear

	ld sp, 32767		; lowest guaranteed stack addr
	ld hl, 0		; We're done so put 0x0000 
	push hl			; on the stack
	jp PAGEOUT		; unpage (a ret instruction)

;------------------------------------------------------------------------
; F_initroms
; Pages each 4k page of flash, checking for a boot vector in each.
; When a boot vector is found, that address is CALLed. That ROM then
; gets an opportunity to do whatever initialization it needs to do.
; Note this is how the W5100 actually gets configured - for the 
; Spectranet to work at all, the Spectranet utility ROM must occupy some
; page somewhere in the flash chip and get initialized.
.globl F_initroms
F_initroms:
	ld b, 1		; start from page 2 (page 0=fixed, page 1=data)
	ld hl, vectors	; pointer to the valid vector table
.initloop1:
	inc b
	ld a, 0x1F
	cp b		; last ROM?
	ret z		; finished
	ld a, b
	call F_checkromsig	; Z = valid signature found for executable
	jr z, .rominit1		; Valid sig found
	cp 0xFF			; empty slot
	jr z, .skip1
	ld (hl), 0xFF		; "occupied but not executable"
.skip1:
	inc hl
	jr .initloop1

.rominit1:	
	; Put an entry in the vector table to indicate the ROM page has
	; a valid vector table.
	ld a, (0x2001)		; fetch the ROM ID
	ld (hl), a		; store it in the rom vector table
	inc hl			; point to next entry in the table
	push hl			; save the table address pointer
	push bc			; save which ROM we've examined
	ld hl, (ROM_INIT_VECTOR) ; get initialization vector from ROM
	ld a, 0xFF
	cp h			; does the vector point somewhere useful?
	jr z, .returnaddr1	; no - skip calling it
	ld de, .returnaddr1	; get return address
	push de			; stack it to simulate CALL
	jp (hl)			; and call it
.returnaddr1:	
	pop bc
	pop hl
	jr .initloop1

.data
STR_bootmsg:
	defb "Alioth Spectranet ",0
	include "ver.xinc"	; include the build number file
