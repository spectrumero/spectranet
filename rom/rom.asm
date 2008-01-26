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

; The Spectranet ROM.
;--------------------
; Out of the included files, the order of two of them are critical.
; zeropage.asm must be the first file. This sets the org, and must start
; at 0x0000. sysvars.asm must be the last, since this changes the org to
; 0x3F00. (This doesn't get burned into ROM, rather it just defines areas
; in the upper fixed page, which is always RAM (chip 3 page 0).
;
; Until w5100_defines is changed to be equ instead of defines, this should
; be included before any of the network library code.

	; Routines for ROM page 0 (chip 0 page 0, lower fixed page)
	include "zeropage.asm"		; Restarts
	include "pager.asm"		; Memory paging routines
	include "w5100_defines.asm"	; Definitions for network hardware
	include "sockdefs.asm"		; Definitions for socket library
	include "w5100_buffer.asm"	; Transmit and receive buffers
	include "w5100_sockalloc.asm"	; socket, accept, close

	; Memory map for upper fixed page (chip 3 page 0)
	include "sysvars.asm"		; System variables
	include "sysdefs.asm"		; General definitions
