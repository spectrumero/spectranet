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

; The upper entry point.
; CALL instructions to 0x3FF8 and higher cause a ROM page-in. A small
; amount of code can live here to dispatch these calls elsewhere.
UPPER_ENTRYPT
	defb 0		; unused at present
	ret		; A way of paging in without using an OUT
	jp J_hldispatch	; HLCALL - 0x3FFA
	jp J_ixdispatch	; IXCALL - 0x3FFD
UPPER_ENTRYPT_SIZE	equ 0x08

; The jump table
; --------------
;
; The convention to call a ROM library function is to do the following:
;
; ld hl, ADDRESS
; call 0x3FFF
;
; The call 0x3FFF is trapped and causes the Spectranet memory to get
; mapped into the lower 16k of the address space (and the Spectrum ROM is
; obviously unmapped at this point).
;
; While the address in HL can be any address (usefully, in the lower 16k)
; normally, ADDRESS should be in the jump table. While this costs a few
; extra cycles, calling indirectly via the jump table means that binary
; compatibility is retained across ROM revisions. It also allows the user
; to redirect calls to ROM library functions at runtime and add their
; own extras. (See the BBC Microcomputer where indirect jump tables were
; used and allowed this sort of thing to take place).
;
; Functions that take HL as a parameter can use the entry point at 0x3FFE
; instead, and set IX to the jump table address - not surprisingly, the
; instruction at 0x3FFE is jp (ix). Operations with the ix register are
; a little slower, so while this entry point works fine - if hl isn't
; needed as a parameter it's best to use 0x3FFF.
;
; This jump table is copied to 0x3E00 on reset (the fixed upper 4k page,
; which is RAM).
JUMPTABLE_COPYFROM
	jp F_socket
	jp F_sockclose
	jp F_listen
	jp F_accept
	jp F_bind
	jp F_connect
	jp F_send
	jp F_recv
	jp F_sendto
	jp F_recvfrom
	jp F_poll
	jp F_pollall
	jp F_pollfd
	jp F_gethostbyname
	jp F_putc_5by8
	jp F_print
	jp F_clear
	jp F_setpageA
	jp F_setpageB
	jp F_long2ipstring
	jp F_ipstring2long
	jp F_itoa8
	jp F_rand16
	jp F_remoteaddress
	jp F_regdump
JUMPTABLE_END

JUMPTABLE_SIZE		equ JUMPTABLE_END - JUMPTABLE_COPYFROM

	include "spectranet.asm"	; A list of public symbols

