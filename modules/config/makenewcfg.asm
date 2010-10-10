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

; Make a new empty configuration.
;
; *** NOTE *** This should only be run once per Spectranet to do the initial
; set-up of the configuration area.
;
	include "../../rom/spectranet.asm"
	include "config_interface.asm"
	org 0x8000

	call PAGEIN
	ld hl, str_creating
	call PRINT42
	
	; first need to copy any existing config from the last page
	; of flash into RAM.
	ld hl, CFG_COPYCONFIG	; load existing data from flash that may exist
	rst MODULECALL_NOPAGE

	ld hl, CFG_CREATENEWCFG	; create a new config area in RAM
	rst MODULECALL_NOPAGE

	ld hl, CFG_COMMITCFG	; commit
	rst MODULECALL_NOPAGE
	jr c, .commiterr

	ld hl, str_done
	call PRINT42
	jp J_exit
.commiterr
	ld hl, str_commiterr
	call PRINT42
J_exit
	jp PAGEOUT

str_creating
	defb "Creating new configuration\n",0
str_commiterr
	defb "Unable to commit to flash\n",0
str_done
	defb "Done.\n",0

