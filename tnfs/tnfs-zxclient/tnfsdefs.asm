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

; TNFS definitions.

tnfs_polltime		equ 65535	; How long we should wait for a reply
tnfs_recv_buffer	equ 0x9000	; TODO: A place in Spectranet RAM
tnfs_max_retries	equ 5

; Standard header offsets
tnfs_sid_offset		equ 0
tnfs_seqno_offset	equ 2
tnfs_cmd_offset		equ 3
tnfs_err_offset		equ 4
tnfs_msg_offset		equ 5

; Mount group
TNFS_OP_MOUNT		equ 0
TNFS_OP_UMOUNT		equ 1

; Directory group
TNFS_OP_OPENDIR		equ 0x10
TNFS_OP_READDIR		equ 0x11
TNFS_OP_CLOSEDIR	equ 0x12
TNFS_OP_MKDIR		equ 0x13
TNFS_OP_RMDIR		equ 0x14

; File group
TNFS_OP_OPEN		equ 0x20
TNFS_OP_READ		equ 0x21
TNFS_OP_WRITE		equ 0x22
TNFS_OP_CLOSE		equ 0x23
TNFS_OP_STAT		equ 0x24
TNFS_OP_LSEEK		equ 0x25
TNFS_OP_UNLINK		equ 0x26
TNFS_OP_CHMOD		equ 0x27

; Utility group
TNFS_OP_SIZE		equ 0x30
TNFS_OP_FREE		equ 0x31

; TNFS error codes - not surprisingly, nearly all the same as POSIX...
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

; Non protocol codes
TTIMEOUT		equ 0x22
TNOTMOUNTED		equ 0x23
TBADLENGTH		equ 0x24
TBADTYPE		equ 0x25
TUNKTYPE		equ 0x26

; File mode and flag definitions
O_RDONLY		equ 0x01

