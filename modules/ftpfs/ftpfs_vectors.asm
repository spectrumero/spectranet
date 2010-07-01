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

; Vector table for the FTP filesystem.

sig	defb 0xAA		; This is a module
romid	defb 0xFF		; for a filesystem only.
reset	defw F_init		; Called on reset
mount	defw F_ftpfs_mount	; Filesystem mount function
	defw 0xFFFF
	defw 0xFFFF
	defw 0xFFFF
	defw 0xFFFF
idstr	defw STR_ident		; ROM identity string
	defb 0,0,0		; No MODCALL jump.

; The VFS jump table.
        jp F_ftpfs_umount        ; Unmount routine
        jp F_ftpfs_opendir       ; Open a directory
        jp F_ftpfs_open          ; Open a file
        jp F_ftpfs_unlink        ; Unlink - delete a file
        jp F_ftpfs_mkdir         ; Mkdir - Create a directory
        jp F_ftpfs_rmdir         ; Rmdir - Delete a directory
        jp F_ftpfs_size          ; Filesystem size
        jp F_ftpfs_free          ; Filesystem free space
        jp F_ftpfs_stat          ; Filesystem 'stat' info
        jp F_ftpfs_chmod         ; Change mode (permissions)
        jp F_ftpfs_read          ; Read a file
        jp F_ftpfs_write         ; Write to a file
        jp F_ftpfs_lseek         ; Seek to a position in a file
        jp F_ftpfs_close         ; Close a file
        jp F_undef              ; Poll - not implemented
        jp F_ftpfs_readdir       ; Read a directory entry
        jp F_ftpfs_closedir      ; Close a directory
        jp F_ftpfs_chdir         ; Change directory
        jp F_ftpfs_getcwd        ; get current directory
        jp F_ftpfs_rename        ; rename

STR_ident
	defb "FTPFS 1.0",0
F_undef
	ld a, ENOSYS
	scf
	ret


