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

; The TNFS mount and umount functions.

;-----------------------------------------------------------------------
; F_tnfs_mount: Mount a remote filesystem.
; Parameters: IX - pointer to 10 byte VFS mount structure:
;		byte 0,1 - Pointer to null terminated protocol
;		byte 2,3 - pointer to null terminated hostname
; 		byte 4,5 - pointer to null terminated mount source
;		byte 6,7 - pointer to null terminated user id
;		byte 8,9 - pointer to null terminated passwd
;		A - Mount point - 0 to 3
;
; On success, returns the session number in HL. On error, returns the
; error number in HL and sets the carry flag.
F_tnfs_mount
	call F_fetchpage	; get our private RAM page
	ret c			; which was allocated on startup.
	ld (v_curmountpt), a	; save the mount point for later

	; first check the requested protocol
	ld e, (ix+0)
	ld d, (ix+1)
	ld hl, STR_tnfstype
	ld bc, 5
.cploop
        ld a, (de)              ; Effectively this is a "strncmp" to check
        cpi                     ; that the passed protocol is "dev" plus
        jp nz, .notourfs        ; a null.
        inc de
        jp pe, .cploop

	; It is now certain that the requested FS is TNFS.
	ld de, buf_tnfs_wkspc	; Look up the host
	ld l, (ix+2)
	ld h, (ix+3)
	call GETHOSTBYNAME
	jp c, F_leave		; exit if host not found

	; create the socket that will be used for tnfs communications
	ld hl, buf_tnfs_wkspc	; IP address is here
	call F_tnfs_opensock
	jp c, F_leave		; unable to open socket

	; We've successfully looked up a host so create the datagram
	; that will be sent.
	ld hl, buf_tnfs_wkspc+4
	ld de, 0		; no session id yet
	xor a			; cmd is 0x00
	call F_tnfs_header	; create the header, HL now at the next byte
	ld (hl), 0		; version 1.0, little endian
	inc hl
	ld (hl), 1		; msb of protocol version
	inc hl
	ex de, hl		; make destination = DE
	ld l, (ix+4)		; remote mount point
	ld h, (ix+5)
	ld b, 255		; maximum size of mount point
	call F_tnfs_strcpy
	ld l, (ix+6)		; user id
	ld h, (ix+7)
	ld b, 64
	call F_tnfs_strcpy
	ld l, (ix+8)		; passwd
	ld h, (ix+9)
	ld b, 64
	call F_tnfs_strcpy

	; the packet is assembled - send it.
	ex de, hl		; get current dest pointer into hl
	ld de, buf_tnfs_wkspc+4	; calculate the size
	sbc hl, de		; hl now contains the size
	ld b, h			; move into bc
	ld c, l
	call F_tnfs_message	; send msg/get response
	jr c, .mounterr		; clean up on error

	; decode the result - first, check for error conditions
	ld a, (tnfs_recv_buffer + tnfs_err_offset)
	and a			; zero = no error
	jr nz, .mounterr	; clean up on error
	ld hl, (tnfs_recv_buffer + tnfs_sid_offset)
	ld (v_tnfs_sid), hl	; save the session identifier
	ld a, '/'		; set the CWD to /
	ld (v_cwd), a
	xor a
	ld (v_cwd+1), a

	; set up mount point in VFS mount table
	ld a, (v_curmountpt)	; get the mount point
	add VFSVECBASE % 256	; find it in the sysvars
	ld l, a
	ld h, 0x3F		; point HL at the address in sysvars
	ld a, (v_pgb)		; Fetch our ROM number
	ld (hl), a		; and store it in the mount point table
	or 1			; reset Z and C flags - mounted OK.
	jp F_leave

.mounterr
	push af			; save the error code
	ld a, (v_tnfssock)	; close the socket
	call CLOSE
	pop af
	scf			; set the carry flag
	jp F_leave
.notourfs
	xor a			; signal 'not our filesystem' by setting
	jp F_leave		; the zero flag.
STR_tnfstype defb "tnfs",0

;-------------------------------------------------------------------------
; F_tnfs_umount
; Unmounts the TNFS filesystem and closes the socket.
F_tnfs_umount
	ld a, TNFS_OP_UMOUNT
	call F_tnfs_header_w		; create the header
	call F_tnfs_message_w_hl	; not much to do here at all
	ret c				; communications error
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a				; no error?
	jr nz, .error
	ld a, (v_tnfssock)		; close the socket
	call CLOSE
	xor a
	ld (v_tnfssock), a		; clear socket number
	ld (v_tnfs_sid), a		; clear session id
	ld (v_tnfs_sid+1), a
	ret
.error
	scf				; flag the error condition
	ret
