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

; Paging routines for 128k machines
;===================================
; The 128k machine's main ROM in the lower 16k of the memory map is selected
; by port 0x7FFD. On +3 machines, there are 4 possible ROM pages, and
; therefore another port defined for controlling which chip is selected
; (0x1FFD).
; 
; When we reset, we want the 48k BASIC ROM paged because there's a few
; routines that the Spectranet uses. The routine F_zxinit sets up the
; initial state (both pager latches reset, and the sysvars set appropriately)
; This allows us to use two routines F_pagezxbasic and F_pagezxrestore
; regardless of the machine's state.
;
; They are no-ops on 48k machines, or after 48k mode has been selected
; (and therefore harmless for non-128k machines).

;------------------------------------------------------------------------
; F_zxinit: Make sure the BANK settings are at the initial state.
F_zxinit
	xor a
	ld (ZX_BANKM), a
	ld (ZX_BANK678), a
	ld bc, ZX_IO_BANKM
	out (c), a
	ld bc, ZX_IO_BANK678
	out (c), a
	ret

;------------------------------------------------------------------------
; F_pagezxbasic: 
; Page in the ZX BASIC ROM.
F_pagezxbasic
	ld a, (ZX_BANKM)
	ld (v_bankm), a		; save old state
	or 0x10			; set bit 4
	ld (ZX_BANKM), a	; update Spectrum sysvar
	ld bc, ZX_IO_BANKM
	out (c), a		; switch pages
	ld a, (ZX_BANK678)	
	ld (v_bank678),a	; save old state
	or 0x04			; set bit 2
	ld (ZX_BANK678), a	; update +3 sysvar
	ld bc, ZX_IO_BANK678	
	out (c), a		; switch pages
	ret

;------------------------------------------------------------------------
; F_pagezxrestore:
; Restore the ROM banks to their original values
F_pagezxrestore
	ld a, (v_bankm)		; get old value
	ld (ZX_BANKM), a	; restore sysvar
	ld bc, ZX_IO_BANKM	
	out (c), a		; restore pager hardware
	ld a, (v_bank678)	; get old +3 value
	ld (ZX_BANK678), a	; restore it
	ld bc, ZX_IO_BANK678
	out (c), a		; restore +3 pager hardware
	ret

