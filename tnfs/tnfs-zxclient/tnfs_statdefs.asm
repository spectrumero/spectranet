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

; Definitions for things returned by stat

; Bitmasks for the filemode field.
; These are defined by POSIX as a 16 bit octal value. The list below
; has been converted to hex, since not all assemblers support octal.
S_IFMT		equ	0xF000
S_IFSOCK	equ	0xC000
S_IFLNK		equ	0xA000
S_IFREG		equ	0x8000
S_IFBLK		equ	0x6000
S_IFDIR		equ	0x4000
S_IFCHR		equ	0x2000
S_IFIFO		equ	0x1000
S_ISUID		equ	0x0800
S_ISGID		equ	0x0400
S_ISVTX		equ	0x0200
S_IRWXU		equ	0x01C0
S_IRUSR		equ	0x0100
S_IWUSR		equ	0x0080
S_IXUSR		equ	0x0040
S_IRGRP		equ	0x0020
S_IWGRP		equ	0x0010
S_IXGRP		equ	0x0008
S_IROTH		equ	0x0004
S_IWOTH		equ	0x0002
S_IXOTH		equ	0x0001

