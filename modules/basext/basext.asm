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

; Creates the BASIC extensions module.
	include "../../rom/spectranet.asm"
	include "../../rom/sysvars.sym"
	include "../../rom/zxsysvars.asm"
	include "../../rom/fs_defs.asm"
	include "defs.asm"
INTERPWKSPC	equ 0x3000
TNFS_PAGE	equ 0xFF

	org 0x2000
	include "vectors.asm"		; vector table
	include "init.asm"		; initialization routines	
	include "commands.asm"		; Command routines
	include "loader.asm"		; Load/save routines
	include "tapetrap.asm"		; tape traps
	include "info.asm"		; %info command
	include "strings_en.asm"	; Strings
	include "parseurl.asm"		; Mount point URL parser
	include "loadsna.asm"		; Load .SNA files
	include "snaphandler.asm"	; Detect type of snapshot
	include "savesna.asm"		; Saves snapshots
	include "regdump.asm"	

