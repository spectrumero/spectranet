;The MIT License
;
;Copyright (c) 2009 Dylan Smith
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

; Filesystem Configuration Utility module

; This is a ROM module.
	org 0x2000		; module in page B
sig     defb 0xAA               ; This is a ROM module
romid   defb 0xFE               ; for a filesystem only.
reset   defw F_init             ; reset vector
mount   defw 0xFFFF		; not a filesystem
        defw 0xFFFF
        defw 0xFFFF
        defw 0xFFFF
        defw 0xFFFF
idstr   defw STR_ident          ; ROM identity string
modcall ret                     ; No modcall code
        defw 0                  ; pad out to start of...

	include "strings_en.asm"	; English strings
	include "config_ui.asm"		; User interface
	include "../../rom/spectranet.asm"	; spectranet lib defs
	include "../../rom/sysvars.sym"		; system vars defs
	include "../../rom/flashconf.asm"	; flash config defs

; Initialize the module - install our BASIC command
F_init
	ld hl, PARSETABLE
	ld b, 1			; just 1 command
	call ADDBASICEXT
	jr c, .installerror
	ld hl, STR_basicinit
	call PRINT42
	ret
.installerror
	ld hl, STR_basinsterr
	call PRINT42
	ret

PARSETABLE
P_fsconfig	defb 0x0b	; Trap C Nonsense in BASIC
		defw CMD_FSCONFIG
		defb 0xFF	; this page
		defw F_start
CMD_FSCONFIG	defb "%fsconfig",0

FLASHPROGSTART
	; Flash writer. This *MUST* be at the end because we change ORG
	org 0x3000
F_updateflash
	di
	ld a, (v_pga)
	push af
	ld a, (v_pgb)
	push af
	ld a, 0x1C		; last sector of flash
	call F_FlashEraseSector
	jr c, .cleanup
	ld a, 0x1C		; start page to write
	call F_writesector
.cleanup
	ex af, af'		; preserve flags
	pop af
	call SETPAGEB
	pop af
	call SETPAGEA
	ex af, af'
	ei
	ret
	
	include "../../rom/flashwrite.asm"
FLASHPROGLEN	equ $-0x3000

