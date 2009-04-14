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

; TNFS BASIC loader routines

;------------------------------------------------------------------------
; F_tbas_readrawfile
; Reads a raw file off the filesystem, without looking to see if it has
; a header.
; Parameters: HL = pointer to filename
;             DE = memory location to place the result
; Returns with carry set and A=error number on error.
F_tbas_readrawfile
	push de			; save pointer
	ld a, O_RDONLY		; LOADing is read only
	ld b, 0x00		; No file flags
	call F_tnfs_open	; Filename pointer is already in HL
	pop de
	ret c
	ld (INTERPWKSPC), a	; save the filehandle
.readloop
	ld a, (INTERPWKSPC)	; restore filehandle
	ld bc, 512		; read max 512 bytes
	call F_tnfs_read
	jr nc, .readloop	; keep going until nothing more can be read
	cp EOF			; End of file?
	jr nz, .failed		; No - something went wrong
	ld a, (INTERPWKSPC)	; Close the file
	jp F_tnfs_close
.failed
	push af			; preserve return code
	ld a, (INTERPWKSPC)
	call F_tnfs_close	; close the file
	pop af			; but let the earlier return code have
	scf			; precedence over any errors that close throws
	ret			; up.
	
