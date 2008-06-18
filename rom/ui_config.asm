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

;-------------------------------------------------------------------------
; Configuration user interface.
; This essentially forms a program that gets run from ROM page 1, paged
; into area B (0x2000-0x2FFF) as part of the 'utility' ROM.

;-------------------------------------------------------------------------
; F_showcurrent
; Show the current configuration. This is a rather tedious routine that
; does a lot of calls to the print a string routine and various conversion
; routines.
F_showcurrent
	call CLEAR42

	ld hl, STR_currset	; print 'Current settings'
	call PRINT42

	; print DHCP status
	ld hl, STR_usedhcp
	call PRINT42
	ld hl, 0x1000 + INITFLAGS
	bit INIT_STATICIP, (hl)
	jr z, .yes
	ld hl, STR_no
	call PRINT42
	jr .continue
.yes
	ld hl, STR_yes
	call PRINT42
.continue

	; Print IPv4 settings.
	ld hl, TABLE_config
.showconfig
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld a, d			; End of table encountered?
	or e
	jr z, .printhwaddr	; yes; null terminator.
	push hl			; save current pointer
	ex de, hl
	call PRINT42		; print the string that was pointed to.
	pop hl
	ld a, (0x1000 + INITFLAGS) ; should we print an address?
	bit INIT_STATICIP, a	; non zero = static IP configuration
	jr z, .bydhcp
	ld e, (hl)		; get low order of configuration address
	inc hl
	ld d, (hl)		; high order of configuration address
	inc hl
	push hl			; save current pointer
	ex de, hl		; address to translate in hl
	ld de, buf_workspace
	call LONG2IPSTRING	; convert it to a string
	ld hl, buf_workspace	; and print it.
.printresult
	call PRINT42
	ld a, '\n'
	call PUTCHAR42
	pop hl
	jr .showconfig		; continue with next entry
.bydhcp
	inc hl			; point hl at next entry
	inc hl
	push hl			; save it
	ld hl, STR_bydhcp
	jr .printresult

.printhwaddr
	; print the current hardware (MAC) address
	ld hl, STR_currhwaddr
	call PRINT42
	ld hl, 0x1000 + HW_ADDRESS
	ld de, buf_workspace
	call MAC2STRING
	ld hl, buf_workspace
	call PRINT42
	ld a, '\n'
	call PUTCHAR42

	; print the current hostname
	ld hl, STR_currhost
	call PRINT42
	ld hl, 0x1000 + HOSTNAME
	ld a, (hl)		; has it ever been set?
	cp 0xFF
	jr nz, .printhost
	ld hl, STR_unset
.printhost
	ld hl, 0x1000 + HOSTNAME 
	ld de, buf_workspace
.xferloop
	ldi			; transfer the hostname to the workspace
	ld a, (hl)		; because the print routine needs pageA
	and a			; for its character set.
	jr nz, .xferloop
.printhost2
	ex de, hl
	ld (hl), 0
	ld hl, buf_workspace
	call PRINT42
	ld a, '\n'
	call PUTCHAR42
	ret

;-----------------------------------------------------------------------
; F_setdhcp:
; Ask the user whethe to use DHCP or not.
; Called by F_getmenuopt.
F_setdhcp
	ld hl, STR_dhcpquestion
	call PRINT42
.keyloop
	call GETKEY
	cp 'y'
	jr nz, .noty
	ld hl, 0x1000 + INITFLAGS
	res INIT_STATICIP, (hl)		; set 'use static IP' to 0
	xor a				; return 0 (non terminal menu option)
	ret
.noty
	cp 'n'
	jr nz, .keyloop			; try again
	ld hl, 0x1000 + INITFLAGS
	set INIT_STATICIP, (hl)		; set 'use static ip' bit
	xor a				; return 0 (non terminal menu option)
	ret

;-----------------------------------------------------------------------
; F_setipaddr
; Asks the user for an IP address.
F_setipaddr
	ld hl, STR_abort
	call PRINT42
.askloop
	ld hl, STR_askip
	call PRINT42
	call F_getipstr
	jr c, .askloop		; try again
	ld de, 0x1000 + IP_ADDRESS
copyquad
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

F_setnetmask
	ld hl, STR_abort
	call PRINT42
.askloop
	ld hl, STR_asknetmask
	call PRINT42
	call F_getipstr
	jr c, .askloop
	ld de, 0x1000 + IP_SUBNET
	jr copyquad

F_setgateway
	ld hl, STR_abort
	call PRINT42
