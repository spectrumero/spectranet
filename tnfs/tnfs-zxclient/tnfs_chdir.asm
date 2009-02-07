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

; chdir functions.
; TNFS or the TNFS server doesn't have the concept of a working directory
; - everything requires an absolute path. The client implements chdir
; by storing the CWD, and for chdir operations, stats the path that
; is being chdir'd to, to make sure it is in fact a directory. If so then
; it stores the new absolute path in its CWD buffer.

;-----------------------------------------------------------------------
; F_tnfs_chdir
; Parameters	HL = path to chdir to
; On error returns with the carry flag set and A=error number
F_tnfs_chdir
	ld a, (hl)		; check for an absolute path
	cp '/'
	jr z, .statpath		; is absolute - jump straight to stat check
	ld de, buf_tnfs_wkspc1	; Assemble absolute path in TNFS workspace
	call F_tnfs_abspath	; create the absolute path from the relative
	ld hl, buf_tnfs_wkspc1	; absolute path is now here
.statpath
	push hl
	ld de, buf_tnfs_wkspc2	; result of stat in the second workspace
	call F_tnfs_stat	; stat the path
	jr c, .error		; stat returned an error
	ld hl, buf_tnfs_wkspc2+1 ; MSB of stat filemode bitfield
	ld a, S_IFDIR / 256	; MSB of S_IFDIR bitfield
	and (hl)		; AND it all together...
	jr z, .notadir		; ...if zero, it wasn't a directory.
	pop hl
	ld de, v_cwd		; copy the path as the new working directory
	ld b, 255
	call F_tnfs_strcpy
	ret
.notadir
	ld a, ENOTDIR
	scf
.error	
	pop hl
	ret
