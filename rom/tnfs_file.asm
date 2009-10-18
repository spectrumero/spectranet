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

; TNFS file operations - open, read, write, close

;--------------------------------------------------------------------------
; F_tnfs_open
; Opens a file on the remote server.
; Arguments	A  - mount point	
;		D  - File flags (POSIX)
;		E  - File mode (POSIX)
;		HL - Pointer to a string containing the full path to the file
F_tnfs_open
	call F_fetchpage
	ret c
	ld (v_curmountpt), a

	push hl			; save filename pointer
	push de			; and flags
	ld a, TNFS_OP_OPEN
	call F_tnfs_header_w	; create the header
	pop de
	ld (hl), e		; insert file mode into message
	inc hl
	ld (hl), d		; insert the flags into the message
	inc hl
	ex de, hl		; prepare for string copy
	pop hl			; retrieve filename pointer
	call F_tnfs_abspath	; create absolute path to file
	call F_tnfs_message_w	; send the message
	jp c, F_leave		; return on network error
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a
	jr z, .gethandle
	scf			; tnfs error
	jp F_leave
.gethandle
	ld a, (v_pgb)		; Allocate a new file descriptor
	call ALLOCFD		; for this TNFS handle
	jr c, .nofds
	ld a, 0x20		; indicate "not a socket"
	ld (hl), a		; and update the FD table
	ld h, HANDLESPACE / 256	; now save the TNFS handle
	ld a, (tnfs_recv_buffer+tnfs_msg_offset)
	ld (hl), a		; in our sysvars area.
	inc h			; point at handle metadata
	ld a, (v_curmountpt)
	ld (hl), a
	ld a, l			; FD is in L, needs to be returned in A
	jp F_leave
.nofds
	ld a, TNFS_OP_CLOSE	; cleanup recovery from finding no free
	call F_tnfs_header_w	; file descriptors - close TNFS handle
	ld a, (tnfs_recv_buffer+tnfs_msg_offset)
	ld (hl), a		; insert the tnfs handle
	inc hl
	call F_tnfs_message_w_hl
	ld a, 0xFF		; TODO - proper return code
	scf
	jp F_leave

;--------------------------------------------------------------------------
; F_tnfs_read
; Reads from an open file descriptor.
; Arguments:	A - File descriptor
;		BC - Requested size of block to read
;		DE - Pointer to a buffer to copy the data
; Returns with carry set on error and A=code, or carry reset on success
; with BC = actual number of bytes read
F_tnfs_read
	call F_fetchpage
	ret c

	ex af, af'		; save FD
	ld a, b			; cap read size at 512 bytes
	cp 0x02
	jr c, .continue		; less than 512 bytes if < 0x02
	jr nz, .sizecap		; if msb > 0x02 cap the size
	ld a, c
	and a			; compare with zero
	jr z, .continue		; less than 512 bytes if zero
.sizecap
	ld bc, 512		; cap at 512 bytes
.continue
	push de			; save buffer pointer
	ld a, TNFS_OP_READ
	call F_tnfs_header_w
	ex af, af'		; get the FD back
	ld e, a			; get the address of the TNFS handle
	ld d, HMETASPACE / 256	; get the mountpoint number
	ld a, (de)		; and store it
	ld (v_curmountpt), a	; in the curmountpt var
	dec d			; point at the fd storage
	ld a, (de)		; and fetch the fd
	ld (hl), a		; add it to the request
	inc hl
	ld (hl), c		; add the length to the request
	inc hl
	ld (hl), b
	inc hl

	; TODO: Not yet optimised. This means that two buffer copies
	; get done, one from the ethernet buffer when reading the datagram
	; then one from our workspace into the supplied buffer pointer.
	; This should be done in two calls to recvfrom to optimise, one
	; to get the header data, and one to get the proper data directly
	; into the supplied buffer.
	call F_tnfs_message_w_hl	; send it, and get the reply
	pop de
	jp c, F_leave			; network error, return now
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a				; check for tnfs error
	jr z, .copybuf
	scf
	jp F_leave
.copybuf
	ld bc, (tnfs_recv_buffer+tnfs_msg_offset)
	push bc
	ld hl, tnfs_recv_buffer+tnfs_msg_offset+2
	ldir
	pop bc
	jp F_leave

;--------------------------------------------------------------------------
; F_tnfs_write
; Writes to an open file descriptor.
; Arguments:		A = directory handle
; 			HL = pointer to buffer to write
;			BC = number of bytes to write
; Returns with carry set on error and A = return code. BC = bytes
; written.
F_tnfs_write
	call F_fetchpage
	ret c

	ex af, af'
	ld a, b			; cap write size at 512 bytes
	cp 0x01
	jr c, .continue		; less than 512 bytes if < 0x02
	jr nz, .sizecap		; if msb > 0x02 cap the size
	ld a, c
	and a			; compare with zero
	jr z, .continue		; less than 512 bytes if zero
.sizecap
	ld bc, 256		; cap at 512 bytes
