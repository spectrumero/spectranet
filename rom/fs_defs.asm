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

; Definitions for TAP header blocks
TNFS_HDR_LEN		equ 21		; 3 byte TAP + 17 bytes ZX + check byte
OFFSET_HDRBYTE		equ 2		; 0x00 = header, 0xFF = data
OFFSET_TYPE		equ 3		; Type ID, 0=bas, 3=code
OFFSET_FILENAME		equ 4		; 10 bytes of filename
OFFSET_LENGTH		equ 14		; 2 byte little endian length
OFFSET_PARAM1		equ 16		; 2 byte little endian
OFFSET_PARAM2		equ 18		; 2 byte little endian
OFFSET_CHKSUM		equ 20		; "checksum" byte
ZX_HEADERLEN		equ 17		; Length of ZX header excl. check byte

; FS error codes - not surprisingly, nearly all the same as POSIX...
ESUCCESS		equ 0x00
EPERM			equ 0x01
ENOENT			equ 0x02
EIO			equ 0x03
ENXIO			equ 0x04
E2BIG			equ 0x05
EBADF			equ 0x06
EAGAIN			equ 0x07
ENOMEM			equ 0x08
EACCES			equ 0x09
EBUSY			equ 0x0A
EEXIST			equ 0x0B
ENOTDIR			equ 0x0C
EISDIR			equ 0x0D
EINVAL			equ 0x0E
ENFILE			equ 0x0F
EMFILE			equ 0x10
EFBIG			equ 0x11
ENOSPC			equ 0x12
ESPIPE			equ 0x13
EROFS			equ 0x14
ENAMETOOLONG		equ 0x15
ENOSYS			equ 0x16
ENOTEMPTY		equ 0x17
ELOOP			equ 0x18
ENODATA			equ 0x19
ENOSTR			equ 0x1A
EPROTO			equ 0x1B
EBADFD			equ 0x1C
EUSERS			equ 0x1D
ENOBUFS			equ 0x1E
EALREADY		equ 0x1F
ESTALE			equ 0x20
EOF			equ 0x21

; FS related wire protocol errors
TTIMEOUT		equ 0x22
TNOTMOUNTED		equ 0x23
TBADLENGTH		equ 0x24
TBADTYPE		equ 0x25
TUNKTYPE		equ 0x26
TMISMCHLENGTH		equ 0x27

; File mode and flag definitions
O_RDONLY		equ 0x01
O_WRONLY		equ 0x02
O_RDWR			equ 0x03
O_APPEND		equ 0x01
O_CREAT			equ 0x02
O_EXCL			equ 0x04
O_TRUNC			equ 0x08

