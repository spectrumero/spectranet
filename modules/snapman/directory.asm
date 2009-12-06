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

; Read the current directory and filter files found.
	include "../../rom/fs_statdefs.asm"

;-------------------------------------------------------------------------
; F_loaddir
; Load the contents of a directory into memory.
F_loaddir
	xor a			; initialize vars
	ld (v_numdirs), a
	ld (v_numsnas), a
	ld hl, v_dirtable
	ld (v_dirptr), hl	; initialize dir listing
	ld hl, v_dirstrings
	ld (v_dirnextentry), hl	; initialize current entry
	ld hl, v_snatable
	ld (v_snaptr), hl	; initialize snapshot listing
	ld hl, v_snastrings
	ld (v_snanextentry), hl

	ld hl, STR_cwd		; current working directory
	call OPENDIR
	ret c
	ld (v_dhnd), a		; save the directory handle
.readloop
	ld de, v_dirwkspc
	call READDIR		; Get the next directory entry
	jr c, .readdone		; Probably EOF
	call F_filterdir	; Decide whether to store or discard
	ld a, (v_dhnd)		; Restore dirhandle
	jr .readloop
.readdone
	ld a, (v_dhnd)
	call CLOSEDIR
	ret

;------------------------------------------------------------------------
; F_filterdir
; Looks at the directory entry in v_dirwkspc, stats it, and adds it to the
; appropriate list.
F_filterdir
	ld hl, v_dirwkspc
	ld de, v_statinfo
	call STAT
	ret c			; TODO - error handling
	ld a, (v_statinfo+STAT_MODE+1)	; Get high order of MODE bits
	and S_IFDIR / 256	; compare with high order mask for isdir
	jr nz, .directory
.file
	ld hl, v_statinfo+STAT_SIZE
	ld de, c_48ksnap
	call F_cp32		; Look for a file the size of a 48k snap
	jr z, .checkfilename

	; TODO - check whether machine is 128K
	ld hl, v_statinfo+STAT_SIZE
	ld de, c_128ksnap1
	call F_cp32
	jr z, .checkfilename
	ld hl, v_statinfo+STAT_SIZE
	ld de, c_128ksnap2
	call F_cp32
	ret nz
.checkfilename
	ld hl, (v_snaptr)
	ld de, (v_snanextentry)
	call F_addentry
	ld (v_snaptr), hl
	ld (v_snanextentry), de 
	ld a, (v_numsnas)
	inc a
	ld (v_numsnas), a
	ret

.directory
	ld hl, (v_dirptr)	; current end of directory table
	ld de, (v_dirnextentry)
	call F_addentry
	ld (v_dirptr), hl
	ld (v_dirnextentry), de
	ld a, (v_numdirs)
	inc a
	ld (v_numdirs), a
	ret
c_48ksnap	defw	0xC01B,0x0000
c_128ksnap1	defw	0x001F,0x0002
c_128ksnap2	defw	0x401F,0x0002

;-----------------------------------------------------------------------
; F_addentry
; Adds an entry to a string table
F_addentry
	push hl
	push de
	ld hl, v_dirwkspc	; point at filename to copy
.strcpy
	ldi
	ld a, (hl)
	and a			; end of string?
	jr nz, .strcpy
	ld (de), a		; make sure the NULL is added
	pop bc 
	pop hl
	ld (hl), c		; put the string pointer in the table
	inc hl
	ld (hl), b
	inc hl
	ld (hl), 0		; cap the table
	inc hl
	ld (hl), 0
	dec hl
	inc de			; de = next free byte
	ret

;-----------------------------------------------------------------------
; F_cp32
; 32 bit compare between two memory locations
; HL = pointer to location 1
; DE = pointer to location 2
F_cp32
	ld b, 4			; number of iterations
.loop
	ld a, (de)
	cp (hl)
	ret nz			; no compare
	inc de
	inc hl
	djnz .loop
	ret
	
