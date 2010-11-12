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

; This just defines vector table addresses and jump tables for ROM modules.
MOD_SIGNATURE		equ 0x2000
MOD_ROMID		equ 0x2001
MOD_VEC_RESET		equ 0x2002
MOD_VEC_MOUNT		equ 0x2004
MOD_VEC_RESERVED0	equ 0x2006
MOD_VEC_RESERVED1	equ 0x2008
MOD_VEC_RESERVED2	equ 0x200A
MOD_VEC_RESERVED3	equ 0x200C
MOD_VEC_IDENT		equ 0x200E

MOD_JP_MODCALL		equ 0x2010

VFSJUMPOFFSET		equ 0x9B	; 0xAE - 0x13 
MOD_VFS_UMOUNT		equ 0x2013
MOD_VFS_OPENDIR		equ 0x2016
MOD_VFS_OPEN		equ 0x2019
MOD_VFS_UNLINK		equ 0x201C
MOD_VFS_MKDIR		equ 0x201F
MOD_VFS_RMDIR		equ 0x2022
MOD_VFS_SIZE		equ 0x2025
MOD_VFS_FREE		equ 0x2028
MOD_VFS_STAT		equ 0x202B
MOD_VFS_CHMOD		equ 0x202E
MOD_VFS_READ		equ 0x2031
MOD_VFS_WRITE		equ 0x2034
MOD_VFS_LSEEK		equ 0x2037
MOD_VFS_CLOSE		equ 0x203A
MOD_VFS_POLL		equ 0x203D
MOD_VFS_READDIR		equ 0x2040
MOD_VFS_CLOSEDIR	equ 0x2043

