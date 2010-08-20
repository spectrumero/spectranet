;The MIT License
;
;Copyright (c) 2010 Dylan Smith
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

; Basstart.asm runs module functions that should be run once BASIC has
; shown the copyright message. The basstart function gets called from
; a trap.

; Displays the startup message when BASIC has initialized.
; This includes the IP address.

F_startmsg
	ld hl, STR_rel
	call PRINT42
	ld hl, bldstr
	call PRINT42
	ld hl, STR_date
	call PRINT42
	ld hl, blddate
	call PRINT42
	ld hl, STR_ip
	call PRINT42
	ld de, 0x3000		; workspace destination for IP address
	call GET_IFCONFIG_INET
	ld de, 0x3004		; put the resulting string here
	ld hl, 0x3000		; where the 4 byte IP address lives
	call LONG2IPSTRING	; convert to a string
	ld hl, 0x3004		; string pointer
	call PRINT42
	ld a, '\n'
	call PUTCHAR42
	ret
STR_rel		defb "Alioth Spectranet\nBuild: ",0
STR_ip		defb "   IP: ",0
STR_date	defb " Date: ",0
	include	"date.asm"
	include "ver.asm"
	
