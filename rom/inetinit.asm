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

; Called on reset/power up, these routines examine the configuration
; stored in the last page of flash, and initializes the IP settings
; accordingly.

;---------------------------------------------------------------------------
; F_inetinit
; Initializes IPv4 settings.
; Called by the reset routine in the main rom on reset/power up.
; Configuration must be copied to RAM since we are using both paging areas
; (one for the W5100 register area, and one for this code).
F_inetinit
	ld hl, 0x1F		; flash page containing configuration
	call SETPAGEA
	ld hl, 0x1F00		; last 256 bytes of config
	ld de, 0x3000		; RAM workspace
	ld bc, 256
	ldir			; copy to RAM
	ld hl, 0x2100+INITFLAGS	; Check to see if we should
	bit INIT_STATICIP, (hl)	; be using static settings or DHCP	
	jp z, F_dhcp		; no, not static configuration - use DHCP.

	call F_showstatic	; Display details
	ld hl, 0x2100+IP_ADDRESS
	call IFCONFIG_INET
	ld hl, 0x2100+IP_SUBNET
	call IFCONFIG_NETMASK
	ld hl, 0x2100+IP_GATEWAY
	call IFCONFIG_GW
	ld hl, 0x2100+PRI_DNS
	ld de, v_nameserver1
	ld bc, 8		; two nameservers, 8 bytes
	ldir
	ret

;------------------------------------------------------------------------
; F_showstatic
; Show configuration if statically configured.
F_showstatic
	ld hl, STR_staticip
	call PRINT42
	ld hl, 0x2100+IP_ADDRESS
	call F_showaddr
	ld hl, STR_staticmask
	call PRINT42
	ld hl, 0x2100+IP_SUBNET
	call F_showaddr
	ld hl, STR_staticgw
	call PRINT42
	ld hl, 0x2100+IP_GATEWAY
	call F_showaddr
	ret

F_showaddr
	ld de, buf_workspace
	call LONG2IPSTRING
	ld hl, buf_workspace
	call PRINT42
	ld a, '\n'
	call PUTCHAR42
	ret

STR_staticip	defb "IP address   : ",0
STR_staticmask	defb "Netmask      : ",0
STR_staticgw	defb "Gateway      : ",0

