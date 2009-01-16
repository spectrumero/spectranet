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

; TNFS directory functions - opendir, readdir. closedir

;=========================================================================
; F_tnfs_opendir
; Opens a directory.
; Arguments:	HL = pointer to null-terminated string containing the path
; On success, returns the directory handle in A.
; On error, sets the carry flag and sets A to the error number.
F_tnfs_opendir
	call F_tnfs_mounted		; Check for valid mount
	ret c
	push hl
	ld a, TNFS_OP_OPENDIR
	call F_tnfs_header_w		; header created at buf_workspace
	ex de, hl
	pop hl
	ld b, 255			; maximum path length
	call F_tnfs_strcpy
	call F_tnfs_message_w		; send message starting at workspace
	ret c				; return on network error
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a				; return code is zero?
	jr z, .gethandle
	scf				; return with tnfs error
	ret
.gethandle
	ld a, (tnfs_recv_buffer+tnfs_msg_offset)
	ret				; return the handle

;=========================================================================
; F_tnfs_readdir
; Reads the next directory entry.
; Arguments:	A = directory handle
; 		DE = pointer to a buffer for the result
; On success, returns with carry cleared, and the buffer at DE filled
; with the result. On error, sets the carry flag and A to the error number
F_tnfs_readdir
	ld b, a				; save the dirhandle
	call F_tnfs_mounted
	ret c
	push de
	ld a, TNFS_OP_READDIR
	call F_tnfs_header_w		; create the header
	ld (hl), b			; set the dirhandle
	inc hl
	call F_tnfs_message_w_hl	; send the message
	pop de				; get buffer pointer back
	ret c				; but return on network error
	ld a, (tnfs_recv_buf+tnfs_err_offset)
	and a				; if rc is zero then copy the
	jr z, .copybuf			; buffer to DE
	scf
	ret
.copybuf
	ld hl, tnfs_recv_buf+tnfs_msg_offset
	ld b, 255			; max filename length
	jp F_tnfs_strcpy		; exit via strcpy

;===========================================================================
; F_tnfs_closedir
; Closes the directory handle.
; Arguments:	A = directory handle
; On success, returns with carry cleared. On error, returns with carry
; set and A as the error.
F_tnfs_closedir
	ld b, a				; save the dirhandle
	call F_tnfs_mounted
	ret c
	ld a, TNFS_OP_CLOSEDIR
	call F_tnfs_header_w
	ld (hl), b			; message is just the dirhandle
	inc hl
	call F_tnfs_message_w_hl
	ret c				; return now on network error
	ld a, (tnfs_recv_buf+tnfs_err_offset)
	and a
	ret z				; no error
	scf				
	ret				; return error number	

