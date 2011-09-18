;The MIT License
;
;Copyright (c) 2011 Dylan Smith
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

; Error number definitions.
SUCCESS		equ 	0x00	; Not an error, success return code
EPERM		equ	0x01	; Operation not permitted
ENOENT		equ	0x02	; No such file or directory
EIO		equ	0x03	; IO error
ENXIO		equ	0x04	; No such device or address
E2BIG		equ	0x05	; Too many arguments
EBADF		equ	0x06	; Bad file descriptor
EAGAIN		equ	0x07	; Operation would block
ENOMEM		equ	0x08	; Out of memory
EACCES		equ 	0x09	; Permission denied
EBUSY		equ	0x0A	; Device or resource busy
EEXIST		equ	0x0B	; File exists
ENOTDIR		equ	0x0C	; Not a directory
EISDIR		equ	0x0D	; Is a directory
EINVAL		equ	0x0E	; Invalid argument
ENFILE		equ	0x0F	; File table overflow
EMFILE		equ	0x10	; Too many open files
EFBIG		equ	0x11	; File too large
ENOSPC		equ	0x12	; Filesystem full
ESPIPE		equ	0x13	; Attempt to seek on a pipe
EROFS		equ	0x14	; Read only filesystem
ENAMETOOLONG	equ	0x15	; Filename too long
ENOSYS		equ	0x16	; Not implemented
ENOTEMPTY	equ	0x17	; Directory not empty
ELOOP		equ	0x18	; Too many symbolic links
ENODATA		equ	0x19	; No data available
ENOSTR		equ	0x1A	; Out of streams
EPROTO		equ	0x1B	; Protocol error
EBADFD		equ	0x1C	; File descriptor bad
EUSERS		equ	0x1D	; Too many users
ENOBUFS		equ	0x1E	; Out of buffer space
EALREADY	equ	0x1F	; Operation already running
ESTALE		equ	0x20	; Stale filesystem handle
EOF		equ	0x21	; End of file

; Non-protocol/non core FS errors
TTIMEOUT	equ	0x22	; Operation timed out
TNOTMOUNTED	equ	0x23	; Filesystem not mounted
TBADLENGTH	equ	0x24	; Incorrect header length
TBADTYPE	equ	0x25	; Invalid block type
TUNKTYPE	equ	0x26	; Unknown file type
TMISMCHLENGTH	equ	0x27	; Data block length mismatch
TBADURL		equ	0x28	; Bad URL
TBADFS		equ	0x29	; Bad FS number

