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

; File mode oflag definitions
O_RDONLY		equ 0x0001
O_WRONLY		equ 0x0002
O_RDWR			equ 0x0003
O_ACCMODE		equ 0x0003

O_EXEC			equ 0x0004
O_APPEND		equ 0x0008

O_CREAT			equ 0x0100
O_TRUNC			equ 0x0200
O_EXCL			equ 0x0400

; Seek definitions
SEEK_SET		equ 0x00
SEEK_CUR		equ 0x01
SEEK_END		equ 0x02

