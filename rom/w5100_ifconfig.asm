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
;
; Interface configuration functions - to abstract the W5100 away from
; software that needs to configure the interface.
;

;-------------------------------------------------------------------------
; F_ifconfig_ routines: F_ifconfig_inet, F_ifconfig_gw, F_ifconfig_netmask
; Configures the basic settings needed for the W5100.
; Parameters: HL - pointer to the 4 byte block of memory with the IPv4
; info.
; DE is incremented by 4.
F_ifconfig_gw
	call F_regpage
	ld de, GAR0	; gateway address register
	jr J_copy_cfg

F_ifconfig_inet
	call F_regpage
	ld de, SIPR0
	jr J_copy_cfg

F_ifconfig_netmask
	call F_regpage
	ld de, SUBR0
	jr J_copy_cfg

J_copy_cfg
	ld bc, 4
	ldir
	jp J_leavesockfn

;-------------------------------------------------------------------------
; F_get_ifconfig routines: F_get_ifconfig_inet, gw, netmask:
; Returns the inet settings into a 4-byte buffer pointed to by DE
; in big-endian format.
F_get_ifconfig_gw
	call F_regpage
	ld hl, GAR0
	jr J_copy_cfg

F_get_ifconfig_inet
	call F_regpage
	ld hl, SIPR0
	jr J_copy_cfg

F_get_ifconfig_netmask
	call F_regpage
	ld hl, SUBR0
	jr J_copy_cfg
	
F_regpage
	ld a, (v_pga)		; copy original page A value
	ld (v_buf_pga), a
	ld a, REGPAGE
	call F_setpageA
	ret

;-------------------------------------------------------------------------
; F_sethwaddr
; Configures the W5100 hardware (MAC) address.
; Parameters: HL - pointer to a 6 byte buffer containing the hardware addr.
; Returns with carry set if the readback fails to give the same result.
F_sethwaddr
	call F_regpage
	push hl		; preserve buffer pointer
	ld de, SHAR0	; hardware address register
	ld bc, 6	; is 6 bytes long
	ldir

	pop hl
	ld de, SHAR0	; readback
	ld bc, 6	; check 6 bytes
.readback
	ld a, (de)
	cpi
	jr nz, .readbackerr
	inc de
	jp pe, .readback ; keep going till BC=0
	or 0		; ensure carry is cleared
	jp J_leavesockfn
.readbackerr
	scf
	jp J_leavesockfn

;---------------------------------------------------------------------------
; F_gethwaddr
; Read the hardware address and fill a 6 byte buffer.
; Parameters: DE = pointer to buffer to fill.
F_gethwaddr
	call F_regpage
	ld hl, SHAR0
	ld bc, 6
	ldir
	jp J_leavesockfn

;---------------------------------------------------------------------------
; F_deconfig
; Deconfigure the interface (reset the inet, gateway and netmask fields).
; Parameters: None.
F_deconfig
	call F_regpage
	ld hl, GAR0
	ld de, GAR1
	ld bc, 7
	ld (hl), 0
	ldir
	ld hl, GAR0
	ld de, SIPR0
	ld bc, 4
	ldir
	jp J_leavesockfn

