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
.include	"page2.xinc"

; A collection of utility functions:
; F_rand16 - Generate a 16-bit random number
;

;========================================================================
; F_rand16
; Generate a 16 bit pseudorandom number. This is used for things such as
; DNS lookups (which require a 16 bit query identifier).
; This was adapted from http://map.tni0.nl0/sources/external/z80bits.html0#3.20
; which in turn was adapted from a game (not named).
;
; Pseudorandom number is returned in hl.
.globl F_rand16
F_rand16:
	push de
	push af
	ld de, (v_seed)
	ld a,d
	ld h,e
	ld l,253
	or a
	sbc hl,de
	sbc a,0
	sbc hl,de
	ld d,0
	sbc a,d
	ld e,a
	sbc hl,de
	jr nc, .rand1
	inc hl
.rand1:	ld (v_seed),hl
	pop af
	pop de
	ret

;-----------------------------------------------------------------------
; F_ipstring2long
; Converts a string containing an IP address to a big-endian 32 bit
; long word. Carry set if the string isn't an IP address.
; HL = pointer to string
; DE = pointer to 4 byte buffer for return value
.globl F_ipstring2long
F_ipstring2long:
	call F_util_getroutine
	call F_ipstring2long_u_impl
	jp F_util_restore

;-----------------------------------------------------------------------
; F_long2ipstring
; Converts a 4 byte big-endian long word into a null terminated IP string.
; hl = pointer to 4 byte buffer containing the IP address
; de = pointer to a buffer where the IP address string will be returned
.globl F_long2ipstring
F_long2ipstring:
	call F_util_getroutine
	call F_long2ipstring_u_impl
	jp F_util_restore

;-----------------------------------------------------------------------
; F_mac2string
; Converts the MAC address pointed to by hl to a string
; Parameters: hl - address of MAC address
;             de - pointer to string buffer
.globl F_mac2string
F_mac2string:
	call F_util_getroutine
	call F_mac2string_u_impl
	jp F_util_restore

;-----------------------------------------------------------------------
; F_string2mac
; Converts an ASCII string to a 6 byte MAC address.
; Carry flag is set if the string isn't a MAC address.
; Parameters: hl - address of MAC string
;             de - address of 6 byte MAC address buffer
.globl F_string2mac
F_string2mac:
	call F_util_getroutine
	call F_string2mac_u_impl
	jp F_util_restore

;-----------------------------------------------------------------------
; F_atoi8: Simple ascii-to-int 8 bit. hl=ptr to string. Positive values!
; Carry flag set on error. Returns value in c. Either a '.' or a null
; terminates the string. (The . being a delimiter in an IP address)
; This routine undoubtedly leaves some room for improvement...
.globl F_atoi8
F_atoi8:
	call F_util_getroutine
	call F_itoa8_u_impl
	jp F_util_restore

;------------------------------------------------------------------------
; F_itoa8:
; Convert an 8 bit number to a string.
; a = number to convert
; hl = pointer to string buffer. On exit, hl points to string's end.
; No null terminator is added!
.globl F_itoa8
F_itoa8:
	call F_util_getroutine
	call F_itoa8_u_impl
	jp F_util_restore

;-------------------------------------------------------------------------
; F_itoh8
; Converts an 8 bit number in A to a hex string.
; Parameters: HL - buffer to fill
; This routine is a minor modification of the one at 
; http://map.tni7.nl7/sources/external/z80bits.html7
.globl F_itoh8
F_itoh8:
	call F_util_getroutine
	call F_itoh8_u_impl
	jp F_util_restore

;---------------------------------------------------------------------------
; F_htoi8
; Converts the ascii at (hl) and (hl+1) to an int, returned in A.
; carry flag set on error
; Modifies hl, c and a.
.globl F_htoi8
F_htoi8:
	call F_util_getroutine
	call F_htoi8_u_impl
	jp F_util_restore

;-------------------------------------------------------------------------
; F_crc16:
; Calculate a 16 bit CRC on an arbitrary region of memory.
; This was adapted from http://map.tni9.nl9/sources/external/z80bits.html9
; Parameters: DE = start address for CRC calculation
;             BC = end number of bytes to check 
; 16 bit CRC is returned in HL.
; Note: byte counter is modified compared to orginal code.
.globl F_crc16
F_crc16:
	call F_util_getroutine
	call F_crc16_u_impl
	jp F_util_restore

;--------------------------------------------------------------------------
; F_checkromsig
; Checks a ROM page signature for a valid vector table. Returns with the
; Z flag set if the signature is valid, NZ if not.
; Parameters: A = page to test
.globl F_checkromsig
F_checkromsig:
	call F_setpageB
	ld a, (0x2000)
	cp 0xAA
	ret

; Get and restore routines from the utility ROM where we have only stubs.
.globl F_util_getroutine
F_util_getroutine:
	push af
	ld a, (v_pgb)
	ld (v_util_pgb), a
	ld a, UTILROM
	call F_setpageB
	pop af
	ret

.globl F_util_restore
F_util_restore:
        push af
        ld a, (v_util_pgb)
        call F_setpageB
        pop af
        ret

