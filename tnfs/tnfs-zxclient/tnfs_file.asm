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
; Arguments	A - File mode
;		B - File flags
;		HL - Pointer to a string containing the full path to the file
F_tnfs_open
	ld c, a			; save filemode flags
	call F_tnfs_mounted
	ret c			; no filesystem mounted
	push hl			; save filename pointer
	ld a, TNFS_OP_OPEN
	call F_tnfs_header_w	; create the header
	ld a, c			; retrieve filemode
	ld (hl), a		; insert into message
	inc hl
	ld (hl), b		; insert the flags into the message
	inc hl
	ex de, hl		; prepare for string copy
	pop hl			; retrieve filename pointer
	ld b, 255		; max 255 bytes
	call F_tnfs_strcpy
	call F_tnfs_message_w	; send the message
	ret c			; return on network error
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a
	jr z, .gethandle
	scf			; tnfs error
	ret
.gethandle
	ld a, (tnfs_recv_buffer+tnfs_msg_offset)
	ret

;--------------------------------------------------------------------------
; F_tnfs_read
; Reads from an open file descriptor.
; Arguments:	A - File descriptor
;		BC - Requested size of block to read
;		DE - Pointer to a buffer to copy the data
; Returns with carry set on error and A=code, or carry reset on success
; with BC = actual number of bytes read
F_tnfs_read
	ex af, af'		; save file descriptor
	call F_tnfs_mounted
	ret c
	push de			; save buffer pointer
	ld a, TNFS_OP_READ
	call F_tnfs_header_w
	ex af, af'		; get file descriptor back
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
	ret c				; network error, return now
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a				; check for tnfs error
	jr z, .copybuf
	scf
	ret
.copybuf
	ld bc, (tnfs_recv_buffer+tnfs_msg_offset)
	push bc
	ld hl, tnfs_recv_buffer+tnfs_msg_offset+2
	ldir
	pop bc
	ret

;--------------------------------------------------------------------------
; F_tnfs_write
; Writes to an open file descriptor.
; Arguments:		A = directory handle
; 			HL = pointer to buffer to write
;			BC = number of bytes to write
; Returns with carry set on error and A = return code. BC = bytes
; written.
; TODO: implement write limit.
F_tnfs_write
	ex af, af´		; save the fd
	call F_tnfs_mounted
	ret c
	push hl			; save buffer pointer
	ld a, TNFS_OP_WRITE
	call F_tnfs_header_w
	ex af, af'
	ld (hl), a		; insert file descriptor
	inc hl
	ld (hl), c		; insert LSB of size
	inc hl
	ld (hl), b		; insert MSB of size
	inc hl
	ex de, hl		; prepare for buffer copy
	pop hl			; source
	ldir
	call F_tnfs_message_w	; write the command and get the reply
	ret c			; network error
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a			; check for tnfs error
	jr z, .getsize
	scf			; set carry to flag error
	ret			
.getsize
	ld bc, (tnfs_recv_buffer+tnfs_msg_offset)
	ret

;------------------------------------------------------------------------
; F_tnfs_close
; Closes an open file descriptor.
; Arguments		A = the file descriptor
; Returns with carry set on error and A = return code.
F_tnfs_close
	ld b, a
	call F_tnfs_mounted
	ret c
	ld a, TNFS_OP_CLOSE
	call F_tnfs_header_w
	ld a, b
	ld (hl), a		; insert the file descriptor
	inc hl
	call F_tnfs_message_w_hl
	ret c
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a
	ret z			; no error
	scf		
	ret			; error, return with c set

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
	call F_tnfs_mounted
	ret c
	push de
	push hl
	ld a, TNFS_OP_STAT
	call F_tnfs_header_w
	pop hl			; copy the filename string to the buffer
	call F_tnfs_strcpy
	call F_tnfs_message_w
	pop de
	ret c			; network error
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a
	jr z, .copybuf
	scf			; tnfs error
	ret
.copybuf
	dec bc			; decrease BC by the size of the
	dec bc			; TNFS header + status byte
	dec bc
	dec bc
	dec bc
	ld hl, tnfs_recv_buffer+tnfs_msg_offset
	ldir			; de is already the dest, bc is size
	ret

