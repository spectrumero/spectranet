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
.include	"if_defs.inc"
.include	"spectranet.inc"
.include	"flashconf.inc"
.include	"ctrlchars.inc"
.include	"sysvars.inc"
.text
;-------------------------------------------------------------------------
; Configuration user interface.
; This essentially forms a program that gets run from ROM page 1, paged
; into area B (0x2000-0x2FFF) as part of the 'utility' ROM.

;-------------------------------------------------------------------------
; F_showcurrent
; Show the current configuration. This is a rather tedious routine that
; does a lot of calls to the print a string routine and various conversion
; routines.
.globl F_showcurrent
F_showcurrent: 
	call CLEAR42

	ld hl, STR_currset	; print 'Current settings'
	call PRINT42

	; print DHCP status
	ld hl, STR_usedhcp
	call PRINT42
	ld hl, 0x1000 + INITFLAGS
	bit INIT_STATICIP, (hl)
	jr z,  .yes1
	ld hl, STR_no
	call PRINT42
	jr  .continue1
.yes1: 
	ld hl, STR_yes
	call PRINT42
.continue1: 

	; Print IPv4 settings.
	ld hl, TABLE_config
.showconfig1: 
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld a, d			; End of table encountered?
	or e
	jr z,  .printhwaddr1	; yes; null terminator.
	push hl			; save current pointer
	ex de, hl
	call PRINT42		; print the string that was pointed to.
	pop hl
	ld a, (0x1000 + INITFLAGS) ; should we print an address?
	bit INIT_STATICIP, a	; non zero = static IP configuration
	jr z,  .bydhcp1
	ld e, (hl)		; get low order of configuration address
	inc hl
	ld d, (hl)		; high order of configuration address
	inc hl
	push hl			; save current pointer
	ex de, hl		; address to translate in hl
	ld de, buf_workspace
	call LONG2IPSTRING	; convert it to a string
	ld hl, buf_workspace	; and print it.
.printresult1: 
	call PRINT42
	ld a, NEWLINE
	call PUTCHAR42
	pop hl
	jr  .showconfig1		; continue with next entry
.bydhcp1: 
	inc hl			; point hl at next entry
	inc hl
	push hl			; save it
	ld hl, STR_bydhcp
	jr  .printresult1

.printhwaddr1: 
	; print the current hardware (MAC) address
	ld hl, STR_currhwaddr
	call PRINT42
	ld hl, 0x1000 + HW_ADDRESS
	ld de, buf_workspace
	call MAC2STRING
	ld hl, buf_workspace
	call PRINT42
	ld a, NEWLINE
	call PUTCHAR42

	; print the current hostname
	ld hl, STR_currhost
	call PRINT42
	ld hl, 0x1000 + HOSTNAME
	ld a, (hl)		; has it ever been set?
	cp 0xFF
	jr nz,  .printhost1
	ld hl, STR_vunset
.printhost1: 
	ld hl, 0x1000 + HOSTNAME 
	call PRINT42
	ld a, NEWLINE
	call PUTCHAR42
	ret

;-----------------------------------------------------------------------
; F_setdhcp:
; Ask the user whethe to use DHCP or not.
; Called by F_getmenuopt.
.globl F_setdhcp
F_setdhcp: 
	ld hl, STR_dhcpquestion
	call PRINT42
.keyloop2: 
	call GETKEY
	cp 'y'
	jr nz,  .noty2
	ld hl, 0x1000 + INITFLAGS
	res INIT_STATICIP, (hl)		; set 'use static IP' to 0
	xor a				; return 0 (non terminal menu option)
	ret
.noty2: 
	cp 'n'
	jr nz,  .keyloop2			; try again
	ld hl, 0x1000 + INITFLAGS
	set INIT_STATICIP, (hl)		; set 'use static ip' bit
	xor a				; return 0 (non terminal menu option)
	ret

;-----------------------------------------------------------------------
; F_setipaddr
; Asks the user for an IP address.
.globl F_setipaddr
F_setipaddr: 
	ld hl, STR_abort
	call PRINT42
.askloop3: 
	ld hl, STR_askip
	call PRINT42
	call F_getipstr
	jr c,  .askloop3		; try again
	ld de, 0x1000 + IP_ADDRESS
copyquad:
	ld hl, buf_hex		; copy the address into config area
	ld a, (hl)
	and a			; nothing there?
	ret z
	ldi
	ldi
	ldi
	ldi
	xor a			; set zero flag
	ret

