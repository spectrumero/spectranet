;The MIT License
;
;Copyright (c) 2008 Dylan Smith
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

; General definitions. These are not hardware specific (generally).

; File descriptor flags.
FD_CLOSED	equ 0x80
CLOSEDBIT	equ 7
FD_VIRTUAL	equ 0x40
VIRTBIT		equ 6
FD_VFS		equ 0x20	; for file descriptors that are valid
VFSBIT		equ 5		; but are not sockets
NOTSOCKMASK	equ 0xE0	; all hw sockets must be < 0x1F
SOCKMASK	equ 0x1F

; Error return codes - base socket library
EBUGGERED	equ 0xFF
ESNFILE		equ 0xFE	; TODO: Rationalize these and make
ESBADF		equ 0xFD	; compatible with filesystem
ECONNRESET	equ 0xFC	
ETIMEDOUT	equ 0xFB
ECONNREFUSED	equ 0xFA

; Error return codes - DNS
HOST_NOT_FOUND	equ 0xEF
NO_RECOVERY	equ 0xEE
NO_ADDRESS	equ 0xED
DNS_TIMEOUT	equ 0xEC

; Socket types
SOCK_STREAM	equ 0x01
SOCK_DGRAM	equ 0x02
SOCK_RAW	equ 0x03