.askloop
	ld hl, STR_askgw
	call PRINT42
	call F_getipstr
	jr c, .askloop
	ld de, 0x1000 + IP_GATEWAY
	jr copyquad

F_setpridns
	ld hl, STR_abort
	call PRINT42
.askloop
	ld hl, STR_askpridns
	call PRINT42
	call F_getipstr
	jr c, .askloop
	ld de, 0x1000 + PRI_DNS
	jr copyquad

F_setsecdns
	ld hl, STR_abort
	call PRINT42
.askloop
	ld hl, STR_asksecdns
	call PRINT42
	call F_getipstr
	jr c, .askloop
	ld de, 0x1000 + SEC_DNS
	jr copyquad

;-------------------------------------------------------------------------
; F_getipstr
; Get an IP-like string (i.e. inet addr, netmask, gateway)
F_getipstr
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
F_sethwaddr
	ld hl, STR_abort
	call PRINT42
.askloop
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
	jr c, .badmac		; carry set? Couldn't interpret address
	ld hl, buf_hex
	ld de, 0x1000 + HW_ADDRESS
	ld bc, 6
	ldir
	xor a			; ensure Z is set
	ret
.badmac
	ld hl, STR_invalidip
	call PRINT42
	jr .askloop

;-----------------------------------------------------------------------
; F_sethostname
; Sets the computer's hostname
F_sethostname
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
; F_saveconfig
; Saves the configuration the user just entered.
F_saveconfig
	ld hl, STR_saving
	call PRINT42
	ld a, 0x1C		; page that belongs to last 16k of flash
	call F_FlashEraseSector
	jr c, .eraseborked
	call F_writeconfig
	jr c, .writeborked
	ld hl, STR_done
	call PRINT42
	or 1			; clear zero flag
	ret
.eraseborked
	ld hl, STR_erasebork
	jr .bork
.writeborked
	ld hl, STR_writebork
.bork
	call PRINT42
	call GETKEY		; give the user a chance to see the msg
	or 1
	ret

;-----------------------------------------------------------------------
; F_cancelconfig:
; Bale out of the menu.
F_cancelconfig
	or 1			; reset zero flag
	ret

MENU_config
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
TABLE_config	
		defw	STR_currip, 0x1000+IP_ADDRESS
		defw	STR_currmask, 0x1000+IP_SUBNET
		defw	STR_currgw, 0x1000+IP_GATEWAY
		defw	STR_currpridns, 0x1000+PRI_DNS
		defw	STR_currsecdns, 0x1000+SEC_DNS
		defw	0

STR_choose	defb "\n\nChoose a configuration option:\n",0
STR_dhcp	defb "Enable/disable DHCP",0
STR_ipaddr	defb "Change IP address",0
STR_netmask	defb "Change netmask", 0
STR_gateway	defb "Change default gateway", 0
STR_hostname	defb "Change hostname", 0
STR_pridns	defb "Change primary DNS",0
STR_secdns	defb "Change secondary DNS",0
STR_hwaddr	defb "Change hardware address", 0
STR_save	defb "Save changes and exit",0
STR_cancel	defb "Cancel changes and exit",0

STR_currset	defb "Current configuration\n=====================\n",0
STR_usedhcp	defb "Use DHCP         : ",0
STR_currip	defb "IP address       : ",0
STR_currmask	defb "Netmask          : ",0
STR_currgw	defb "Default gateway  : ",0
STR_currhwaddr	defb "Hardware address : ",0
STR_currhost	defb "Hostname         : ",0
STR_currpridns	defb "Primary DNS      : ",0
STR_currsecdns	defb "Secondary DNS    : ",0
STR_no		defb "No\n",0
STR_yes		defb "Yes\n",0
STR_bydhcp	defb "Set by DHCP",0
STR_unset	defb "[unset]",0

STR_abort	defb "Enter on a blank line aborts\n",0
STR_invalidip	defb "\nSorry, that wasn't a valid address.\n",0
STR_dhcpquestion defb "\nUse DHCP? (Y/N): ",0
STR_askip	defb "\nIP address: ",0
STR_asknetmask	defb "\nNetmask: ",0
STR_askgw	defb "\nGateway: ",0
STR_askhw	defb "\nHardware address: ",0
STR_askhostname	defb "\nHostname: ",0
STR_askpridns	defb "\nPrimary DNS: ",0
STR_asksecdns	defb "\nSecondary DNS: ",0

STR_saving	defb "\nSaving configuration...",0
STR_done	defb "Done\n",0
STR_erasebork	defb "Erase failed\n",0
STR_writebork	defb "Write failed\n",0

