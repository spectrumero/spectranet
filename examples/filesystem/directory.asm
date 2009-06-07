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

; Directory functions.

;-----------------------------------------------------------------------------
; F_opendir
; Open a directory. HL points to the directory to open.
; In this example, there is only one that can be opened; that's /. Anything
; else returns an error.
F_opendir
	ld a, (hl)
	cp '/'				; / followed by a
	jr nz, .notfound
	inc hl
	ld a, (hl)
	and a				; null terminator
	jr nz, .notfound
	
	ld a, (v_pgb)			; our page number
	call ALLOCDIRHND		; get a free directory handle
	ret c				; failed to find one
	push hl				; save dir handle
	ld a, l				; calculate the offset in our
	sub DIRVECBASE % 256		; sysvars
	ld h, 0x10
	ld l, a				; hl = dir pointer address
	call F_fetchpage		; fetch our page of static RAM
	jr c, .cleanupfail
	ld (hl), 0			; set the dirent index
	call F_restorepage		; restore page A
	pop hl
	ld a, l				; move dirhandle into A
	ret
.cleanupfail
	pop hl
	ld a, l
	call FREEDIRHND
	ld a, 254			; TODO proper return code
	scf
	ret
.notfound
	ld a, 0x06			; ENOENT
	scf
	ret

;-----------------------------------------------------------------------------
; F_readdir
; Reads a directory entry.
; Parameters:	A = directory handle
;		DE = buffer to fill with directory entry
F_readdir
	call F_fetchpage		; get our sysvars
	ret c				; and exit on error
	sub DIRVECBASE % 256		; point A at LSB of our dir pointer
	ld l, a
	ld h, 0x10			; hl = addr of dir pointer
	ld (v_hlsave), hl		; save it for later
	ld a, (hl)			; fetch the pointer
	cp NUMFILES			; off the end?
	jr z, .eodir			; End of directory.
	ld hl, FILETABLE		; point hl at the file table
	rlca				; a = a * 2
	add a, l
	ld l, a				; hl points at file table entry
	push de
	ld e, (hl)			; get pointer to string
	inc hl
	ld d, (hl)
	ex hl, de
	pop de				; get original destination
.cploop
	ld a, (hl)
	ld (de), a
	and a				; end of string?
	jr z, .finish
	inc hl
	inc de
	jr .cploop
.finish
	ld hl, (v_hlsave)
	inc (hl)			; point at the next file
	call F_restorepage		; restore paging area A
	ret
.eodir
	ld a, 0x21			; EOF: TODO: errno file
	scf
	ret

;-----------------------------------------------------------------------------
; F_closedir
; Closes a directory.
; Parameters:	A = directory handle
F_closedir
	; There is not a lot our example filesystem has to actually do -
	; only release the directory handle. Your FS probably has to do
	; more, but this is the minimum that must be done.
	jp FREEDIRHND

