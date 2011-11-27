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
.include	"fcntl.inc"
.include	"stat.inc"
.include	"spectranet.inc"
.include	"zxrom.inc"
.include	"defs.inc"
.include	"sysvars.inc"
.include	"zxsysvars.inc"
.include	"errno.inc"
.text
; TAP load/save functions
;------------------------------------------------------------------------
; F_tbas_readrawfile
; Reads a raw file off the filesystem, without looking to see if it has
; a header.
; Parameters: HL = pointer to filename
;             DE = memory location to place the result
; Returns with carry set and A=error number on error.
.globl F_tbas_readrawfile
F_tbas_readrawfile:
	push de			; save pointer
	push bc
	ld de, O_RDONLY		; LOADing is read only
	ld bc, 0x0000		; No mode
	call OPEN		; Filename pointer is already in HL
	pop bc
	pop de
	ret c
	ld (v_vfs_curfd), a	; save the filehandle
.readloop1:
	ld a, (v_vfs_curfd)	; restore filehandle
	ld bc, 512		; read max 512 bytes
	call READ
	jr nc, .readloop1	; keep going until nothing more can be read
	cp EOF			; End of file?
	jr nz, .failed1		; No - something went wrong
	ld a, (v_vfs_curfd)	; Close the file
	jp VCLOSE
.failed1:
	push af			; preserve return code
	ld a, (v_vfs_curfd)
	call VCLOSE		; close the file
	pop af			; but let the earlier return code have
	scf			; precedence over any errors that close throws
	ret			; up.

;--------------------------------------------------------------------------
; F_tbas_loader
; The BASIC LOAD command. Opens the named file, reads the header, then
; decides how to load the file from the header information contained.
; Parameters	HL = pointer to filename
;		DE = memory address to load to for CODE files
;               A  = type to expect
.globl F_tbas_loader
F_tbas_loader:
	push bc
	ld (INTERPWKSPC+21), a	; save the type parameter
	ld (v_desave), de	; save address
	ld de, O_RDONLY		; Open file read only
	ld bc, 0x0000		; with no mode
	call OPEN
	pop bc
	ret c			; return if the open operation fails
	ld (v_vfs_curfd), a	; save the returned filehandle
	ld de, INTERPWKSPC	; set destination pointer to workspace
	call F_tbas_getheader	; Fetch the header
	jp c, J_cleanuperror	; on error, clean up and return
	ld ix, INTERPWKSPC+3	; start of "tape" header in a TAP file
	ld a, (INTERPWKSPC+21)	; get the type byte
	cp (ix+0)		; check that it's the right type
	jr nz, .wrongtype2
	and a			; type 0? BASIC program
	jr nz, .testcode2	; No, test for CODE
	call F_tbas_loadbasic	; Load a BASIC program
	jp c, J_cleanuperror	; handle errors
.cleanup2:
	ld a, (v_vfs_curfd)
	call VCLOSE
	ret
.testcode2:
	cp 0x03			; type CODE
	jr nz, .unktype2		; not a type we know
	ld de, (INTERPWKSPC+OFFSET_PARAM1)	; get the start address
	ld bc, (INTERPWKSPC+OFFSET_LENGTH)	; and the expected length
	call F_tbas_loadblock	; and load the TAP block
	jr .cleanup2
.wrongtype2:
	; TODO: handle CODE files
	ld a, TBADTYPE
	scf
	ret
.unktype2:
	ld a, TUNKTYPE
	scf
	ret

;--------------------------------------------------------------------------
; F_tbas_getheader
; Reads a block header into memory from the file handle in v_vfs_curfd.
; Spectranet files are the same format as TAP files, so each block has
; a 2 byte length, followed by data. This function reads the length
; and places the complete header into the memory address specified 
; by DE. On error, it returns with carry set and A containing the error
; number. On success, the file type is returned in A.
.globl F_tbas_getheader
F_tbas_getheader:
	push de			; save pointer
	ld a, (v_vfs_curfd)	; get the current file descriptor
	ld bc, TNFS_HDR_LEN	; 19 bytes (length + ZX header block)
	call READ
	pop hl			; get the pointer back but in hl
	ret c			; error occurred in read
	ld a, (hl)
	cp 0x13			; first byte must be 0x13
	jr nz, .wronglen3
	inc hl
	ld a, (hl)		; second byte must be 0x00
	and a
	jr nz, .wronglen3
	inc hl
	ld a, (hl)		; type must be 0x00 - "header"
	and a
	jr nz, .wrongblktype3
	inc hl
	ld a, (hl)		; return the type byte
	ret			; TODO: Check the checksum etc.