.globl F_setnetmask
F_setnetmask: 
	ld hl, STR_abort
	call PRINT42
.askloop4: 
	ld hl, STR_asknetmask
	call PRINT42
	call F_getipstr
	jr c,  .askloop4
	ld de, 0x1000 + IP_SUBNET
	jr copyquad

.globl F_setgateway
F_setgateway: 
	ld hl, STR_abort
	call PRINT42
.askloop5: 
	ld hl, STR_askgw
	call PRINT42
	call F_getipstr
	jr c,  .askloop5
	ld de, 0x1000 + IP_GATEWAY
	jr copyquad

.globl F_setpridns
F_setpridns: 
	ld hl, STR_abort
	call PRINT42
.askloop6: 
	ld hl, STR_askpridns
	call PRINT42
	call F_getipstr
	jr c,  .askloop6
	ld de, 0x1000 + PRI_DNS
	jr copyquad

.globl F_setsecdns
F_setsecdns: 
	ld hl, STR_abort
	call PRINT42
.askloop7: 
	ld hl, STR_asksecdns
	call PRINT42
	call F_getipstr
	jr c,  .askloop7
	ld de, 0x1000 + SEC_DNS
	jr copyquad

;-------------------------------------------------------------------------
; F_getipstr
; Get an IP-like string (i.e. inet addr, netmask, gateway)
.globl F_getipstr
F_getipstr: 
	ld c, 16		; maximum length of an IP address string
	ld de, buf_addr
	call INPUTSTRING
	ld hl, buf_addr
	ld a, (hl)
	and a			; first byte = null?
	ret z
	ld de, buf_hex
	call IPSTRING2LONG
	ret nc			; Valid string, return.
	ld hl, STR_invalidip
	call PRINT42
	scf
	ret

;-----------------------------------------------------------------------
; F_sethwaddr
; Get a hardware address from the user.
.globl F_sethwaddr
F_sethwaddr: 
	ld hl, STR_abort
	call PRINT42
.askloop9: 
	ld hl, STR_askhw
	call PRINT42
	ld c, 18		; hw address is 18 bytes long
	ld de, buf_addr
	call INPUTSTRING
	ld hl, buf_addr
	ld a, (hl)
	and a
	ret z			; nothing entered, so do nothing
	ld de, buf_hex
	call STRING2MAC
	jr c,  .badmac9		; carry set? Couldn't interpret address
	ld hl, buf_hex
	ld de, 0x1000 + HW_ADDRESS
	ld bc, 6
	ldir
	xor a			; ensure Z is set
	ret
.badmac9: 
	ld hl, STR_invalidip
	call PRINT42
	jr  .askloop9

;-----------------------------------------------------------------------
; F_sethostname
; Sets the computer's hostname
.globl F_sethostname
F_sethostname: 
	ld hl, STR_abort
	call PRINT42
	ld hl, STR_askhostname
	call PRINT42
	ld c, 15
	ld de, buf_addr
	call INPUTSTRING
	ld hl, buf_addr
	ld a, (hl)
	and a
	ret z				; nothing entered, do nothing
	ld de, 0x1000 + HOSTNAME
	ld bc, 16
	ldir
	xor a
	ret	

;-----------------------------------------------------------------------
; F_cancelconfig:
; Bale out of the menu.
.globl F_cancelconfig
F_cancelconfig: 
	or 1			; reset zero flag
	ret
.data
.globl MENU_config
MENU_config:
		defw	STR_dhcp, F_setdhcp
		defw	STR_ipaddr, F_setipaddr
		defw	STR_netmask, F_setnetmask
		defw	STR_gateway, F_setgateway
		defw	STR_pridns, F_setpridns
		defw	STR_secdns, F_setsecdns
		defw	STR_hwaddr, F_sethwaddr
		defw	STR_hostname, F_sethostname
		defw	STR_save, F_saveconfig
		defw	STR_cancel, F_cancelconfig
		defw	0,0
.globl TABLE_config
TABLE_config:	
		defw	STR_currip, 0x1000+IP_ADDRESS
		defw	STR_currmask, 0x1000+IP_SUBNET
		defw	STR_currgw, 0x1000+IP_GATEWAY
		defw	STR_currpridns, 0x1000+PRI_DNS
		defw	STR_currsecdns, 0x1000+SEC_DNS
		defw	0

