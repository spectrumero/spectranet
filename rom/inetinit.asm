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
.include	"spectranet.inc"
.include	"flashconf.inc"
.include	"ctrlchars.inc"
.include	"sysvars.inc"
;---------------------------------------------------------------------------
; F_inetinit
; Initializes IPv4 settings.
; Called by the reset routine in the main rom on reset/power up.
; Configuration must be copied to RAM since we are using both paging areas
; (one for the W5100 register area, and one for this code).
.text
.globl F_inetinit
F_inetinit:
	call F_iface_wait
	ld a, 0x1F		; flash page containing configuration
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
	ld hl, v_ethflags	; set IP acquired flag
	set 0, (hl)
	ret

;------------------------------------------------------------------------
; F_iface_wait
; Wait for the interface to come up. Work around the W5100 hardware bug
; by resetting the chip if we don't get a stable link.
; Check that the CPLD is a version that can detect link state.
F_iface_wait:
	ei			; HALT will be used for timing
	halt			; ensure read occurs when ULA is not reading
				; screen memory (prototype CPLD does not
				; have this port and returns 0xFF)
	ld bc, CPLDINFO		; CPLD information port
	in a, (c)
	cp 0xFF			; 0xFF = prototype CPLD which does not have
	jr z, .prototype
	ld hl, STR_wait
	call PRINT42
	ei			; HALT used for timing
	call .reset		; ensure chip is reset

	ld b, 5			; how many times to try
.linkloop:
	push bc
	ld d, 200		; wait for 200 frames (4 seconds) maximum
.waitloop:
	ld bc, CTRLREG
	in a, (c)
	bit 6, a		; if the light's on this goes to zero
	jr z, .testlinked
	halt			; wait 20ms
	dec d
	jr nz, .waitloop 	; check register again
.reenter:
	call .reset		; try again
	pop bc
	djnz .linkloop

	di
	ld hl, STR_fail
	call PRINT42
	scf			; interface didn't come up
	ret
.linked:
	di
	pop bc			; restore stack
	ld hl, STR_linkup
	call PRINT42
	or a			; ensure carry is cleared
	ret
	; check the link is stable - the link light must remain on for
	; 50% of the time for 1 second.
.testlinked:
	ld a, '>'
	call PUTCHAR42
	ld h, 50		; frames to wait
	ld e, 0			; count of LED lit
.linktestloop:
	in a, (c)		; get status register
	bit 6, a		; test LINK value
	jr nz, .continue	; not lit - do not increment counter
	inc e
.continue:
	halt
	dec h			; decrement loop count
	jr nz, .linktestloop
	ld a, 25		; link light must be on >= this amount
	cp e
	jr c, .linked		; exit the routine
	jr .reenter		; re-enter wait-for-link loop

.reset:
	ld a, '.'
	call PUTCHAR42		; print a dot
	ld bc, CTRLREG
	in a, (c)		; get current control register
	res 7, a		; reset RESET bit
	out (c), a		; ensure RESET bit is low
	halt			; wait at least 20ms
	halt
	set 7, a		; release RESET bit
	out (c), a
	ret

	; The prototype CPLD flips the toggle flip flop for programmable
	; traps every time the trap port is touched; it is not mixed with
	; the !WR signal. So we have to read it one more time to set it
	; back to its proper start position.
.prototype:
	in a, (c)		; note: BC will already be set
	di
	ret

;------------------------------------------------------------------------
; F_showstatic
; Show configuration if statically configured.
.globl F_showstatic
F_showstatic:
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

.globl F_showaddr
F_showaddr:
	ld de, buf_workspace
	call LONG2IPSTRING
	ld hl, buf_workspace
	call PRINT42
	ld a, NEWLINE
	call PUTCHAR42
	ret
.data
STR_staticip:	defb "I:",0
STR_staticmask:	defb "M:",0
STR_staticgw:	defb "G:",0
STR_wait:	defb "Link",0
STR_linkup:	defb "OK",NEWLINE,0
STR_fail:	defb "Not detected",NEWLINE,0

