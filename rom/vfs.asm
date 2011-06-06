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
.include	"moduledefs.inc"
.include	"sysvars.inc"
.include	"sysdefs.inc"
.include	"sockdefs.inc"

;----------------------------------------------------------------------------
; Dispatcher routines.
.globl F_fd_dispatch
F_fd_dispatch:
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
J_notopen:
	pop de
	pop hl
	ld a, 0x06		; TODO: errno.asm1 - EBADF
	scf
	ret

.globl F_vfs_dispatch
F_vfs_dispatch:
	call F_cleanpath	; remove leading/trailing space
	call F_resolvemp	; See if a mount point is specified
	ex (sp), hl
	push de
	push af
	ld de, VFSVECBASE
	add a, e		; find the address of the VFS vector
	ld e, a			; and check that something is mounted
	ld a, (de)
	and a			; not mounted if the VFS ROM no. was 0
	jr nz, F_dispatch_3
.notmounted2:
	pop af			; fix the stack
	pop de
	pop hl
	ld a, 0x23		; TODO: errno.asm2
	scf
	ret

.globl F_dir_dispatch
F_dir_dispatch:
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
.globl F_dispatch_notfd
F_dispatch_notfd:
	push af
	jr F_dispatch_1
.globl F_dispatch
F_dispatch:
	push af
	sub FDBASE%256
.globl F_dispatch_1
F_dispatch_1:
	add a, e		; Calculate the address in the fd table
.globl F_dispatch_2
F_dispatch_2:
	ld e, a			; make DE point to it
	ld a, (de)		; get the ROM to page
	and a			; ROM 0 is handled specially
	jr z, isasocket
.globl F_dispatch_3
F_dispatch_3:
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
isasocket:
	ld a, 0xCC		; Check for READ. Note the LSB addresses
	cp l			; are +3 on the actual (because CALL put
	jr z, .sockread8		; the return address, not the actual
	ld a, 0xCF		; address on the stack!)
	cp l
	jr z, .sockwrite8
	ld a, 0xD8		; POLL
	cp l
	jr z, .sockpoll8
	ld a, 0xD5		; CLOSE
	jr nz, .badcall8
	pop af
	pop de
	pop hl
	jp F_sockclose
.sockread8:
	pop af
	pop de
	pop hl
	jp F_recv
.sockwrite8:
	pop af
	pop de
	pop hl
	jp F_send
.sockpoll8:
	pop af
	pop de
	pop hl
	jp F_pollfd
.badcall8:
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
.globl F_mount
F_mount:
	; First search for a ROM that handles this protocol.
	ld (v_mountnumber), a	; save device number
	ld hl, vectors
.findrom9:
	ld a, (hl)		; get ROM ID
	and a			; check for the terminator
	jr z, .notfound9		; no ROM found that handles this protocol
.testproto9:
	push hl			; save current vector table address
	ld a, l
	sub ROMVECOFFS		; subtract the base addr to get the ROM slot
	push af			; save ROM slot number
	call F_pushpageB
	ld hl, (MOD_VEC_MOUNT)	; get address of the real mount routine
	ld a, h			; H must be 0x20-0x2F for a valid MOUNT routine
	and 0xF0		; mask out low nibble
	cp 0x20			; result should be 0x20 for valid MOUNT
	jr nz, .testnext9
	ld de, .return9		; simulate CALL instruction with JP (HL)
	push de
	ld a, (v_mountnumber)
	jp (hl)
.return9:
	jr c, .mountfailed9	; Tried but failed to mount?
	jr z, .testnext9		; Protocol is not ours?
	call F_poppageB		; restore original page B
	pop af			; restore ROM page number
	pop hl			; restore the stack
	ret
.testnext9:
	call F_poppageB		; restore stack
	pop af			; ROM slot number
	pop hl			; table pointer
	inc l			; and point it to the next ROM list entry
	jr .findrom9

.mountfailed9:
	ex af, af'
	call F_poppageB		; restore stack and page
	pop af			; unwind stack	
	pop hl			; restore HL
	ex af, af'
	ret
.notfound9:
	ld a, 0xFE		; TODO: proper return code here
	scf
	ret

;--------------------------------------------------------------------------
; F_freemountpoint
; Frees a mount point, passed in A
.globl F_freemountpoint
F_freemountpoint:
	add a, VFSVECBASE % 256	; calculate the address in sysvars
	ld h, 0x3F		; sysvars page
	ld l, a
	ld (hl), 0		; clear it down
	ret

