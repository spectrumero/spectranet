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
.include	"fcntl.inc"

.section vectors
sig:	defb 0xAA		; This is a ROM module
romid:	defb 0xFA		; for a filesystem only.
reset:	defw F_init		; reset vector
mount:	defw F_tnfs_mount	; The mount routine
	defw 0xFFFF
	defw 0xFFFF
	defw F_startmsg
	defw 0xFFFF
idstr:	defw STR_ident		; ROM identity string
	jp J_tnfs_modcall	; MODCALL entry point

; The VFS table. This is a jump table for all the VFS entry points.
; Only some are implemented, the rest point to a routine that returns
; an error.
	jp F_tnfs_umount	; Unmount routine
	jp F_tnfs_opendir	; Open a directory
	jp F_tnfs_open		; Open a file
	jp F_tnfs_unlink	; Unlink - delete a file
	jp F_tnfs_mkdir		; Mkdir - Create a directory
	jp F_tnfs_rmdir		; Rmdir - Delete a directory
	jp F_tnfs_size		; Filesystem size
	jp F_tnfs_free		; Filesystem free space
	jp F_tnfs_stat		; Filesystem 'stat' info
	jp F_tnfs_chmod		; Change mode (permissions)
	jp F_tnfs_read		; Read a file
	jp F_tnfs_write		; Write to a file
	jp F_tnfs_lseek		; Seek to a position in a file
	jp F_tnfs_close		; Close a file
	jp F_undef		; Poll - not implemented
	jp F_tnfs_readdir	; Read a directory entry
	jp F_tnfs_closedir	; Close a directory
	jp F_tnfs_chdir		; Change directory
	jp F_tnfs_getcwd	; get current directory
	jp F_tnfs_rename	; rename
.data
STR_ident:
	defb "TNFS 1.00",0
.text
.globl F_tnfs_size
F_tnfs_size:			; TODO functions
.globl F_tnfs_free
F_tnfs_free:
.globl F_undef
F_undef:
	ld a, ENOSYS		; Function not implemented
	scf
	ret
