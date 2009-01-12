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

; The TNFS mount and umount functions.

;-----------------------------------------------------------------------
; F_tnfs_mount: Mount a remote filesystem.
; Arguments:	IX = pointer to 8 byte structure containing
;			byte 0,1 - pointer to null terminated hostname
;                       byte 2,3 - pointer to null terminated mount point
;                       byte 4,5 - pointer to null terminated user id
;                       byte 6,7 - pointer to null terminated passwd
; On success, returns the session number in HL. On error, returns the
; error number in HL and sets the carry flag.
F_tnfs_mount
	ld de, buf_workspace	; first look up the host
	ld l, (ix+1)
	ld h, (ix+0)
	call GETHOSTBYNAME
	ret c

	; We've successfully looked up a host so create the datagram
	; that will be sent.
	ld hl, buf_workspace+4
	ld de, 0		; no session id yet
	xor a			; cmd is 0x00
	call F_tnfs_header	; create the header, HL now at the next byte
	ex de, hl		; make destination = DE
