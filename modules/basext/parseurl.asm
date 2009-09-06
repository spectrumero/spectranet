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

; Parse URLs for mounting filesystems.

;--------------------------------------------------------------------------
; F_parseurl: Break up incoming string into null-terminated strings.
; Parameters: IX - points to memory where the mount structure will be held
;             HL - pointer to string
F_parseurl
	call F_findfstype	; if there's an fs type token
	jr nc, .continue	; then continue
	push hl			; otherwise
	ld hl, STR_defaulttype	; make a copy of the default fs
	ld de, v_workspace	; type token in memory that's not 
	ld bc, deftypelen	; going to get paged out.
	ldir
	pop hl
	ld (ix+0), v_workspace%256
	ld (ix+1), v_workspace/256
	jr .finduser
.continue
	ld (ix+0), e		; set the host arg
	ld (ix+1), d
.finduser
	call F_finduser		; User specified in the string?
	jr c, .findhost
	ld (ix+6), e
	ld (ix+7), d
	call F_findpasswd	; Is there a password?
	jr c, .findhost
	ld (ix+8), e
	ld (ix+9), d
.findhost
	call F_findhost		; There *must* be a host.
	ret c
	ld (ix+2), e
	ld (ix+3), d
.path				; The remainder is the path - just
	ld (ix+4), l		; set the next argument to the current
	ld (ix+5), h		; value of HL and return.
	ret

;--------------------------------------------------------------------------
; Find the filesystem type token if there is one. If there is, return
; with carry reset, DE pointing at the start address, and HL pointing
; at the start of the  next bit of the string to parse.
; If not return with carry set and HL set to its original value.
F_findfstype
	push hl
.loop
	ld a, (hl)
	and a
	jr z, J_notfound
	cp ':'			; look for colon token followed by...
	inc hl
	jr nz, .loop		; Not found, next...
	ld a, (hl)		; See if we have an "/"
	cp '/'
	jr z, .found
	inc hl
	jr .loop		; no, continue
.found
	dec hl			; convert tokens to nulls
	xor a
	ld (hl), a		; delete the colon
	inc hl
	ld (hl), a		; delete the slash
	inc hl
	ld (hl), a		; delete the second slash
	inc hl
	pop de			; return start address in DE
	ret
J_notfound
	pop hl			; restore HL
	scf			; indicate "no fstype found"
	ret

;-------------------------------------------------------------------------
; See if there's a user. The hostname part of the string can be
; user@host, user:pw@host or just host.
F_finduser
	push hl
.loop
	ld a, (hl)
	and a			; end of string
	jr z, J_notfound
	cp '/'			; we've hit the first bit of the path...
	jr z, J_notfound
	cp ':'
	jr z, J_found		; password separator found
	cp '@'			; host separator?
	jr z, J_found
	inc hl
	jr .loop		; no - check the next char
J_found
	pop de			; DE = start of string
	ld a, d			; make sure the arg is at least 1 char
	cp h
	jr nz, .done
	ld a, e
	cp l
	jr nz, .done
	ex de, hl		; oops - reset HL to the start of the string
	scf			; indicate not found
	ret
.done
	xor a
	ld (hl), a
	inc hl
	ret

;-------------------------------------------------------------------------
; See if there's a password.
F_findpasswd
	push hl
.loop
	ld a, (hl)
	and a
	jr z, J_notfound
	cp '/'
	jr z, J_notfound
	cp '@'
	jr z, J_found
	inc hl
	jr .loop

;------------------------------------------------------------------------
; Find the hostname
F_findhost
	push hl
.loop
	ld a, (hl)
	and a
	jr z, J_notfound
	cp '/'
	jr z, J_found
	inc hl
	jr .loop

STR_defaulttype
	defb "tnfs",0
deftypelen equ 5
