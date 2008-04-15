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
; into area B (0x2000-0x2FFF)

;-------------------------------------------------------------------------
; F_showcurrent
; Show the current configuration. This is a rather tedious routine that
; does a lot of calls to the print a string routine and various conversion
; routines.
F_showcurrent
	ld hl, 0x001F		; chip 0 page 1F
	call F_setpageA		; page into area A
	ld hl, STR_currset	; print 'Current settings'
	call F_print

	; print the IP address label, the address, and a carriage return.
	ld hl, STR_currip
	call F_print
	ld hl, 0x1000 + IP_ADDRESS	
	ld de, buf_workspace
	call F_long2ipstring
	ld hl, buf_workspace
	call F_print	
	ld a, '\n'
	call F_putc_5by8

	; print the current netmask
	ld hl, STR_currmask
	call F_print
	ld hl, 0x1000 + IP_SUBNET
	ld de, buf_workspace
	call F_long2ipstring
	ld hl, buf_workspace
	call F_print
	ld a, '\n'
	call F_putc_5by8

	; print the current gateway
	ld hl, STR_currgw
	call F_print
	ld hl, 0x1000 + IP_GATEWAY
	ld de, buf_workspace
	call F_long2ipstring
	ld hl, buf_workspace
	call F_print
	ld a, '\n'
	call F_putc_5by8

	; print the current hardware (MAC) address
	ld hl, STR_currhwaddr
	call F_print
	ld hl, 0x1000 + HW_ADDRESS
	ld de, buf_workspace
	;call F_hwaddr2string
	ld hl, buf_workspace
	call F_print
	ld a, '\n'
	call F_putc_5by8

	; print the current hostname
	ld hl, STR_currhost
	call F_print
	ld hl, 0x1000 + HOSTNAME
	call F_print
	ld a, '\n'
	call F_putc_5by8

	ret

MENU_config
		defw	STR_ipaddr
		defw	STR_netmask
		defw	STR_gateway
		defw	STR_hwaddr
		defw	STR_hostname
		defw	STR_save
		defw	STR_cancel
		defw	0
STR_ipaddr	defb "Change IP address",0
STR_netmask	defb "Change netmask", 0
STR_gateway	defb "Change default gateway", 0
STR_hostname	defb "Change hostname", 0
STR_hwaddr	defb "Change ethernet address\n", 0
STR_save	defb "Save changes and exit",0
STR_cancel	defb "Cancel changes and exit",0

STR_currset	defb "Current configuration\n",0
STR_currip	defb "IP address       : ",0
STR_currmask	defb "Netmask          : ",0
STR_currgw	defb "Default gateway  : ",0
STR_currhwaddr	defb "Hardware address : ",0
STR_currhost	defb "Hostname         : ",0

