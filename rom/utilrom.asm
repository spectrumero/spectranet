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
	include "spectranet.asm"

; temporary!
	define SOCK_DGRAM 2

	org 0x2000
	defb 0xAA
	defb 0x55
	defw F_inetinit			; RESET vector
	defw 0xFFFF			; RST8 vector
	defw 0xFFFF			; INT vector
	defw F_nmihandler		; NMI vector
	defw 0xFFFF
	defw 0xFFFF
	defw 0xFFFF

	include "inetinit.asm"		; Initializes inet settings
	include "dhcpclient.asm"	; DHCP client
	include "utilnmi.asm"		; NMI handler
	include "dhcpdefs.asm"
	include "sockdefs.asm"
	include "sysvars.sym"
	include "flashconf.asm"		; defines for configuration memory
CONFIGUTIL_START
	incbin "configutilrom.out"	; Configuration utility image
CONFIGUTIL_END
;	include "ui_config.asm"		; configuration user interface
;	include "ui_menu.asm"		; simple menu generator

;fwstart
;	incbin "flashwrite.out"		; this gets LDIR'd to RAM
;fwend

