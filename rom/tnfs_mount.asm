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
.include	"tnfs_defs.inc"
.include	"tnfs_sysvars.inc"
.include	"spectranet.inc"
.include	"sysvars.inc"
.include	"fcntl.inc"
.include	"errno.inc"

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
.globl F_tnfs_mount
F_tnfs_mount:
	call F_fetchpage	; get our private RAM page
	ret c			; which was allocated on startup.
	ld (v_curmountpt), a	; save the mount point for later

	; first check the requested protocol
	ld e, (ix+0)
	ld d, (ix+1)
	ld hl, STR_tnfstype
	ld bc, 5
.cploop1:
        ld a, (de)              ; Effectively this is a "strncmp" to check
        cpi                     ; that the passed protocol is "tnfs" plus
        jp nz, .notourfs1        ; a null.
        inc de
        jp pe, .cploop1

	; It is now certain that the requested FS is TNFS.
	; Check that we have an IP address set
	ld a, (v_ethflags)
	and 1			; if bit 0 is not 1 then we don't have
	jr nz, .lookup		; a valid IP

	ld a, EIO		; set the error number
	scf
	jp F_leave
.lookup:
	ld de, buf_tnfs_wkspc	; Look up the host
	ld l, (ix+2)
	ld h, (ix+3)
	push ix
	call GETHOSTBYNAME
	pop ix
	jp c, F_leave		; exit if host not found

	; create the socket that will be used for tnfs communications
	ld hl, buf_tnfs_wkspc	; IP address is here
	call F_tnfs_prepsock	; Open the socket if necessary
	jp c, F_leave		; unable to open socket

	; We've successfully looked up a host so create the datagram
	; that will be sent.
	ld hl, buf_tnfs_wkspc+4
	ld de, 0		; no session id yet
	xor a			; cmd is 0x00
	call F_tnfs_header	; create the header, HL now at the next byte
	ld (hl), 0		; version 1.01, little endian
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
	jr c, .mounterr1		; clean up on error

	; decode the result - first, check for error conditions
	ld a, (tnfs_recv_buffer + tnfs_err_offset)
	and a			; zero = no error
	jr nz, .mounterr1	; clean up on error

	ld hl, (tnfs_recv_buffer + tnfs_sid_offset)
	ld d, v_tnfs_sid0 / 256	; start with the lowest SID storage offset
	ld a, (v_curmountpt)	; get the intended mount point number
	rlca			; multiply by two
	add a, v_tnfs_sid0 % 256	; calculate the offset
	ld e, a			; DE = storage for the session id
	ex de, hl
	ld (hl), e		; save the session identifier
	inc l
	ld (hl), d

	ld a, (v_curmountpt)	; now calculate the address of the CWD
	add a, v_cwd0 / 256	; storage area (A=MSB)
	ld h, a			; and point HL there
	ld l, 0
	ld (hl), '/'
	inc l
	ld (hl), 0

	; set up mount point in VFS mount table
	ld a, (v_curmountpt)	; get the mount point
	add a, VFSVECBASE % 256	; find it in the sysvars
	ld l, a
	ld h, 0x3F		; point HL at the address in sysvars
	ld a, (v_pgb)		; Fetch our ROM number
	ld (hl), a		; and store it in the mount point table

	; set initial poll time
	or 1			; reset Z and C flags - mounted OK.
	jp F_leave

.mounterr1:
	call F_tnfs_checkclose	; close the socket if necessary
	scf			; set the carry flag
	jp F_leave
.notourfs1:
	xor a			; signal 'not our filesystem' by setting
	jp F_leave		; the zero flag.
STR_tnfstype: defb "tnfs",0

;-------------------------------------------------------------------------
; F_tnfs_umount
; Unmounts the TNFS filesystem and closes the socket.
.globl F_tnfs_umount
F_tnfs_umount:
	call F_fetchpage
	ret c
	ld (v_curmountpt), a

	ld a, TNFS_OP_UMOUNT
	call F_tnfs_header_w		; create the header
	inc hl				; advance past end
	call F_tnfs_message_w_hl	; not much to do here at all
	ret c				; communications error
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a				; no error?
	jr nz, .error2

	ld a, (v_curmountpt)
	rlca				; calculate the SID address
	add a, v_tnfs_sid0 % 256
	ld h, v_tnfs_sid0 / 256		; hl points at the sid
	ld l, a
	ld (hl), 0			; clear down the sid
	inc l
	ld (hl), 0

	ld a, (v_curmountpt)
	call FREEMOUNTPOINT		; clear down the mount point

	call F_tnfs_checkclose		; close the socket if necessary
	jp F_leave
.error2:
	scf				; flag the error condition
	jp F_leave
