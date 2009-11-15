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

; File that builds the TNFS ROM library.

	org 0x2000			; this is a standard ROM module.

	include "tnfs_vectors.asm"	; Vector table
	include "tnfs_init.asm"
	include "tnfs_core.asm"		; low level library
	include "tnfs_mount.asm"	; Mount and unmount filesystems
	include "tnfs_file.asm"		; File operations
	include "tnfs_directory.asm"	; Directory operations

	include "../modules/basext/regdump.asm"

	; These are not really anything to do with TNFS, but there's not
	; enough space in any other "core" ROM page to put them elsewhere!
;	include "machinetype.asm"
	include "save7ffd.asm"		; Finds and saves port 0x7FFD

	; definitions
	include "spectranet.asm"	; Base ROM definitions
	include "sysvars.asm"		; Base system variables
	include "fs_statdefs.asm"	; Definitions for stat()
	include "fs_defs.asm"		; General filesystem definitions
	include "tnfs_defs.asm"		; TNFS definitions
	include "tnfs_sysvars.asm"	; System variables and workspaces
