;The MIT License
;
;Copyright (c) 2010 Dylan Smith
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

; The FTP filesystem mount and umount functions.

;-----------------------------------------------------------------------
; F_ftpfs_mount: Mount a remote filesystem.
; Parameters: IX - pointer to 10 byte VFS mount structure:
;               byte 0,1 - Pointer to null terminated protocol
;               byte 2,3 - pointer to null terminated hostname
;               byte 4,5 - pointer to null terminated mount source
;               byte 6,7 - pointer to null terminated user id
;               byte 8,9 - pointer to null terminated passwd
;               A - Mount point - 0 to 3
;
; On success, returns the session number in HL. On error, returns the
; error number in HL and sets the carry flag.
F_ftpfs_mount
	call F_fetchpage	; get our private RAM
	ret c			; or die if we don't have it
	ld (v_curmountpt), a	; save the current mount point

        ; first check the requested protocol
        ld e, (ix+0)
        ld d, (ix+1)
        ld hl, STR_ftptype
        ld bc, 5
.cploop
        ld a, (de)              ; Effectively this is a "strncmp" to check
        cpi                     ; that the passed protocol is "ftp" plus
        jp nz, .notourfs        ; a null.
        inc de
        jp pe, .cploop

	ld a, (v_ftp_status)	; make sure we're not already connected
	and a
	jp nz, .already		; already mounted - return an error

	; look up the requested host
	ld de, v_ftp_servaddr	; Buffer to return address
	ld l, (ix+2)		; pointer to hostname
	ld h, (ix+3)
	call GETHOSTBYNAME
	jp c, F_leave		; host not found if carry is set

	; copy username and password to sysvars
	ld l, (ix+6)		; username pointer
	ld h, (ix+7)
	ld a, (hl)		; is it empty?
	and a
	jr nz, .cpauth
	ld hl, STR_anonymous	; if empty use anonymous user id
.cpauth
	ld de, v_ftp_user
	ld b, 32		; max length
	call F_ftp_strcpy

	ld l, (ix+8)		; password pointer
	ld h, (ix+9)
	ld a, (hl)
	and a
	jr nz, .cppasswd
	ld hl, STR_defpasswd
.cppasswd
	ld de, v_ftp_passwd
	ld b, 32		
	call F_ftp_strcpy

	; if a mount source is set, set it as the CWD
	ld l, (ix+4)
	ld h, (ix+5)
	ld a, (hl)
	and a
	jr nz, .cpsrc
	ld hl, STR_root
.cpsrc
	ld de, v_cwd
	ld b, 255
	call F_ftp_strcpy

	; Try to connect to complete the mount operation.
	call F_ftp_connect

	jp F_leave		; page out and return

;-----
; Constants for mount function
STR_ftptype
STR_anonymous	defb	"ftp",0	; both filesystem type and anon login...
STR_defpasswd	defb	"winston@apectranet",0
STR_root	defb	"/",0