.wronglen3:
	ld a, TBADLENGTH
	scf
	ret
.wrongblktype3:
	ld a, TBADTYPE
	scf
	ret

;----------------------------------------------------------------------------
; F_tbas_loadblock
; Loads a TAP block
; Parameters: DE = where to copy in memory
;	      BC = expected length
;             v_vfs_curfd contains the file descriptor
.globl F_tbas_loadblock
F_tbas_loadblock:
	push de			; save destination ptr
	push bc			; save length
	ld de, INTERPWKSPC	; get the length from TAP block
	ld bc, 3		; 3 bytes long (length + flags)
	ld a, (v_vfs_curfd)
	call READ		; read the TAP header
	pop bc			; get the length
	pop de			; and destination pointer
	ret c			; and leave on read error
	ld hl, (INTERPWKSPC)	; sanity check TAP length
	dec hl			; which should be length in ZX header + 2
	dec hl
	sbc hl, bc		; zero flag is set if length is correct
	jr nz, .lengtherr4
.loadloop4:
	ld a, (v_vfs_curfd)	; get file descriptor
	call READ
	ret
.lengtherr4:
	ld a, TMISMCHLENGTH	; Length of data block doesn't match header
	scf
	ret

;----------------------------------------------------------------------------
; F_tbas_loadbasic
; Load a program written in BASIC.
; Parameters: IX points to the "tape" header (i.e4. TAP block + 2)
;             v_vfs_curfd contains the file descriptor
; Much of this is modelled on the ZX ROM loader.
.globl F_tbas_loadbasic
F_tbas_loadbasic:
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
	ld h, (ix+0x0e)		; Check for LINE number
	ld a, h
	and 0xC0
	jr nz, .loadblock5	; No line number - skip to loader
	ld l, (ix+0x0d)		; HL = line number
	ld (ZX_NEWPPC), hl	; set line number to jump to
	xor a
	ld (ZX_NSPPC), a	; Statement number 0

.loadblock5:
	pop bc			; fetch the length
	pop de			; fetch the start

	jp F_tbas_loadblock	; load the block

;--------------------------------------------------------------------------
; F_tbas_mktapheader
; Create a TAP header with filename and type.
; Parameters		A = type
;			DE = filename
;			BC = filename length
.globl F_tbas_mktapheader
F_tbas_mktapheader:
	push de
	push bc
	; Create the header
	ld hl, 0x13		; length of header block in TAP format
	ld (INTERPWKSPC), hl
	ld (INTERPWKSPC+3), a	; save the type byte
	xor a
	ld (INTERPWKSPC+2), a	; is a header block, set to 0x00
	ld a, 10		; > 10 chars in the filename?
	cp b
	jr nc, .continue6
	ld c, 10		; copy max of 10
.continue6:
	ld b, c			; prepare to copy string
	ld hl, INTERPWKSPC+4
.loop6:
	ld a, (de)		; copy the string
	ld (hl), a
	inc de
	inc hl
	djnz .loop6
	ld a, 10		; find remaining bytes
	sub c
	jr z, .exit6		; nothing to do!
	ld b, a			; A now contains the loop count
.spaces6:
	ld (hl), 0x20		; fill the rest with spaces
	inc hl
	djnz .spaces6
.exit6:
	pop bc
	pop de
	ld hl, 0		; make the parameters default to 0
	ld (INTERPWKSPC+OFFSET_PARAM1), hl
	ld h, 0x80		; the default when no param2
	ld (INTERPWKSPC+OFFSET_PARAM2), hl
	ret

