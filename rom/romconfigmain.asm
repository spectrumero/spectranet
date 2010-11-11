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

; ROM configuration utility main routine.
.include	"spectranet.inc"
.include	"ctrlchars.inc"
.include	"sysvars.inc"

;--------------------------------------------------------------------------
; F_romconfigmain: Main loop
.section main
.globl F_romconfigmain
F_romconfigmain:
	call CLEAR42
	ld hl, STR_installed
	call PRINT42
	call F_showroms
	call F_configmenu
	jr z, F_romconfigmain
	
	; page back in caller
	ld a, 0x02		; utility ROM
	call SETPAGEB
	ret
.text
;--------------------------------------------------------------------------
; F_showroms - Shows the current available ROMs.
.globl F_showroms
F_showroms:
	ld a, 0x02		; first valid ROM slot
.disploop2:
	call SETPAGEB
	push af
	ld a, (0x2000)		; check signature byte
	cp 0xFF			; end?
	jr z, .exit2		; exit routine
	cp 0xAA			; ROM module?
	jr nz, .putdatarom2	; no, list as "data"
	pop af			; get ROM number
	push af
	call .printid2		; print its id
	ld hl, (0x200E)		; get the identity string
	call PRINT42		; print the identity
	ld a, NEWLINE
	call PUTCHAR42
	pop af
	inc a
	jr .disploop2
.exit2:
	pop af
	ret

.putdatarom2:
	pop af
	push af
	call .printid2
	ld hl, STR_datarom
	call PRINT42
	pop af
	inc a
	jr .disploop2

.printid2:
	ld hl, v_workspace	; workspace to load with value
	call ITOH8
	ld a, '['
	call PUTCHAR42
	ld hl, v_workspace
	call PRINT42		; print the ROM number in hex
	ld a, ']'
	call PUTCHAR42
	ld a, ' '
	call PUTCHAR42
	ret

;-------------------------------------------------------------------------
; F_findfirstfreepage
; Finds the first free ROM page, returning it in A.
; Search starts from the first user page, page 0x04. Returns with the
; carry flag set if no free pages are available.
.globl F_findfirstfreepage
F_findfirstfreepage:
	ld a, 0x04
.loop3:
	call SETPAGEB
	ex af, af'
	ld a, (0x2000)
	cp 0xFF			; FF = free page
	jr z, .found3
	ex af, af'
	cp 0x1F			; Last page?
	jr z, .nospace3
	inc a
	jr .loop3
.nospace3:
	scf
	ret
.found3:
	ex af, af'
	and a			; make sure carry is reset
	ret

;-----------------------------------------------------------------------
; F_loader
; Loads some data into RAM.
.globl F_loader
F_loader:
	; Page in some RAM for the data to land.
	call SETPAGEA

	call CLEAR42
	
	ld c, SOCK_STREAM	; open a TCP socket
	call SOCKET		; file descriptor in A
	jp c, .borked4		; or c set if failed
	ld (v_sockfd), a	; save the fd

	ld de, 2000		; port 2000
	call BIND		; bind to the port
	jp c, .borked4

	ld a, (v_sockfd)	; socket we want to listen on
	call LISTEN		; listen
	jr c, .borked4

	; Display an informative message to the user showing the
	; IP and port we are listening on.
	ld hl, STR_send
	call PRINT42
	ld de, buf_workspace	; where to deposit our IP address
	call GET_IFCONFIG_INET
	ld hl, buf_workspace
	ld de, buf_workspace+4
	call LONG2IPSTRING
	ld hl, buf_workspace+4
	call PRINT42
	ld hl, STR_port
	call PRINT42

	; Wait for a connection.		
	ld a, (v_sockfd)
	call ACCEPT		; block until something connects
	jr c, .borked4
	ld (v_connfd), a	; save the connection file descriptor

	; Get the first 4 bytes which contains the start address and
	; data length. We are actually going to ignore the start
	; address but to be compatible with the "ethup" utility we
	; still get it.
	ld de, buf_workspace	; where to store
	ld bc, 4		; how many bytes
	call RECV		; block till we get them
	call F_printxfinfo	; print information about the data

	; Receive the data.
	ld de, 0x1000		; current address to write to
	ld (buf_workspace), de	; save current pointer
.recvloop4:
	ld a, (v_connfd)
	ld bc, 1024		; receive up to 1K at a time
	call RECV
	jr c, .borked4
	ld hl, (buf_workspace+2) ; get remaining length
	sbc hl, bc
	ld a, h			; are we done yet?
	or l
	jr z, .recvdone4
	ld (buf_workspace+2), hl ; save remaining length
	ld hl, (buf_workspace)	; get current pointer
	add hl, bc		; increment it
	ld (buf_workspace), hl	; save it
	ex de, hl
	ld a, '.'		; progress marker
	call PUTCHAR42
	jr .recvloop4		; get the next block
.recvdone4:
	ld a, (v_connfd)	; close the connection
	call CLOSE
	ld a, (v_sockfd)
	call CLOSE
	ret
.borked4:
	ld hl, buf_workspace
	call ITOH8
	ld hl, STR_borked
	call PRINT42
	ld hl, buf_workspace
	call PRINT42
	scf
	ret

