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

; An example of using UDP datagrams to be able to get multiple
; Spectrums to do something, such as synchronizing the playing of different
; parts of a beeper tune with multiple machines (of course latency
; must be taken into account!)
; Code can be called by BASIC, the 2-byte value in the datagram we got sent
; will be returned in BC (therefore BASIC will see it as the return code
; from the USR function)

.include "spectranet.inc"
.include "sockdefs.inc"
.include "sync.inc"

.text
    
; Wait for a datagram to come in, and put the first 2 bytes of the 
; received datagram into BC
.globl F_wait
F_wait:
    call PAGEIN
    ld a, (syncsock)
    ld hl, sockinfo
    ld de, buffer
    ld bc, 2
    call RECVFROM               ; this will block until we get a datagram
    jp c, J_error

    ld bc, (buffer)             ; BASIC gets this value from usr

    jp PAGEOUT

