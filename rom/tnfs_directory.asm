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
	call F_fetchpage		; get our sysvars at 0x1000
	ret c

	ld (v_curmountpt), a		; save the mount point in use

	ld a, TNFS_OP_OPENDIR
	call F_tnfs_pathcmd		; send command, get reply
	jp c, F_leave			; return on network error
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a				; return code is zero?
	jr z, .gethandle
	scf				; return with tnfs error
	jp F_leave
.gethandle
	ld a, (v_pgb)			; allocate a
	call ALLOCDIRHND		; directory handle.
	jr c, .cleanupandexit
	ld h, HANDLESPACE / 256		; create our private sysvar addr
	ld a, (tnfs_recv_buffer+tnfs_msg_offset)
	ld (hl), a			; save TNFS handle
	inc h				; point at metadata storage
	ld a, (v_curmountpt)		; and save the mount point
	ld (hl), a
	ld a, l				; move dirhandle into A
	jp F_leave			; return the directory handle
.cleanupandexit
	push af
	ld a, (tnfs_recv_buffer+tnfs_msg_offset)
	ld b, a
	ld a, TNFS_OP_CLOSEDIR		; close the TNFS handle
	call F_tnfs_header_w
	ld (hl), b			; message is just the dirhandle
	inc hl
	call F_tnfs_message_w_hl
	pop af
	jp F_leave
	
;=========================================================================
; F_tnfs_readdir
; Reads the next directory entry.
; Arguments:	A = directory handle
; 		DE = pointer to a buffer for the result
; On success, returns with carry cleared, and the buffer at DE filled
; with the result. On error, sets the carry flag and A to the error number
F_tnfs_readdir
	call F_fetchpage
	ret c

	ld l, a				; get the TNFS handle address
	ld h, HANDLESPACE / 256
	ld b, (hl)			; get the TNFS handle
	inc h				; point at handle metadata
	ld a, (hl)			; get the mountpoint
	ld (v_curmountpt), a
	push de
	ld a, TNFS_OP_READDIR
	call F_tnfs_header_w		; create the header
	ld (hl), b			; set the dirhandle
	inc hl
	call F_tnfs_message_w_hl	; send the message
	pop de				; get buffer pointer back
	jp c, F_leave			; but return on network error
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a				; if rc is zero then copy the
	jr z, .copybuf			; buffer to DE
	scf
	jp F_leave
.copybuf
	ld hl, tnfs_recv_buffer+tnfs_msg_offset
	ld b, 255			; max filename length
	call F_tnfs_strcpy		; copy then exit
	jp F_leave

;===========================================================================
; F_tnfs_closedir
; Closes the directory handle.
; Arguments:	A = directory handle
; On success, returns with carry cleared. On error, returns with carry
; set and A as the error.
F_tnfs_closedir
	call F_fetchpage
	ret c

	call FREEDIRHND			; The dirhandle should always be
					; cleared, even if there's an error.
	ld l, a				; get the handle address
	ld h, HANDLESPACE / 256
	ld b, (hl)			; and fetch the TNFS handle
	inc h
	ld a, (hl)			; get the mount point
	ld (v_curmountpt), a
	ld a, TNFS_OP_CLOSEDIR
	call F_tnfs_header_w
	ld (hl), b			; message is just the dirhandle
	inc hl
	call F_tnfs_message_w_hl
	jp c, F_leave			; return now on network error
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a
	jp z, F_leave			; no error
	scf				
	jp F_leave			; return error number	

;===========================================================================
; F_tnfs_chdir
; Chdir is not part of the protocol, but it's part of the client. It works
; by statting the path supplied, and if it's a directory, storing this
; path (which gets prepended to subsequent file operations).
; Parameters	HL = path to chdir to
; Returns with carry set on error and A=error code
F_tnfs_chdir
	call F_fetchpage
	ret c

	push hl
	ld (v_curmountpt), a	; set the mount point being worked upon
	ld a, TNFS_OP_STAT	
	call F_tnfs_pathcmd	; stat the path
	jr c, .error		; stat returned an error
	ld hl, tnfs_recv_buffer+tnfs_msg_offset+1 ; MSB of stat filemode bitfield
	ld a, S_IFDIR / 256	; MSB of S_IFDIR bitfield
	and (hl)		; AND it all together...
	jr z, .notadir		; ...if zero, it wasn't a directory.
	pop hl

	ld a, (v_curmountpt)
	add v_cwd0 / 256	; add the MSB of the CWD storage
	ld d, a			; DE = pointer to this mount point's CWD
	ld e, 0			; copy the directory we just got
	call F_tnfs_abspath	; as an absolute path.
	jp F_leave
.notadir
	ld a, ENOTDIR
	scf
.error	
	pop hl
	jp F_leave

;-------------------------------------------------------------------------
; F_tnfs_mkdir
; Create a directory on the server.
; Parameters		HL = pointer to directory name
; Returns with carry set on error and A=error code.
F_tnfs_mkdir
	ld b, TNFS_OP_MKDIR
	jp F_tnfs_simplepathcmd

;------------------------------------------------------------------------
; F_tnfs_rmdir
; Removes a directory on the server.
; Parameters		HL = pointer to the directory
; Returns with carry set on error and A=error code.
F_tnfs_rmdir
	ld b, TNFS_OP_RMDIR
	jp F_tnfs_simplepathcmd

;------------------------------------------------------------------------
; F_tnfs_getcwd
; Gets the current working directory
; Parameters		DE = pointer to memory to copy result
F_tnfs_getcwd
	call F_fetchpage
	ret c

	add v_cwd0 / 256	; add the MSB of the CWD storage
	ld h, a			; 
	ld l, 0			; HL = pointer to CWD
.cploop
	ld a, (hl)
	ld (de), a
	and a			; null terminator?
	jp z, F_leave
	inc hl
	inc de
	jr .cploop

