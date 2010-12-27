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
.include	"spectranet.inc"
.text

; Initialize the module - install our BASIC command
.globl F_init
F_init: 
        ld hl, PARSETABLE
        ld b, numcmds
.loop1: 
	push bc
        call ADDBASICEXT
	pop bc
        jr c,  .installerror1
	djnz  .loop1

	; init local 8 byte sysvar area.
	call F_getsysvar
	inc hl
	ld (hl), 0		; shadow copy has not been made.

        ld hl, STR_basicinit
        call PRINT42
        ret
.installerror1: 
        ld hl, STR_basinsterr
        call PRINT42
        ret

.data
PARSETABLE:
numcmds:	equ 9
P_fsconfig:     defb 0x0b       ; Trap C Nonsense in BASIC
                defw CMD_FSCONFIG
                defb 0xFF       ; this page
                defw F_start
P_ifconfig:     defb 0x0b       ; Trap C Nonsense in BASIC
                defw CMD_IFCONFIG
                defb 0xFF       ; this page
                defw F_ifconfig
P_cfgset:	defb 0x0b
		defw CMD_CFGSET
		defb 0xFF
		defw F_cfgset
P_cfgsetstr:	defb 0x0b
		defw CMD_CFGSET_STR
		defb 0xFF
		defw F_cfgset_string
P_cfgcommit:	defb 0x0b
		defw CMD_CFGCOMMIT
		defb 0xFF
		defw F_cfgcommit
P_cfgabandon:	defb 0x0b
		defw CMD_CFGABANDON
		defb 0xFF
		defw F_cfgabandon
P_cfgnew:	defb 0x0b
		defw CMD_CFGNEW
		defb 0xFF
		defw F_cfgnew
P_cfgnewsec:	defb 0x0b
		defw CMD_CFGNEWSEC
		defb 0xFF
		defw F_cfgnewsec
P_cfgrm:	defb 0x0b
		defw CMD_CFGRM
		defb 0x00
		defw F_cfgrm

CMD_FSCONFIG:   defb "%fsconfig",0
CMD_IFCONFIG:	defb "%ifconfig",0
CMD_CFGSET:	defb "%cfgset",0
CMD_CFGSET_STR:	defb "%cfgset$",0
CMD_CFGCOMMIT:	defb "%cfgcommit",0
CMD_CFGABANDON:	defb "%cfgabandon",0
CMD_CFGNEW:	defb "%cfgnew",0
CMD_CFGNEWSEC:	defb "%cfgnewsec",0
CMD_CFGRM:	defb "%cfgrm",0

