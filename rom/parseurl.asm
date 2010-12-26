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
.include	"sysvars.inc"
.text
; Parse URLs for mounting filesystems.

;--------------------------------------------------------------------------
; F_parseurl: Break up incoming string into null-terminated strings.
; Parameters: IX - points to memory where the mount structure will be held
;             DE - pointer to string
.globl F_parseurl
F_parseurl:
	ex de, hl		; move passed parameter into HL
	call F_findfstype	; if there's an fs type token
	jr nc, .continue1	; then continue
	push hl			; otherwise
	ld hl, STR_defaulttype	; make a copy of the default fs
	ld de, v_workspace	; type token in memory that's not 
	ld bc, deftypelen	; going to get paged out.
	ldir
	pop hl
	ld (ix+0), v_workspace%256
	ld (ix+1), v_workspace/256
	jr .finduser1
.continue1:
	ld (ix+0), e		; set the host arg
	ld (ix+1), d
.finduser1:
	call F_finduser		; User specified in the string?
	jr c, .findhost1
	ld (ix+6), e
	ld (ix+7), d
	call F_findpasswd	; Is there a password?
	jr c, .findhost1
	ld (ix+8), e
	ld (ix+9), d
.findhost1:
	call F_findhost		; There *must* be a host.
	ret c
	ld (ix+2), e
	ld (ix+3), d
.path1:				; The remainder is the path - just
	ld (ix+4), l		; set the next argument to the current
	ld (ix+5), h		; value of HL and return.
	ret

;--------------------------------------------------------------------------
; Find the filesystem type token if there is one. If there is, return
; with carry reset, DE pointing at the start address, and HL pointing
; at the start of the  next bit of the string to parse.
; If not return with carry set and HL set to its original value.
.globl F_findfstype
F_findfstype:
	push hl
.loop2:
	ld a, (hl)
	and a
	jr z, J_notfound
	cp ':'			; look for colon token followed by...
	inc hl
	jr nz, .loop2		; Not found, next...
	ld a, (hl)		; See if we have an "/"
	cp '/'
	jr z, .found2
	inc hl
	jr .loop2		; no, continue
.found2:
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
J_notfound:
	pop hl			; restore HL
	scf			; indicate "no fstype found"
	ret

;-------------------------------------------------------------------------
; See if there's a user. The hostname part of the string can be
; user@host, user:pw@host or just host.
.globl F_finduser
F_finduser:
	push hl
.loop3:
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
	jr .loop3		; no - check the next char
J_found:
	pop de			; DE = start of string
	ld a, d			; make sure the arg is at least 1 char
	cp h
	jr nz, .done3
	ld a, e
	cp l
	jr nz, .done3
	ex de, hl		; oops - reset HL to the start of the string
	scf			; indicate not found
	ret
.done3:
	xor a
	ld (hl), a
	inc hl
	ret

;-------------------------------------------------------------------------
; See if there's a password.
.globl F_findpasswd
F_findpasswd:
	push hl
.loop4:
	ld a, (hl)
	and a
	jr z, J_notfound
	cp '/'
	jr z, J_notfound
	cp '@'
	jr z, J_found
	inc hl
	jr .loop4

;------------------------------------------------------------------------
; Find the hostname
.globl F_findhost
F_findhost:
	push hl
.loop5:
	ld a, (hl)
	and a
	jr z, .addpath5
	cp '/'
	jr z, J_found
	inc hl
	jr .loop5
	
	; if we hit the end of the string while parsing the hostname
	; we can assume the user wants to mount the root.
.addpath5:
	inc hl
	ld (hl), '/'
	inc hl
	ld (hl), 0
	pop de
	ret
.data
STR_defaulttype:
	defb "tnfs",0
deftypelen: equ 5