; internal function for the above - print info of what's being tx'd to us.
.globl F_printxfinfo
F_printxfinfo:
	ld hl, STR_est
	call PRINT42
	ld hl, STR_len
	call PRINT42
	ld a, (buf_workspace+3)
	ld hl, buf_workspace+4
	call ITOH8
	ld a, (buf_workspace+2)
	call ITOH8
	ld hl, buf_workspace+4
	call PRINT42
	ld a, NEWLINE
	call PUTCHAR42
	ret
	
;-------------------------------------------------------------------------
; F_romconfigmenu
; Displays the ROM configuration menu.
.globl F_configmenu
F_configmenu:
	ld hl, STR_menutitle
	call PRINT42
	ld hl, MENU_romconfig
	call F_genmenu
	ld hl, MENU_romconfig
	call F_getmenuopt
	ret

;-------------------------------------------------------------------------
; F_addmodule
; Adds a new module to the last slot in ROM, assuming there's one available
.globl F_addmodule
F_addmodule:
	call F_findfirstfreepage	; Find the ROM page for the module
	jp c, J_noroom			; Report "no room" if C is set
	call SETPAGEB			; page it into area B
	ld a, 0xC3			; page to fill in RAM
	call F_loader			; fetch data over the network
	jp c, F_waitforkey		; bale out now, error receiving
	ld hl, STR_writingmod		; tell the user
	call PRINT42
	ld hl, v_workspace		; hex conversion
	ld a, (v_pgb)			; of current page B
	call ITOH8			; convert to hex string
	ld hl, v_workspace
	call PRINT42			; print it
	ld hl, 0x1000			; program a 4K block
	ld de, 0x2000
	ld bc, 0x1000
	di
	call F_FlashWriteBlock
	ei
	jp c, J_writeborked
	jp F_waitforkey

;-------------------------------------------------------------------------
; F_repmodule
; Replaces a module.
.globl F_repmodule
F_repmodule:
	ld hl, STR_entermod
	call PRINT42
	call F_getromnum		; ask for the ROM id
	ret z				; user baled on us
	ld (v_workspace), a		; the ROM that will be replaced.
	and 0xFC			; mask out bottom two bits to find
	ld (v_workspace + 1), a		; the sector, store it for later
	call F_copysectortoram		; copy the flash sector
	ld a, (v_workspace)		; calculate the RAM page to use
	and 0x03			; get position in the sector
	add a, 0xDC			; add RAM page number
	call F_loader			; get the new data over the net
	ld a, (v_workspace + 1)		; retrieve sector page
	di
	call F_FlashEraseSector
	jr c, J_eraseborked		; oops!
	ld a, (v_workspace + 1)
	call F_writesector		; write the new contents of RAM
	ei
	jr c, J_writeborked
	jp F_waitforkey

;------------------------------------------------------------------------
; Report flash write/erase failures
J_eraseborked:
	ld hl, STR_erasebork
	call PRINT42
	scf
	ret

;-----------------------------------------------------------------------
; F_removepage
; Removes a page from a sector of flash, shuffling all the ROMs down.
; Page to remove should be in (v_workspace), and A should have the sector
; first page.
.globl F_removepage
F_removepage:
	ld b, 3				; 3 pages to copy to RAM
	ex af, af'
	ld a, 0xDC			; RAM page to start with
.loop9:
	push bc
	call F_setpageB			; page in RAM destination
	inc a
	ex af, af'
	ld hl, v_workspace
	cp (hl)				; is this the page to delete?
	jr nz, .noskip9			
	inc a				; if so skip it
.noskip9:
	call F_setpageA			; page in ROM source
	inc a
	ex af, af'
	ld hl, 0x1000			; ROM source addr
	ld de, 0x2000			; RAM dest addr
	ld bc, 0x1000
	ldir
	pop bc
	djnz .loop9

	call F_setpageB			; page in the final RAM page
	ld hl, 0x2000
	ld de, 0x2001
	ld bc, 0xFFF
	ld (hl), 0xFF			; and fill it with 0xFF (empty flash)
	ldir

	ex af, af'			; get the flash page pointer back
	dec a				; and turn it back into the
	and 0xFC			; first page in the sector
	push af				; save it
	di
	call F_FlashEraseSector		; erase it
	jr c, .fail9
	pop af
	call F_writesector		; write the modified sector back
	ei
	jr c, J_writeborked
	ret
.fail9:
	ei
	pop af				; restore stack
	jr J_eraseborked

;-----------------------------------------------------------------------
; Jump here to display a write failed message.
J_writeborked:
	ld hl, STR_writebork
	call PRINT42
	scf
	ret

