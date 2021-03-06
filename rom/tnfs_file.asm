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
.include	"spectranet.inc"
.include	"sysvars.inc"
.include	"tnfs_sysvars.inc"
.include	"tnfs_defs.inc"
.text
; TNFS file operations - open, read, write, close
;	include "regdump.asm0"
;--------------------------------------------------------------------------
; F_tnfs_open
; Opens a file on the remote server.
; Arguments	A  - mount point	
;		DE  - File flags (POSIX)
;		BC  - File mode (POSIX)
;		HL - Pointer to a string containing the full path to the file
.globl F_tnfs_open
F_tnfs_open:
	call F_fetchpage
	ret c
	ld (v_curmountpt), a

	push hl			; save filename pointer
	push de			; and flags
	push bc			; and mode
	ld a, TNFS_OP_OPEN
	call F_tnfs_header_w	; create the header
	pop bc
	pop de
	ld (hl), e		; 
	inc hl
	ld (hl), d		; insert the flags into the message
	inc hl
	ld (hl), c		; 
	inc hl
	ld (hl), b		; insert the mode into the message
	inc hl
	ex de, hl		; prepare for string copy
	pop hl			; retrieve filename pointer
	call F_tnfs_abspath	; create absolute path to file
	call F_tnfs_message_w	; send the message
	jp c, F_leave		; return on network error
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a
	jr z, .gethandle1
	scf			; tnfs error
	jp F_leave
.gethandle1:
	ld a, (v_pgb)		; Allocate a new file descriptor
	ld c, ALLOCFD		
	call RESALLOC		; for this TNFS handle
	jr c, .nofds1
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
.nofds1:
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
.globl F_tnfs_read
F_tnfs_read:
	call F_fetchpage
	ret c
	ld (v_curfd), a			; store the FD
	call F_tnfs_setmountpt_fd	; set the current mount point
	xor a
	ld (v_bytesread), a		; reset bytesread counter
	ld (v_bytesread+1), a

	ld h, b				; store bytes requested in HL
	ld l, c
.readloop2:
	ld a, (v_curfd)
	push hl
	call F_tnfs_read_blk		; note: returns with our memory
	ex af, af'			; preserve any flags
	ld hl, (v_bytesread)		; update read counter
	add hl, bc
	ld (v_bytesread), hl
	ex af, af'
	pop hl
	jr nz, .readdone2		; fewer bytes read than requested
	jr c, .readdone2			; or an error occurred
	sbc hl, bc			; calculate bytes remaining
	ld b, h				; and set BC
	ld c, l
	jr nz, .readloop2		; still more to read
.readdone2:
	ld bc, (v_bytesread)		; return bytes read in BC
	jp F_leave			; read complete
	
.globl F_tnfs_read_blk
F_tnfs_read_blk:
	ld (v_read_destination), de	; save destination
	ex af, af'		; save FD
	ld a, b			; cap read size at 512 bytes
	cp 0x02
	jr c, .continue3		; less than 512 bytes if < 0x02
.sizecap3:
	ld bc, 512		; cap at 512 bytes
.continue3:
	push bc			; save requested bytes
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

	; v_read_destination contains address of buffer.
	call F_tnfs_message_w_hl	; send it, and get the reply
	pop hl			; get requested bytes back
	ret c			; return immediately on message error
	ld a, h			; compare high order of requested 
	cp b			; versus received...
	ret nz			; not equal.
	ld a, l			; do the same with the low order.
	cp c
	ret			; note: for TNFS_OP_READ, the function
				; above restores memory and copies data
				; to its final destination.

;--------------------------------------------------------------------------
; F_tnfs_write
; Writes to an open file descriptor.
; Arguments:		A = file handle
; 			HL = pointer to buffer to write
;			BC = number of bytes to write
; Returns with carry set on error and A = return code. BC = bytes
; written.
.globl F_tnfs_write
F_tnfs_write:
	call F_fetchpage
	ret c
	ld (v_curfd), a
	call F_tnfs_setmountpt_fd	; set the current mount point
.writeloop4:
	push hl
	push bc
	ld a, (v_curfd)		; load current file handle
	call F_tnfs_write_blk	; write up to maximum block size
	pop hl			; get original length
	pop de
	jp c, F_leave		; error - exit
	sbc hl, bc		; subtract bytes written from bytes to write
	jp z, F_leave		; if zero, leave now.
	ex de, hl		; get pointer into HL
	add hl, bc		; advance pointer
	ld b, d			; bytes remaining into BC
	ld c, e
	jr nz, .writeloop4	; next block if bytes remain
	jp F_leave

