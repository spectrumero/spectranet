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

; Snapshot Manager.
	org 0x2000		; ROM module start point.
	include "vectors.asm"	; Vector/signature table.
	include "memory.asm"	; Memory allocation and initialization
	include "utils.asm"	; utility functions
	include	"screen.asm"	; Screen functions
	include "directory.asm"	; Read and stat files in the directory
	include	"inputloop.asm"	; Input loop and handling functions
	include "strings_en.asm" ; String table
	include "loadsna.asm"	; Loads snapshots
	include "savesna.asm"	; Saves snapshots

	include "../../rom/spectranet.asm"	; Spectranet defines
	include "../../rom/sysvars.sym"		; System vars
	include "../../rom/fs_defs.asm"		; Filesystem defs
	include "snapmandefs.asm"		; Defines

