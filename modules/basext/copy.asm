;The MIT License
;
;Copyright (c) 2011 Dylan Smith
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

; The copy command

.include	"defs.inc"
.include	"fcntl.inc"
.include	"spectranet.inc"
.include	"stat.inc"
.include	"errno.inc"

;------------------------------------------------------------------------
; F_copy expects the destination filename in WORKSPACE and the
; source in WORKSPACE+256.
.globl F_copy
F_copy:
	call F_chkpath

	; Open the source file for read.
	ld hl, INTERPWKSPC+256
	ld de, O_RDONLY		; LOADing is read only
	ld bc, 0x0000		; No mode
	call OPEN
	ret c			; bale now if we can't open the src file
	ld (SRC_FD), a		; save the returned FD

	; Open the destination for write.
	ld hl, INTERPWKSPC
	ld de, O_WRONLY|O_CREAT
	ld bc, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH	; mode 0666 -rw-rw-rw-
	call OPEN
	jr c, .cleanup		; clean up opened file on error and return
	ld (DST_FD), a		; save the returned fd

	; We're now done with the filenames so we can re-use the workspace
	; for the data that will be copied.
.cploop:
	ld a, (SRC_FD)
	ld de, INTERPWKSPC
	ld bc, 256
	call READ
	jr c, .closefiles	; Probably at EOF, or an error occurred
	ld a, (DST_FD)
	ld hl, INTERPWKSPC
	call WRITE		; BC already set to bytes read
	jr nc, .cploop

.closefiles:
	push af
	ld a, (SRC_FD)
	call VCLOSE
	ld a, (DST_FD)
	call VCLOSE
	pop af
	cp EOF			; At EOF?
	ret z
	scf			; no, then make sure carry is still set
	ret			; to indicate error condition.

.cleanup:
	push af			; store error
	ld a, (SRC_FD)
	call VCLOSE
	pop af
	ret

;------------------------------------------------------------------------
; F_chkpath: Test the destination path:
; - if it's a directory, append the source filename
; - if it's a file that exists, return an error (C flag set)
; - if it's a file that doesn't exist, do nothing
.globl F_chkpath
F_chkpath:
	; First stat the destination to find if it's a directory.
	ld hl, INTERPWKSPC
	ld de, INTERPWKSPC+512
	call STAT
	jr c, .pathdone		; non-existent destination, that's OK, it
				; might be specifying a file that's
				; not yet been created.
	ld a, (INTERPWKSPC+512+STAT_MODE+1)
	and S_IFDIR / 256	; check directory flag
	jr nz, .catdir

	; If the destination is a file, we'll not overwrite it (this avoids
	; having to compare paths to test for file being copied onto itself
	; at the expense of not being able to use the copy command to
	; overwrite a file).
	ld a, EEXIST
	scf
	ret

.catdir:
	ld hl, INTERPWKSPC+256	; source filename
	call F_basename		; HL now points at the file name
	ex de, hl		; move into DE for the catpath call
	ld hl, INTERPWKSPC	; destination directory
	call F_catpath
.pathdone:
	or a			; reset carry
	ret	

