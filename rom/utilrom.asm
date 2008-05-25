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

; The Utility ROM

; These routines live in page 1 of flash, and run when page 1 is paged
; into paging area B (0x2000-0x2FFF)

	org 0x2000

; temporary
	define SHAR0	0x1009	; Our ethernet address, first of 6
	define SHAR1	0x100A
	define SHAR2	0x100B
	define SHAR3	0x100C
	define SHAR4	0x100D
	define SHAR5	0x100E
	define GAR0	0x1001	; Gateway addr first octet
	define GAR1	0x1002
	define GAR2	0x1003
	define GAR3	0x1004
	define SIPR0	0x100F	; First octet of our IP address
	define SIPR1	0x1010
	define SIPR2	0x1011
	define SIPR3	0x1012
	define SUBR0	0x1005	; Subnet mask, first octet
	define SUBR1	0x1006
	define SUBR2	0x1007
	define SUBR3	0x1008
	define SOCK_DGRAM 2

	org 0x2000
	defb 0xAA
	defb 0x55
	defw F_dhcp			; RESET vector
	defw 0xFFFF
	defw 0xFFFF
	defw 0xFFFF
	defw 0xFFFF
	defw 0xFFFF
	defw 0xFFFF

	include "rom.sym"		; main ROM symbols
;	include "configwrite.sym"	; symbols for flashwrite.out

	include "dhcpclient.asm"	; DHCP client
	include "dhcpdefs.asm"
;	include "ui_config.asm"		; configuration user interface
;	include "ui_menu.asm"		; simple menu generator

;fwstart
;	incbin "flashwrite.out"		; this gets LDIR'd to RAM
;fwend

