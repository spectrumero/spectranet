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

;----------------------------------------------------------------------------
; VFS routines.
; These routines find the appropriate jump table for filesystems and file
; descriptors for standard routines.

; A ROM module that looks after a filesystem should have a vector table
; immediately after the general vector table, at address 0x2010.
; There are actually two vector tables - one that defines the call address
; of routines that act on open file descriptors (eg read, write, close etc.)
; and another tables that don't (mount, open, umount etc), and a table that
; lists calls that work on directory descriptors (readdir, closedir)
;
; The tables look like this:
; FS level operations
; 0x2013:	UMOUNT
; 0x2016:	OPENDIR
; 0x2019:	OPEN
; 0x201C:	UNLINK (delete a file)
; 0x201F:	MKDIR
; 0x2022:	RMDIR
; 0x2025:	SIZE (routine to get the size of the filesystem)
; 0x2028:	FREE (free space remaining)
; 0x202B:	STAT (stat a file)
; 0x202E:	CHMOD (change file mode)
; File descriptor level operations
; 0x2031:	READ
; 0x2034:	WRITE
; 0x2037:	LSEEK
; 0x203A:	CLOSE
; 0x203D:	POLL
; Directory descriptor level operations
; 0x2040:	READDIR
; 0x2043:	CLOSEDIR
;
; For functions that are not implemented, an address to a short routine
; that sets the carry flag and makes A the appropriate return code should
; be provided.
	include "moduledefs.asm"
;----------------------------------------------------------------------------
; Dispatcher routines.
F_fd_dispatch
	ex (sp), hl		; fetch return address, saving HL
	push de
	ld d, 0x3F		; point DE at memory address containing
	ld e, a			; the fd's flags
	ex de, hl
	bit CLOSEDBIT, (hl)
	ex de, hl
	jr nz, J_notopen
	ld de, FDVECBASE	; set base address of the descriptor table
	jr F_dispatch
J_notopen
	pop de
	pop hl
	ld a, 0x06		; TODO: errno.asm - EBADF
	scf
	ret

F_vfs_dispatch
	ex (sp), hl
	push de
	push af
	ld de, VFSVECBASE
	add a, e		; find the address of the VFS vector
	ld e, a			; and check that something is mounted
	ld a, (de)
	and a			; not mounted if the VFS ROM no. was 0
	jr nz, F_dispatch_3
.notmounted
	pop af			; fix the stack
	pop de
	pop hl
	ld a, 0x23		; TODO: errno.asm
	scf
	ret

F_dir_dispatch
	ex (sp), hl
	push de
	ld d, 0x3F		; point DE at the address containing
	ld e, a			; directory handle information
	ex af, af'
	ld a, (de)
	and a			; is this a valid open descriptor?
	jr z, J_notopen
	ex af, af'
	push af
	jr F_dispatch_2

;--------------------------------------------------------------------------
; F_dispatch
; Find the appropriate ROM page for the file (or whatever) descriptor,
; and fetch the jump address from the jump table within.
F_dispatch_notfd
	push af
	jr F_dispatch_1
F_dispatch
	push af
	sub FDBASE%256
F_dispatch_1
	add a, e		; Calculate the address in the fd table
F_dispatch_2
	ld e, a			; make DE point to it
	ld a, (de)		; get the ROM to page
	and a			; ROM 0 is handled specially
	jr z, isasocket
F_dispatch_3
	ex af, af'		; save AF while copying the current page
	ld a, (v_pgb)		; save current page
	ld (v_vfspgb_vecsave), a
	ex af, af'
	call F_setpageB		; page the ROM
	
	ld a, l			; calculate the table offset for the function
	sub VFSJUMPOFFSET
	ld (VFSJUMP+1), a	; set the jump vector
	pop af			; restore registers
	pop de
	pop hl
	call VFSJUMP

	push af			; restore original page B
	ld a, (v_vfspgb_vecsave)
	call F_setpageB
	pop af
	ret

; If someone access a socket via read/write rather than send/recv 
; it's handled here. There are only four functions that can be done to
; a socket via the VFS interface.
isasocket
	ld a, 0xCC		; Check for READ. Note the LSB addresses
	cp l			; are +3 on the actual (because CALL put
	jr z, .sockread		; the return address, not the actual
	ld a, 0xCF		; address on the stack!)
	cp l
	jr z, .sockwrite
	ld a, 0xD8		; POLL
	cp l
	jr z, .sockpoll
	ld a, 0xD5		; CLOSE
	jr nz, .badcall
	pop af
	pop de
	pop hl
	jp F_sockclose
.sockread
	pop af
	pop de
	pop hl
	jp F_recv
.sockwrite
	pop af
	pop de
	pop hl
	jp F_send
.sockpoll
	pop af
	pop de
	pop hl
	jp F_pollfd
.badcall
	pop af
	pop de
	pop hl
	ld a, 0xFF		; TODO: proper return code
	scf
	ret