;--------------------------------------------------------------------------
; F_setmountpoint
; Sets the default mountpoint in use, passed in A
.globl F_setmountpoint
F_setmountpoint:
	cp 4			; mount point must be <= 3
	ccf			; flip the carry flag
	ret c			; so if there's an error we return with C
	ld (v_vfs_curmount), a
	ret

;--------------------------------------------------------------------------
; F_resalloc
; Resource allocator/deallocator for file and directory descriptors.
; Parameters: FD param in A
;             Flags in C
; C bit 0 = Set=Allocate, reset=free
; C bit 1 = Set=Directory, reset=File
.globl F_resalloc
F_resalloc:
	bit 1, c
	jr nz, F_allocdirhnd
;--------------------------------------------------------------------------
; F_allocfd
; Allocates a file descriptor. 
; Parameters:	A = ROM number for the fd
; On return HL = address of fd. Functions that use this should set this
; to a value that means something (and bit 7 must be reset). L = actual
; fd number.
.globl F_allocfd
F_allocfd:
	bit 0, c
	jr z, F_freefd
	push bc
	ld hl, v_fd1hwsock	; lowest address in fd table
	ld b, MAX_FDS
.findloop13:
	bit 7, (hl)		; not allocated yet?
	jr nz, .alloc13
	inc l
	djnz .findloop13		; keep looking until none left
	scf			; out of free file descriptors
	pop bc
	ret
.alloc13:
	res 7, (hl)		; basic allocation
	push hl			; save FD address and FD number
	ld b, a			; save parameter
	ld a, l
	add a, VECOFFS		; find the address of the vector table
	ld l, a			; and make HL point to it
	ld a, b			; retrieve param
	ld (hl), a		; set vector table page address
	pop hl
	pop bc
	ret			; FD is returned in L, address in HL

;-------------------------------------------------------------------------
; F_freefd
; Frees the file descriptor passed in A.
.globl F_freefd
F_freefd:
	push hl
	push af
	ld h, v_fd1hwsock / 256
	ld l, a
	ld (hl), 0x80		; Set bit 7 to mark the fd as freed.
	add a, VECOFFS		; add the vector table offset
	ld l, a			; and point HL to it
	ld (hl), 0x00		; clear it down
	pop af
	pop hl
	ret

;------------------------------------------------------------------------
; F_allocdirhnd
; Allocates a directory handle.
; Parameters	A = ROM number for the handle
; On return HL = address of the handle, L is the handle itself
.globl F_allocdirhnd
F_allocdirhnd:
	bit 0, c
	jr z, F_freedirhnd
	push bc
	ld hl, v_dhnd1page
	ld b, MAX_DIRHNDS
	ex af, af'
.findloop15:
	ld a, (hl)
	and a			; 0 = free
	jr z, .alloc15
	inc l
	djnz .findloop15
	scf			; all are used up
	pop bc
	ret
.alloc15:
	ex af, af'
	ld (hl), a		; allocate it by setting the page number
	pop bc
	ret

;-----------------------------------------------------------------------
; F_freedirhnd
; Frees the directory handle passed in A
.globl F_freedirhnd
F_freedirhnd:
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
.globl F_resolvemp
F_resolvemp:
	push hl
	inc hl			; check for the :
	ld a, (hl)
	cp ':'
	jr nz, .returncurrent17	; Return the current mount point.
	dec hl
	ld a, (hl)		; Get the putative FS number
	sub '0'			; Subtract ascii '0' to make the actual number
	jr c, .returncurrent17
	cp 4			; Greater than 3?
	jr nc, .returncurrent17
	pop hl
	inc hl			; effectively strip off the "n:"
	inc hl
	ret

.returncurrent17:
	pop hl
	ld a, (v_vfs_curmount)
	ret

;----------------------------------------------------------------------
; F_cleanpath
; Gets rid of leading/trailing white spaces
.globl F_cleanpath
F_cleanpath:
	push hl
	ld bc, 256
	xor a
	cpir			; find the argument's end
	dec hl			; end - 1
.spaceloop18:
	dec hl			
	ld a, (hl)
	cp ' '
	jr nz, .done18
	ld (hl), 0		; remove trailing white space
	jr .spaceloop18
.done18:
	pop hl
	ret

