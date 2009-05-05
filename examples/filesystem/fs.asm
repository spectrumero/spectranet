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

; Filesystem example.
; This demonstrates a simple filesystem that can be mounted, a file opened,
; and written to, and closed.

	org 0x2000
	include "spectranet.asm"
	include "../../rom/sysvars.sym"
	
	; First, define the tables.
sig	defb 0xAA		; This is a valid ROM module
romid	defb 0xFE		; with ID 0xFE (generic filesystem ID)
reset	defw 0xFFFF		; No reset vector
mount	defw F_do_mount		; The mount routine
	defw 0xFFFF
	defw 0xFFFF
	defw 0xFFFF
	defw 0xFFFF
idstr	defw STR_ident		; ROM identity string
modcall	ret			; No modcall code
	defw 0			; pad out to start of...

; The VFS table. This is a jump table for all the VFS entry points.
; Only some are implemented, the rest point to a routine that returns
; an error.
	jp F_umount		; Unmount routine
	jp F_opendir		; Open a directory
	jp F_open		; Open a file
	jp F_undef		; Unlink - not implemented
	jp F_undef		; Mkdir - not implemented
	jp F_undef		; Rmdir - not implemented
	jp F_size		; Filesystem size
	jp F_free		; Filesystem free space
	jp F_stat		; Filesystem 'stat' info
	jp F_undef		; Change mode - not implemented
	jp F_read		; Read a file
	jp F_write		; Write to a file
	jp F_undef		; Seek - not implemented
	jp F_close		; Close a file
	jp F_undef		; Poll - not implemented
	jp F_readdir		; readdir
	jp F_closedir		; Close a directory
	jp F_undef		; chdir
	jp F_undef		; reserved1
	jp F_undef		; reserved2

STR_ident
	defb "Example filesystem",0

; The 'undef' routine just returns an error. (Put all other routines
; here till they are done!)
F_opendir
F_size
F_free
F_stat
F_read
F_write
F_close
F_readdir
F_closedir
F_undef
	scf
	ld a, 0xFF		; TODO: The proper return code
	ret

; Now include the code that does all the work.
	include "mount.asm"
	include "file.asm"
