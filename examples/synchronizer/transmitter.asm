;The MIT License
;
;Copyright (c) 2014 Dylan Smith
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

; This routine transmits a datagram on the socket that was opened.
; The destination address must be POKEd (or otherwise copied into) the
; sockinfo structure. See the map file for the structure's start
; address (and the wiki documentation for its format, or the README.TXT
; file that explains the usage). The buffer (again see the map file)
; can be POKEd with 2 bytes which the receiver will get.
; Caling F_setport will set the port to use.

.include "spectranet.inc"
.include "sockdefs.inc"
.include "sync.inc"

.text

.globl F_setport
F_setport:
    ld hl, port
    ld (sockinfo+4), hl
    ret
    
.globl F_transmit
F_transmit:
    call PAGEIN
    ld a, (syncsock)
    ld hl, sockinfo
    ld de, buffer
    ld bc, 2
    call SENDTO
    jp c, J_error

    jp PAGEOUT