;---------------------------------------------------------------------------
; F_tbas_writefile
; Writes a file from a %SAVE command. The header must be complete and stored
; in INTERPWKSPC.
; Parameters:		DE = pointer to filename
;			BC = length of filename (i.e6. from ZX_STK_FETCH)
; On error returns with carry set and A = errno.
.globl F_tbas_writefile
F_tbas_writefile:
	ld hl, INTERPWKSPC+21	; convert filename to a C string
	call F_basstrcpy

	push bc
	ld hl, INTERPWKSPC+21	; Open the file for write (the full C string
	ld de, O_WRONLY | O_CREAT 		; for the filename is in mem after the header)
	ld bc, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH	; mode 0666 -rw-rw-rw-
	call OPEN		; Open the file.
	pop bc
	ret c
	ld (v_vfs_curfd), a	; store the file descriptor

	ld hl, INTERPWKSPC+OFFSET_TYPE	; checksum the header
	ld bc, ZX_HEADERLEN
	xor a			; start with 0x00 for header block
	call F_tbas_mkchecksum
	ld (INTERPWKSPC+OFFSET_CHKSUM), a
	ld hl, INTERPWKSPC	; write the 21 byte TAP block
	ld a, (v_vfs_curfd)
	ld bc, 21
	call WRITE
	jp c, J_cleanuperror

	ld hl, (INTERPWKSPC+OFFSET_LENGTH)
	inc hl			; add 2 for the 0xFF data block byte
	inc hl			; and check byte
	ld (INTERPWKSPC), hl	; create TAP header and ZX data block
	ld a, 0xFF		; which consists of a 16 bit length 
	ld (INTERPWKSPC+2), a	; followed by 0xFF
	ld a, (v_vfs_curfd)
	ld hl, INTERPWKSPC
	ld bc, 3

	call WRITE		; write it out
	jp c, J_cleanuperror

.writedata7:
	ld a, (INTERPWKSPC+OFFSET_TYPE)	; find the type of block we´re saving
	and a			; if zero, it is BASIC
	jr nz, .testcode7	; if not jump forward
	ld hl, (ZX_PROG)	; find the start of the program
	jr .save7
.testcode7:
	cp 3			; type CODE
	jr nz, .badtype7		; TODO: character/number arrays
	ld hl, (INTERPWKSPC+OFFSET_PARAM1)	; get the start address
.save7:
	ld bc, (INTERPWKSPC+OFFSET_LENGTH)	; length
	push hl			; save values so we can calculate the
	push bc			; checksum (TODO optimize)
.saveloop7:
	ld a, (v_vfs_curfd)	; get file descriptor
	call WRITE
	jr c, .cleanuperror7	; exit on error
.done7:
	pop bc			; retrieve original size
	pop hl			; and start address
	ld a, 0xFF		; start with 0xFF for data block
	call F_tbas_mkchecksum
	ld (INTERPWKSPC), a	; store result
	ld a, (v_vfs_curfd)	; TODO: checksum saving could do with
	ld hl, INTERPWKSPC	; being optimized!
	ld bc, 1
	call WRITE
	jp c, J_cleanuperror	
	ld a, (v_vfs_curfd)	; close the file.
	call VCLOSE
	ret
.badtype7:
	ld a, TBADTYPE
	scf
	jp J_cleanuperror
.cleanuperror7:
	pop bc			; restore stack
	pop hl
	jp J_cleanuperror

;---------------------------------------------------------------------------
; F_tbas_mkchecksum
; Make checksum for "tape" blocks.
; Parameters:		HL = pointer to block
;			BC = size
;			A = initial byte
; Result is returned in A.
.globl F_tbas_mkchecksum
F_tbas_mkchecksum:
.loop8:
	xor (hl)		; the checksum is made just by XORing each
	inc hl			; byte.
	dec bc
	ld e, a			; save A
	ld a, b
	or c			; BC = 0?
	ld a, e			; restore A
	jr nz, .loop8
	ret

;----------------------------------------------------------------------------
; Generic 'clean up and leave'
J_cleanuperror:
	push af			; save error code
	ld a, (v_vfs_curfd)	; and attempt to close the file
	call VCLOSE
	pop af			; restore error and return with it.
	ret

