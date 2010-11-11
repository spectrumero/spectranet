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

; Definitions for streams.

; Flags that describe what kind of stream we have.
ISFILE		equ 1
RDONLY		equ 2 
ISDIR		equ 4
ISCTRL		equ 8

; Bit positions for the above
BIT_ISFILE	equ 0
BIT_RDONLY	equ 1
BIT_ISDIR	equ 2
BIT_ISCTRL	equ 3

; Offsets for stream metadata.
STRM_WRITEBUF	equ 0		; Write buffer number
STRM_READBUF	equ 1		; Read buffer number
STRM_WRITEPTR	equ 2		; Write pointer
STRM_READPTR	equ 3		; Read pointer
STRM_FD		equ 4		; File/socket/dir handle
STRM_FLAGS	equ 5		; Flags bitfield
STRM_REMAINING	equ 6		; Remaining buffer size

; State variables - offsets (note offset 5 is STRM_FLAGS)
OFS_FLAGS       equ 0
OFS_CURCMD      equ 1
OFS_CURSTATE    equ 2
OFS_STREAM      equ 3
OFS_CURDATA     equ 6		

; Definitions.
BUFMETADATA     equ 0x1000
BUFDATASZ       equ 8

; Command definitions for the control channel
CMD_POLLALL	equ 'p'

STREAM_ROM_ID	equ 0x02
INTERPWKSPC	equ 0x3000
