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

; String table
.data 
.globl STRING_TABLE
STRING_TABLE:
STR_SUCCESS:    defb    "Success",0                             ; 0x00
STR_EPERM:      defb    "Operation not permitted",0             ; 0x01
STR_ENOENT:     defb    "No such file or directory",0           ; 0x02
STR_EIO:        defb    "I/O error",0                           ; 0x03
STR_ENXIO:      defb    "No such device or address",0           ; 0x04
STR_E2BIG:      defb    "Too many arguments",0                  ; 0x05
STR_EBADF:      defb    "Bad file descriptor",0                 ; 0x06
STR_EAGAIN:     defb    "Operation would block",0               ; 0x07
STR_ENOMEM:     defb    "Out of memory",0                       ; 0x08
STR_EACCES:     defb    "Permission denied",0                   ; 0x09
STR_EBUSY:       defb    "Device or resource busy",0             ; 0x0A
STR_EEXIST:      defb    "File exists",0                         ; 0x0B
STR_ENOTDIR:     defb    "Not a directory",0                     ; 0x0C
STR_EISDIR:      defb    "Is a directory",0                      ; 0x0D
STR_EINVAL:      defb    "Invalid argument",0                    ; 0x0E
STR_ENFILE:      defb    "File table overflow",0                 ; 0x0F
STR_EMFILE:      defb    "Too many open files",0                 ; 0x10
STR_EFBIG:       defb    "File too large",0                      ; 0x11
STR_ENOSPC:      defb    "Filesystem full",0                     ; 0x12
STR_ESPIPE:      defb    "Attempt to seek on a pipe",0           ; 0x13
STR_EROFS:       defb    "Read only filesystem",0                ; 0x14
STR_ENAMETOOLONG: defb   "Filename too long",0                   ; 0x15
STR_ENOSYS:      defb    "Not implemented",0                     ; 0x16
STR_ENOTEMPTY:   defb    "Directory not empty",0                 ; 0x17
STR_ELOOP:       defb    "Too many links",0                      ; 0x18
STR_ENODATA:     defb    "No data available",0                   ; 0x19
STR_ENOSTR:      defb    "Out of streams",0                      ; 0x1A
STR_EPROTO:      defb    "Protocol error",0                      ; 0x1B
STR_EBADFD:      defb    "File descriptor state bad",0           ; 0x1C
STR_EUSERS:      defb    "Too many users",0                      ; 0x1D
STR_ENOBUFS:     defb    "No buffer space available",0           ; 0x1E
STR_EALREADY:    defb    "Operation already running",0           ; 0x1F
STR_ESTALE:      defb    "Stale TNFS handle",0                   ; 0x20
STR_EOF:         defb    "End of file",0                         ; 0x21

; Non-protocol error messages
STR_TIMEOUT:     defb    "Operation timed out",0                 ; 0x22
STR_NOTMOUNTED:  defb    "Filesystem not mounted",0              ; 0x23
STR_BADLENGTH:   defb    "Incorrect header length",0             ; 0x24
STR_BADTYPE:     defb    "Incorrect block type",0                ; 0x25
STR_UNKTYPE:     defb    "Unknown file type",0                   ; 0x26
STR_MISMCHLEN:   defb    "Data block length mismatch",0          ; 0x27
STR_EBADURL:     defb    "Bad URL",0                             ; 0x28
STR_EBADFS:      defb    "Bad filesystem number",0               ; 0x29
STR_EMPBUSY:     defb    "Mount point already used",0            ; 0x2A
STR_EUNKPROTO:   defb    "Unknown filesystem type",0             ; 0x2B

ERR_TABLE_END:
STR_UNKNOWN:     defb    "Unknown error",0

.globl ERR_TABLE_LEN
ERR_TABLE_LEN	equ ERR_TABLE_END - STRING_TABLE

; Base rom messages
.globl STR_HITABLE
.globl HITABLE_LOWEST
STR_HITABLE:
HITABLE_LOWEST	equ 0xEC
STR_DNS_TIMEOUT:	defb	"DNS timeout",0				; 0xEC
STR_NO_ADDRESS:	defb	"No address",0				; 0xED
STR_NO_RECOVERY:	defb	"No recovery",0				; 0xEE
STR_HOST_NOT_FOUND: defb	"Host not found",0			; 0xEF
		defb 0,0,0,0,0,0,0,0,0,0			; 0xF0-0xF9
STR_ECONNREFUSED: defb	"Connection refused",0			; 0xFA
STR_ETIMEDOUT:	defb	"Socket timeout",0			; 0xFB
STR_ECONNRESET:	defb	"Connection reset by peer",0		; 0xFC
STR_ESBADF:	defb	"Bad socket descriptor",0		; 0xFD
STR_ESNFILE:	defb	"Invalid socket descriptor",0		; 0xFE
STR_EUNK:	defb	"General socket error",0		; 0xFF
HITABLE_END:

.globl HITABLE_LEN
HITABLE_LEN	equ HITABLE_END - STR_HITABLE