;-----------------------------------------------------------------------
; F_remmodule: Removes a module.
.globl F_remmodule
F_remmodule:
	ld hl, STR_delrom
	call PRINT42
	call F_getromnum		; ask for the ROM id
	ret z				; user baled on us
	ex af, af'
	dec a
	ld (v_workspace+2), a		; save the first free page - 1
	ex af, af'
	ld (v_workspace), a		; make a copy of the user selection
	and 0xFC			; find the sector
	ld (v_workspace+1), a		; store the sector's first page num
	ld hl, STR_erasing
	call PRINT42
	ld a, (v_workspace+1)
	call F_removepage		; remove the selected ROM
	ret c				; leave if it failed
	ld hl, STR_eraseok
	call PRINT42

	; If there are further occupied sectors after the one from which
	; the ROM page was just removed, we need to take a page from the
	; last sector and use it to fill in the hole we just made.
	ld a, (v_workspace+2)
	and 0xFC			; what sector?
	ld b, a
	ld a, (v_workspace+1)
	cp b				; no more sectors after this one
	ret z

	ld hl, STR_defragment		; report progress
	call PRINT42
	ld a, (v_workspace+2)		; page in the relevant page
	call F_setpageA			; to page area A
	ld a, 0xDC
	call F_setpageB			; RAM in B
	ld hl, 0x1000			; copy
	ld de, 0x2000
	ld bc, 0x1000
	ldir
	ld a, (v_workspace+1)		; get the sector with the hole
	or 0x03				; and the page of the hole to fill
	call F_setpageB
	ld hl, 0x1000			; flash it into the hole
	ld de, 0x2000
	ld bc, 0x1000
	di
	call F_FlashWriteBlock
	ei
	jr c, J_writeborked
	ld a, (v_workspace + 2)		; get the page of the data we copied
	call F_removepage		; and remove it
	xor a				; reset Z
	ret

;----------------------------------------------------------------------
; F_exit: Exit the ROM utility.
.globl F_exit
F_exit:
	or 1				; reset Z flag
	ret

;-------------------------------------------------------------------------
; J_noroom
J_noroom:
	ld hl, STR_noroom
	call PRINT42
;-------------------------------------------------------------------------
; 'Press x to exit'
.globl F_waitforkey
F_waitforkey:
	ld hl, STR_xtoexit
	call PRINT42
.waitforkey12:
	call GETKEY
	cp 'x'
	jr nz, .waitforkey12
	xor a			; set Z flag
	ret

;-------------------------------------------------------------------------
; F_getromnum
; Ask the user for a ROM slot (hex value), return it in A
; Note. First free page is also returned in A'
.globl F_getromnum
F_getromnum:
	ld c, 3			; buffer is 3 bytes long (2 + null)
	ld de, v_workspace
	call INPUTSTRING
	ld hl, v_workspace
	ld a, (hl)
	and a			; nothing entered?
	ret z
	call HTOI8		; convert hex string pointed to by hl
	cp 4			; must be greater than 4
	jr c, .invalid13
	push af			; save the ROM number selected
	call F_findfirstfreepage
	pop bc			; get AF back into BC for comparison
	cp b			; b should be <= a
	jr c, .invalid13
	ex af, af'		; keep first free page in A'
	ld a, b			; move result into A
	or a			; make sure Z is not set
	ret
.invalid13:	
	ld hl, STR_notvalid
	call PRINT42
	jr F_getromnum
	
;-------------------------------------------------------------------------
; F_copysectortoram
; Copies 4 pages of flash to RAM.
; Parameter: A = first page.
.globl F_copysectortoram
F_copysectortoram:
	ex af, af'			; save ROM page
	ld a, 0xDC			; first RAM page
	ld b, 4				; pages to copy
.copyloop14:
	push bc
	call F_setpageB			; RAM into area B
	inc a
	ex af, af'			; ROM page into A
	call F_setpageA			; page it in
	inc a
	ex af, af'			; for the next iteration.
	ld hl, 0x1000			; copy the page
	ld de, 0x2000
	ld bc, 0x1000
	ldir
	pop bc
	djnz .copyloop14
	ret

.globl F_debugpages
F_debugpages:
	push af
	ex af, af'
	push af

	ex af, af'
	ld hl, v_workspace+2
	call ITOH8
	ld hl, STR_accum
	call PRINT42
	ld hl, v_workspace+2
	call PRINT42

	pop af
	push af
	ld hl, v_workspace+2
	call ITOH8
	ld hl, STR_accum1
	call PRINT42
	ld hl, v_workspace+2
	call PRINT42

	ld a, (v_workspace)
	ld hl, v_workspace+2
	call ITOH8
	ld hl, STR_workspace
	call PRINT42
	ld hl, v_workspace+2
	call PRINT42
	
	ld a, (v_workspace+1)
	ld hl, v_workspace+2
	call ITOH8
	ld hl, STR_workspace1
	call PRINT42
	ld hl, v_workspace+2
	call PRINT42

	call F_waitforkey
	pop af
	ex af, af'
	pop af
	ret
.data	
STR_workspace:	defb NEWLINE,"workspace + 0: ",0
STR_workspace1:	defb NEWLINE,"workspace + 1: ",0
STR_accum:	defb NEWLINE,"A register   : ",0
STR_accum1:	defb NEWLINE,"A' register  : ",0

;-------------------------------------------------------------------------
; Definitions.
MENU_romconfig:
	defw STR_addmodule,F_addmodule
	defw STR_repmodule,F_repmodule
	defw STR_remmodule,F_remmodule
	defw STR_exit,F_exit
	defw 0