.globl F_tnfs_write_blk
F_tnfs_write_blk:
	ex af, af'
	ld a, b			; cap write size at 512 bytes
	cp 0x02
	jr c, .continue5		; less than 512 bytes if < 0x02
.sizecap5:
	ld bc, 512		; cap at 512 bytes
.continue5:
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
	ld a, h			; Is the data in 0x1000-0x1FFF?
	and 0xF0		; mask out bottom nibble
	cp 0x10			; 0x10-0x1F...
	call z, F_restorepage	; Flip page A to its original value
	ldir
	call z, F_fetchpage	; get our page back if we paged
	call F_tnfs_message_w	; write the command and get the reply
	ret c			; network error
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a			; check for tnfs error
	jr z, .getsize5
	scf			; set carry to flag error
	ret			
.getsize5:
	ld bc, (tnfs_recv_buffer+tnfs_msg_offset)
	ret

;------------------------------------------------------------------------
; F_tnfs_close
; Closes an open file descriptor.
; Arguments		A = the file descriptor
; Returns with carry set on error and A = return code.
.globl F_tnfs_close
F_tnfs_close:
        call F_fetchpage
        ret c
	push af
	call F_tnfs_setmountpt_fd	; set the mount point for the fd
	pop af

        ld c, FREEFD
        call RESALLOC           ; always free the FD even if there's an error

        ld b, a
        ld a, TNFS_OP_CLOSE
        call F_tnfs_header_w
        ld e, b                 ; make address of TNFS handle
        ld d, HANDLESPACE / 256
        ld a, (de)              ; get the TNFS handle
        ld (hl), a              ; insert it into the message
        inc hl
        call F_tnfs_message_w_hl
        jp c, F_leave           ; protocol error
        ld a, (tnfs_recv_buffer+tnfs_err_offset)
        and a
        jp z, F_leave           ; no error
        scf             
        jp F_leave              ; error, return with c set

;------------------------------------------------------------------------
; F_tnfs_stat
; Stats a file (gets information on it).
; Arguments		HL = pointer to a null-terminated string - the filename
; 			DE = pointer to a buffer for the result
; The result is exactly the structure defined in tnfs-protocol.txt6
; Returns with carry set on error and A = return code.
; An optimization would be to copy the reply directly from the ethernet
; buffer and save a buffer copy.
.globl F_tnfs_stat
F_tnfs_stat:
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
	jr z, .copybuf7
	scf			; tnfs error
	jp F_leave
.copybuf7:
	dec bc			; decrease BC by the size of the
	dec bc			; TNFS header + status byte
	dec bc
	dec bc
	dec bc
	ld hl, tnfs_recv_buffer+tnfs_msg_offset
	ldir			; de is already the dest, bc is size
	jp F_leave

;---------------------------------------------------------------------------
; F_tnfs_rename
; Renames a file.
; Arguments		HL = pointer to null terminated source filename
;			DE = pointer to null terminated destination filename
;			A = mount point
.globl F_tnfs_rename
F_tnfs_rename:
	call F_fetchpage
	ret c
	ld (v_curmountpt), a

	push de
	push hl
	ld a, TNFS_OP_RENAME
	call F_tnfs_header_w	; create the header
	ex de, hl
	pop hl			; get source argument
	call F_tnfs_abspath
	pop hl			; get destination argument
	call F_tnfs_abspath
	call F_tnfs_message_w	; Send the message
	jp F_tnfs_simpleexit

;---------------------------------------------------------------------------
; F_tnfs_lseek
; Seek to a position in a file.
; Parameters: 	A = file descriptor
;		C = operation 0x00 = SEEK_SET, 0x01 = SEEK_CUR, 0x02 = SEEK_END
;		DEHL = 32 bit signed seek position
; Returns with carry set and A=error code on error.
.globl F_tnfs_lseek
F_tnfs_lseek:
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
.globl F_tnfs_unlink
F_tnfs_unlink:
	ld b, TNFS_OP_UNLINK
	jp F_tnfs_simplepathcmd

;---------------------------------------------------------------------------
; F_tnfs_chmod
; Changes file mode.
; Parameters		HL = pointer to filename
;			DE = 16 bit mode flags
; On error returns with carry set and A=error
.globl F_tnfs_chmod
F_tnfs_chmod:
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

;--------------------------------------------------------------------------
; F_tnfs_setmountpt_fd
; Sets the current mount point to what the fd in A is using
F_tnfs_setmountpt_fd:
	push hl
	ld h, HMETASPACE / 256		; get fd's metadata pointer
	ld l, a
	ld a, (hl)			; get the mountpoint for this fd
	ld (v_curmountpt), a		; set the current mountpoint
	pop hl
	ret

