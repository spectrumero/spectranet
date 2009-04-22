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

;--------------------------------------------------------------------------
; F_tbas_loader
; The BASIC LOAD command. Opens the named file, reads the header, then
; decides how to load the file from the header information contained.
; Parameters	HL = pointer to filename
;		DE = memory address to load to for CODE files
F_tbas_loader
	ld (v_desave), de	; save address
	ld a, O_RDONLY		; Open file read only
	ld b, 0x00		; with no flags
	call F_tnfs_open	
	ret c			; return if the open operation fails
	ld (v_tnfs_curfd), a	; save the returned filehandle
	ld de, INTERPWKSPC	; set destination pointer to workspace
	call F_tbas_getheader	; Fetch the header
	jr c, .cleanupdie	; on error, clean up and return
	ld ix, INTERPWKSPC+3	; start of "tape" header in a TAP file
	ld a, (INTERPWKSPC+3)	; get the type byte
	and a			; type 0? BASIC program
	jr nz, .testcode	; No, test for CODE
	call F_tbas_loadbasic	; Load a BASIC program
	jr c, .cleanupdie	; handle errors
.cleanup
	ld a, (v_tnfs_curfd)
	call F_tnfs_close
	ret
.testcode
	; TODO: handle CODE files
	ld a, TUNKTYPE
	scf
	ret

.cleanupdie
	push af			; save error code
	ld a, (v_tnfs_curfd)		; and attempt to close the file
	call F_tnfs_close
	pop af			; restore error and return with it.
	ret

;--------------------------------------------------------------------------
; F_tbas_getheader
; Reads a block header into memory from the file handle in v_tnfs_curfd.
; Spectranet files are the same format as TAP files, so each block has
; a 2 byte length, followed by data. This function reads the length
; and places the complete header into the memory address specified 
; by DE. On error, it returns with carry set and A containing the error
; number. On success, the file type is returned in A.
F_tbas_getheader
	push de			; save pointer
	ld a, (v_tnfs_curfd)	; get the current file descriptor
	ld bc, TNFS_HDR_LEN	; 19 bytes (length + ZX header block)
	call F_tnfs_read
	pop hl			; get the pointer back but in hl
	ret c			; error occurred in read
	ld a, (hl)
	cp 0x13			; first byte must be 0x13
	jr nz, .wronglen
	inc hl
	ld a, (hl)		; second byte must be 0x00
	and a
	jr nz, .wronglen
	inc hl
	ld a, (hl)		; type must be 0x00 - "header"
	and a
	jr nz, .wrongblktype
	inc hl
	ld a, (hl)		; return the type byte
	ret			; TODO: Check the checksum etc.
.wronglen
	ld a, TBADLENGTH
	scf
	ret
.wrongblktype
	ld a, TBADTYPE
	scf
	ret

;----------------------------------------------------------------------------
; F_tbas_loadblock
; Loads a TAP block
; Parameters: DE = where to copy in memory
;             v_tnfs_curfd contains the file descriptor
F_tbas_loadblock
	push de			; save destination ptr
	push bc			; save length
	ld de, INTERPWKSPC	; get the length from TAP block
	ld bc, 3		; 3 bytes long (length + flags)
	ld a, (v_tnfs_curfd)
	call F_tnfs_read	; read the TAP header
	pop bc			; get the length
	pop de			; and destination pointer
	ret c			; and leave on read error
	ld hl, (INTERPWKSPC)	; sanity check TAP length
	dec hl			; which should be length in ZX header + 2
	dec hl
	sbc hl, bc		; zero flag is set if length is correct
	jr nz, .lengtherr
	ld h, b			; copy length remaining into HL
	ld l, c
.loadloop
	ld a, (v_tnfs_curfd)	; get file descriptor
	push hl			; save length remaining
	call F_tnfs_read
	pop hl			; get current length back into HL
	ret c			; bale out if we've got an error condition
	sbc hl, bc		; decrement length remaining
	ld b, h			; and update data request
	ld c, l
	jr nz, .loadloop	; continue until 0 bytes left
	ret
.lengtherr
	di
	call F_regdump
	halt

	ld a, TBADLENGTH
	scf
	ret

;----------------------------------------------------------------------------
; F_tbas_loadbasic
; Load a program written in BASIC.
; Parameters: IX points to the "tape" header (i.e. TAP block + 2)
;             v_tnfs_curfd contains the file descriptor
; Much of this is modelled on the ZX ROM loader.
F_tbas_loadbasic
	ld hl, (ZX_E_LINE)	; End marker of current variables area
	ld de, (ZX_PROG)	; Destination address
	dec hl
	ld (v_ixsave), ix	; save IX
	ld c, (ix+0x0b)		; Length argument in "tape" header
	ld b, (ix+0x0c)
	push bc			; save the length
	rst CALLBAS
	defw ZX_RECLAIM_1	; Reclaim present program/vars
	pop bc
	push hl			; Save program area pointer
	push bc			; and length
	rst CALLBAS
	defw ZX_MAKE_ROOM	; Call MAKE_ROOM to make speace for program
	ld ix, (v_ixsave)	; restore IX
	inc hl			; The system variable VARS
	ld c, (ix+0x0f)		; needs to be set.
	ld b, (ix+0x10)
	add hl, bc
	ld (ZX_VARS), hl
				; TODO: Consider LINE number in header
	pop bc			; fetch the length
	pop de			; fetch the start

	jp F_tbas_loadblock	; load the block