;---------------------------------------------------------------------------
; F_mount
; Searches for an appropriate mount routines in the ROM modules we have,
; then tries to mount the FS.
; Parameters:		IX - pointer to an 10 byte structure that contains:
;			byte 0,1 - pointer to null terminated protocol
;			byte 2,3 - pointer to null terminated hostname
;                       byte 4,5 - pointer to null terminated mount source
;                       byte 6,7 - pointer to null terminated user id
;                       byte 8,9 - pointer to null terminated passwd
;			A - device number
; The actual mount routine that gets called should do the following:
; - If the protocol is supported, mount the FS and return with Z and C reset
; - If the proto is supported, but the FS can't be mounted, return with C set
; - If the proto is not recognised, return with Z set
F_mount
	; First search for a ROM that handles this protocol.
	ld (v_mountnumber), a	; save device number
	ld hl, vectors
.findrom
	ld a, (hl)		; get ROM ID
	and a			; check for the terminator
	jr z, .notfound		; no ROM found that handles this protocol
.testproto
	push hl			; save current vector table address
	ld a, l
	sub ROMVECOFFS		; subtract the base addr to get the ROM slot
	push af			; save ROM slot number
	call F_pushpageB
	ld hl, (MOD_VEC_MOUNT)	; get address of the real mount routine
	ld a, h			; H must be 0x20-0x2F for a valid MOUNT routine
	and 0xF0		; mask out low nibble
	cp 0x20			; result should be 0x20 for valid MOUNT
	jr nz, .testnext
	ld de, .return		; simulate CALL instruction with JP (HL)
	push de
	jp (hl)
.return
	jr c, .mountfailed	; Tried but failed to mount?
	jr z, .testnext		; Protocol is not ours?
	call F_poppageB		; restore original page B
	ld a, (v_mountnumber)	; get device number
	add VFSVECBASE%256	; and calculate the address in sysvars
	ld h, 0x3F		; MSB of the sysvars area
	ld l, a			; LSB - HL now has the addr of the fs table
	pop af			; restore ROM page number
	ld (hl), a		; Put the ROM number in the filesystem table
	pop hl			; restore the stack
	ret
.testnext
	call F_poppageB		; restore stack
	pop af			; ROM slot number
	pop hl			; table pointer
	inc l			; and point it to the next ROM list entry
	jr .findrom

.mountfailed
	call F_poppageB		; restore stack and page
	pop af
	pop hl			; restore HL
	ld a, 0xFF		; TODO: proper return code here
	ret
.notfound
	ld a, 0xFE		; TODO: proper return code here
	scf
	ret
	
;--------------------------------------------------------------------------
; F_allocfd
; Allocates a file descriptor. 
; Parameters:	A = ROM number for the fd
; On return HL = address of fd. Functions that use this should set this
; to a value that means something (and bit 7 must be reset). L = actual
; fd number.
F_allocfd
	push bc
	ld hl, v_fd1hwsock	; lowest address in fd table
	ld b, MAX_FDS
.findloop
	bit 7, (hl)		; not allocated yet?
	jr nz, .alloc
	inc l
	djnz .findloop		; keep looking until none left
	scf			; out of free file descriptors
	pop bc
	ret
.alloc
	res 7, (hl)		; basic allocation
	push hl			; save FD address and FD number
	ld b, a			; save parameter
	ld a, l
	add VECOFFS		; find the address of the vector table
	ld l, a			; and make HL point to it
	ld a, b			; retrieve param
	ld (hl), a		; set vector table page address
	pop hl
	pop bc
	ret			; FD is returned in L, address in HL

;-------------------------------------------------------------------------
; F_freefd
; Frees the file descriptor passed in A.
F_freefd
	push hl
	ld h, v_fd1hwsock / 256
	ld l, a
	ld (hl), 0x80		; Set bit 7 to mark the fd as freed.
	add VECOFFS		; add the vector table offset
	ld l, a			; and point HL to it
	ld (hl), 0x00		; clear it down
	pop hl
	ret

;------------------------------------------------------------------------
; F_allocdirhnd
; Allocates a directory handle.
; Parameters	A = ROM number for the handle
; On return HL = address of the handle, L is the handle itself
F_allocdirhnd
	push bc
	ld hl, v_dhnd1page
	ld b, MAX_DIRHNDS
	ex af, af'
.findloop
	ld a, (hl)
	and a			; 0 = free
	jr z, .alloc
	inc l
	djnz .findloop
	scf			; all are used up
	pop bc
	ret
.alloc
	ex af, af'
	ld (hl), a		; allocate it by setting the page number
	pop bc
	ret

;-----------------------------------------------------------------------
; F_freedirhnd
; Frees the directory handle passed in A
F_freedirhnd
	push hl
	ld h, v_dhnd1page / 256
	ld l, a
	ld (hl), 0
	pop hl
	ret

;-----------------------------------------------------------------------
; F_resolvemp
; Resolve the mount point from a path.
; The symbolic mount point can be 0:, 1:, 2:, 3:. Basically, the pattern
; is ^[0-3]: in regexp terms.
; HL = pointer to the string.
; Returns with A = mount point handle.
;F_resolvemp
;	push hl
;	inc hl			; check for the :
;	ld a, (hl)
;	cp ':'
;	jr nz, .returncurrent	; Return the current mount point.
;	dec hl
;	ld a, (hl)		; Get the putative FS number
;	sub a, '0'		; Subtract ascii '0' to make the actual number
;	jr c, .returncurrent
;	cp 4			; Greater than 3?
;	jr nc, .returncurrent
;	pop hl
;	ret

;.returncurrent
;	pop hl
;	ld a, (v_vfs_curmount)
;	ret

