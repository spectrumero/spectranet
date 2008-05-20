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

; Initialization routines that are run on reset.
;
; The first thing that's done is to page in the configuration area into
; paging area B. This is nominally in the last page of the flash chip
; (page 0x20, chip 0). From this we can figure out what we're supposed
; to do next.
;
J_reset
	; Clear upper page.
	;ld sp, INITSTACK	; temporary stack when booting
	ld hl, 0x3000		; Clear down the fixed RAM page.
	ld de, 0x3001
	ld bc, 0xFFF
	ld (hl), 0
	ldir

	call F_clear		; clear the screen
	ld hl, STR_bootmsg	
	call F_print		; show the boot message

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

	; Set an initial local port number for connect()
	call F_rand16
	set 6, h		; make sure we start with a highish number
	ld (v_localport), hl	; set initial local port address

	; Initialize any ZX bits that need to be done.
	call F_zxinit

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


;	call F_initroms		; Initialize any ROM modules we may have

	; TODO: The proper routine to read the configuration, and set
	; the MAC address.
	call F_tempsetup
	
	ld hl, STR_unpaging	
	call F_print

	ld hl, 0		; We're done so put 0x0000 
	push hl
	jp UNPAGE		; unpage (a ret instruction)

;------------------------------------------------------------------------
; F_initroms
; Pages each 4k page of flash, checking for a boot vector in each.
; When a boot vector is found, that address is CALLed. That ROM then
; gets an opportunity to do whatever initialization it needs to do.
; Note this is how the W5100 actually gets configured - for the 
; Spectranet to work at all, the Spectranet utility ROM must occupy some
; page somewhere in the flash chip and get initialized.
F_initroms
	ld hl, 1	; start from page 1 - page 0 is the fixed page.
	ld de, vectors	; pointer to the valid vector table
	ld (v_workspace), de	; save it
.initloop
	ld a, 0x20	; last ROM?
	cp l
	ret z		; finished
	push hl
	call F_checkromsig	; Z = valid signature found
	pop hl
	inc hl
	jr nz, .initloop	; No valid ROM signature
	
	; Put an entry in the vector table to indicate the ROM page has
	; a valid vector table.
	ld de, (v_workspace)	; get vector pointer
	ld a, l
	ld (de), a		; save ROM page number in the vector table
	inc de			; point to next entry in the table
	ld (v_workspace), de	; and save.

	push hl
	ld hl, (ROM_INIT_VECTOR) ; get initialization vector from ROM
	ld a, 0xFF
	cp h			; does the vector point somewhere useful?
	jr z, .returnaddr	; no - skip calling it
	ld de, .returnaddr	; get return address
	push de			; stack it to simulate CALL
	jp (hl)			; and call it
.returnaddr	
	pop hl
	jr .initloop

; This is a temporary W5100 setup routine, to do the bare minimum basic
; setup.
F_tempsetup
	; Page in the W5100
	; Chip selects put RAM in area B, W5100 in area A
	ld hl, 0x0100		; registers are in page 0 of the W5100
	call F_setpageA		; page it into area A

	; Perform a software reset by setting the reset flag in the MR.
	ld a, MR_RST
	ld (MR), a

	; Set memory mapped mode, all options off.
	xor a
	ld (MR), a

	; set the MAC address
	ld hl, CFG_HWADDR
	ld de, SHAR0		
	ld bc, 6
	ldir

	; set up the socket buffers: 2k per socket buffer.
	ld a, 0x55
	ld (TMSR), a
	ld (RMSR), a
	
	; set the IMR
	ld a, %11101111
	ld (IMR), a

	; set a dns server
	ld hl, CFG_DNS
	ld de, v_nameserver1
	ldi
	ldi
	ldi
	ldi

	ret
CFG_HWADDR 	defb 0xAA,0x17,0x0E,0x00,0x3B,0xA6
CFG_DNS		defb 83,218,26,5

STR_bootmsg
	defb "Alioth Spectranet (beta)\n",0
STR_unpaging
	defb "Unpaging\n",0
