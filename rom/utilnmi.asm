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
.include	"spectranet.inc"
.include	"sysvars.inc"
.include	"ctrlchars.inc"
.include	"sockdefs.inc"

; Utility ROM - NMI handler
.text
.globl F_nmihandler
F_nmihandler:
	call F_savescreen	; save frame buffer contents
	ld bc, 0xFFFD		; silence the AY (even for 48K machines
	ld a, 8			; in case they have an AY add on compatible
	out (c), a		; with the 128K)
	ld b, 0xBF		; set register 8
	xor a			; to 0
	out (c), a
	ld b, 0xFF
	ld a, 9			; register 9 to zero
	out (c), a
	ld b, 0xBF
	xor a
	out (c), a
	ld a, 10		; register 10 to zero
	ld b, 0xFF
	out (c), a
	ld b, 0xBF
	xor a
	out (c), a
	call F_detectpages	; Detect 128K mode and value of port 0x7ffd
	ld a, (v_machinetype)
	cp 1			; 128K machine?
	jr nz, .menuloop1	; If not, continue
	ld a, (v_port7ffd)	; If so, make sure the normal screen
	res 3, a		; is in use.
	ld bc, 0x7ffd
	out (c), a
.menuloop1:
	ld a, 7
	out (254), a		; border = white
	call CLEAR42
	ld hl, STR_nmimenu	; title
	call PRINT42
	ld hl, MENU_nmi		; generate the menu
	call F_genmenu
	ld hl, MENU_nmi
	call F_getmenuopt	; act on user keypress
	jr nz, .menuloop1	; routines set Z if they want to exit

	call F_restorescreen
	ld a, (v_port7ffd)	; Restore port 0x7FFD
	ld bc, 0x7ffd
	out (c), a
	ld a, (v_border)	; Restore the border colour
	out (254), a
	ret


;-------------------------------------------------------------------------
; F_savescreen
; Save the current Spectrum frame buffer into our static memory.
.globl F_savescreen
F_savescreen:
	ld bc, CTRLREG		; save border colour
	in a, (c)
	and 7
	ld (v_border), a

	ld a, 0xDA		; Use pages 0xDA, 0xDB of RAM
	call SETPAGEA
	ld hl, 0x4000		; Spectrum screen buffer
	ld de, 0x1000		; Page area A
	ld bc, 0x1000		; 4K
	ldir
	ld a, 0xDB
	call SETPAGEA
	ld hl, 0x5000
	ld de, 0x1000
	ld bc, 0xB00		; Remainder of screen, including attrs.
	ldir
	ret

;---------------------------------------------------------------------------
; F_restorescreen
; Restore the Spectrum framebuffer.
.globl F_restorescreen
F_restorescreen:
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
	ret

;---------------------------------------------------------------------
; F_config
; Invokes the configuration program
.globl F_config
F_config:
	ld hl, 0xFE00		; module FE (configuration) call 0x00
	rst MODULECALL_NOPAGE
	ret

;-----------------------------------------------------------------------
; F_rom
; Invokes the ROM module utility. This is stored in page 0x01 of flash
; as a binary object.
.globl F_rom
F_rom:
	ld a, 0x01
	call SETPAGEA		; this utility's executable code is in the
	ld hl, ROMMODCONF_START	; data ROM, so page it in and copy it from
	ld de, 0x3000		; 0x1000 to 0x3000.
	ld bc, ROMMODCONF_LEN
	ldir
	call 0x3000		; call it
	or 1			; reset Z
	ret

.data
ROMMODCONF_START:
.incbin	"modman.bin"
ROMMODCONF_LEN	equ $-ROMMODCONF_START

.text
;-----------------------------------------------------------------------
; F_loader
; Loads some data into RAM.
.globl F_loader
F_loader:
	call CLEAR42
	
	ld c, SOCK_STREAM	; open a TCP socket
	call SOCKET		; file descriptor in A
	jp c, .borked6		; or c set if failed
	ld (v_sockfd), a	; save the fd

	ld de, 2000		; port 2000
	call BIND		; bind to the port
	jp c, .borked6

	ld a, (v_sockfd)	; socket we want to listen on
	call LISTEN		; listen
	jr c, .borked6

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
	jr c, .borked6
	ld (v_connfd), a	; save the connection file descriptor

	; Get the first 4 bytes which contains the start address and
	; data length.
	ld de, buf_workspace	; where to store
	ld bc, 4		; how many bytes
	call RECV		; block till we get them
	call F_printxfinfo	; print information about the data

	; Receive the data.
	ld de, (buf_workspace)	; current address to write to
.recvloop6:
	ld a, (v_connfd)
	ld bc, 1024		; receive up to 1K at a time
	call RECV
	jr c, .borked6
	ld hl, (buf_workspace+2) ; get remaining length
	sbc hl, bc
	ld a, h			; are we done yet?
	or l
	jr z, .recvdone6
	ld (buf_workspace+2), hl ; save remaining length
	ld hl, (buf_workspace)	; get current pointer
	add hl, bc		; increment it
	ld (buf_workspace), hl	; save it
	ex de, hl
	ld a, '.'		; progress marker
	call PUTCHAR42
	jr .recvloop6		; get the next block
.recvdone6:
	ld a, (v_connfd)	; close the connection
	call CLOSE
	ld a, (v_sockfd)
	call CLOSE
.keymsg6:
	ld hl, STR_xtoexit
	call PRINT42
.waitforkey6:			; wait for a key so the user has a chance
	call GETKEY		; to see what happened.
	cp 'x'			; press 'x' to exit
	jr nz, .waitforkey6
	or 1			; ensure zero flag is cleared
	ret
.borked6:
	ld hl, buf_workspace
	call ITOH8
	ld hl, STR_borked
	call PRINT42
	ld hl, buf_workspace
	call PRINT42
	jr .keymsg6

; internal function for the above - print info of what's being tx'd to us.
.globl F_printxfinfo
F_printxfinfo:
	ld hl, STR_est
	call PRINT42
	ld hl, STR_start
	call PRINT42
	ld a, (buf_workspace+1)
	ld hl, buf_workspace+4
	call ITOH8
	ld a, (buf_workspace)
	call ITOH8
	ld hl, buf_workspace+4
	call PRINT42
	ld a, NEWLINE
	call PUTCHAR42
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

.globl F_snapshot
F_snapshot:
	ld hl, 0xFB00		; ROM ID 0xFB call 0x00
	rst MODULECALL_NOPAGE
	ret

;---------------------------------------------------------------------
; F_exit
; A very short routine for the menu to be able to set the zero flag.	
.globl F_exit
F_exit:
	xor a			; set zero flag
	ret

MENU_nmi:
	defw	STR_config,F_config
	defw	STR_rom,F_rom
	defw	STR_loader,F_loader
	defw	STR_snapshot,F_snapshot
	defw	STR_exit,F_exit
	defw	0,0

