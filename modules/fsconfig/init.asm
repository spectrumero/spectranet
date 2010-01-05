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

; Initialize the module - install our BASIC command
F_init
        ld hl, PARSETABLE
        ld b, numcmds
.loop
	push bc
        call ADDBASICEXT
	pop bc
        jr c, .installerror
	djnz .loop

        ld hl, STR_basicinit
        call PRINT42
        ret
.installerror
        ld hl, STR_basinsterr
        call PRINT42
        ret

PARSETABLE
numcmds		equ 2
P_fsconfig      defb 0x0b       ; Trap C Nonsense in BASIC
                defw CMD_FSCONFIG
                defb 0xFF       ; this page
                defw F_start
P_ifconfig      defb 0x0b       ; Trap C Nonsense in BASIC
                defw CMD_IFCONFIG
                defb 0xFF       ; this page
                defw F_ifconfig
CMD_FSCONFIG    defb "%fsconfig",0
CMD_IFCONFIG	defb "%ifconfig",0