.continue
	push hl			; save buffer pointer
	ld a, TNFS_OP_WRITE
	call F_tnfs_header_w
	ex af, af'
	ld e, a			; get the TNFS handle for the file descriptor
	ld d, HMETASPACE / 256	; get the FS number
	ld a, (de)
	ld (v_curmountpt), a
	dec d			; point at the handle storage...
	ld a, (de)		; and get it.
	ld (hl), a		; insert the TNFS handle
	inc hl
	ld (hl), c		; insert LSB of size
	inc hl
	ld (hl), b		; insert MSB of size
	inc hl
	ex de, hl		; prepare for buffer copy
	pop hl			; source
	ldir
	call F_tnfs_message_w	; write the command and get the reply
	jp c, F_leave		; network error
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a			; check for tnfs error
	jr z, .getsize
	scf			; set carry to flag error
	ret			
.getsize
	ld bc, (tnfs_recv_buffer+tnfs_msg_offset)
	jp F_leave

;------------------------------------------------------------------------
; F_tnfs_close
; Closes an open file descriptor.
; Arguments		A = the file descriptor
; Returns with carry set on error and A = return code.
F_tnfs_close
	call F_fetchpage
	ret c

	call FREEFD		; always free the FD even if there's an error

	ld b, a
	ld a, TNFS_OP_CLOSE
	call F_tnfs_header_w
	ld e, b			; make address of TNFS handle
	ld d, HMETASPACE / 256
	ld a, (de)		; get the filesystem mount point
	ld (v_curmountpt), a	
	dec d			; point at the handle storage
	ld a, (de)		; get the TNFS handle
	ld (hl), a		; insert it into the message
	inc hl
	call F_tnfs_message_w_hl
	jp c, F_leave		; protocol error
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a
	jp z, F_leave		; no error
	scf		
	jp F_leave		; error, return with c set

;------------------------------------------------------------------------
; F_tnfs_stat
; Stats a file (gets information on it).
; Arguments		HL = pointer to a null-terminated string - the filename
; 			DE = pointer to a buffer for the result
; The result is exactly the structure defined in tnfs-protocol.txt
; Returns with carry set on error and A = return code.
; An optimization would be to copy the reply directly from the ethernet
; buffer and save a buffer copy.
F_tnfs_stat
	call F_fetchpage
	ret c
	ld (v_curmountpt), a	; save the mount point

	push de
	ld a, TNFS_OP_STAT
	call F_tnfs_pathcmd	; send the command + path
	pop de
	jp c, F_leave		; network error
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a
	jr z, .copybuf
	scf			; tnfs error
	jp F_leave
.copybuf
	dec bc			; decrease BC by the size of the
	dec bc			; TNFS header + status byte
	dec bc
	dec bc
	dec bc
	ld hl, tnfs_recv_buffer+tnfs_msg_offset
	ldir			; de is already the dest, bc is size
	jp F_leave

;---------------------------------------------------------------------------
; F_tnfs_lseek
; Seek to a position in a file.
; Parameters: 	A = file descriptor
;		C = operation 0x00 = SEEK_SET, 0x01 = SEEK_CUR, 0x02 = SEEK_END
;		DEHL = 32 bit signed seek position
; Returns with carry set and A=error code on error.
F_tnfs_lseek
	call F_fetchpage
	ret c

	ex af, af'
	ld a, TNFS_OP_LSEEK
	push hl
	push de
	call F_tnfs_header_w	; Create the header in workspace
	ex af, af'
	ld e, a			; get the TNFS handle
	ld d, HMETASPACE / 256	; find the filesystem number
	ld a, (de)
	ld (v_curmountpt), a
	dec d			; find the tnfs handle
	ld a, (de)
	ld (hl), a		; Set the TNFS handle
	pop de			
	pop hl
	ld a, c			; Operation type
	ld (buf_tnfs_wkspc+5), a
	ld (buf_tnfs_wkspc+6), hl ; 32 bit little endian seek position
	ld (buf_tnfs_wkspc+8), de ; is in DEHL
	ld de, buf_tnfs_wkspc	; send message from workspace
	ld bc, 10		; that is 10 bytes long
	call F_tnfs_message
	jp F_tnfs_simpleexit

;---------------------------------------------------------------------------
; F_tnfs_unlink
; Unlink (delete) a file.
; Parameters		HL = pointer to filename
F_tnfs_unlink
	ld b, TNFS_OP_UNLINK
	jp F_tnfs_simplepathcmd

;---------------------------------------------------------------------------
; F_tnfs_chmod
; Changes file mode.
; Parameters		HL = pointer to filename
;			DE = 16 bit mode flags
; On error returns with carry set and A=error
F_tnfs_chmod
	call F_fetchpage
	ret c

	ld (v_curmountpt), a	; filesystem in use
	ld a, TNFS_OP_CHMOD
	push hl
	push de
	call F_tnfs_header_w	; Create the header in workspace
	pop de
	ld (hl), e		; add the requested file mode flags
	inc hl
	ld (hl), d
	inc hl
	ex de, hl		; buffer pointer in DE for strcpy op
	pop hl			; get filename parameter back
	call F_tnfs_abspath	; copy filename as absolute path
	call F_tnfs_message_w	; send message and get reply
	jp F_tnfs_simpleexit	; and handle exit
