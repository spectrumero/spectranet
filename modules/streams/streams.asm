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

; BASIC streams
	include "../../rom/zxromdefs.asm"	; ZX ROM definitions
	include "../../rom/spectranet.asm"	; Spectranet symbols
	include "../../rom/sysvars.sym"		; System variable decs
	include "../../rom/zxsysvars.asm"	; ZX system variables
	include "../../rom/fs_defs.asm"		; filesystem defs
	include "streamvars.asm"		; our local sysvars
	include "streamdefs.asm"		; defines

	org 0x2000		; this is a module
	include "vectors.asm"	; Vector table
	include "init.asm"	; Initialization routines
	include "commands.asm"	; BASIC commands
	include "string_en.asm"	; English strings
	include "memory.asm"	; Memory claim
	include "chanmgr.asm"	; Channel manager
	include "io.asm"	; IO routines
	include "buffer.asm"	; buffers
	include "fileio.asm"	; file open functions
	include "ctrlchan.asm"	; Control channel
;	include "flowcontrol.asm" ; BASIC flow control

; Our ROM ID
STREAM_ROM_ID	equ 0x02

