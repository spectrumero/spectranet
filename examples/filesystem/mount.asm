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

; The mount and unmount functions.
; Mount is called with IX pointing to a data structure which tells us
; what's trying to be mounted. The first thing to do is to see if a filesystem
; that we know about is being mounted, by examining the "protocol" field.
; Parameters:		IX - pointer to an 10 byte structure that contains:
;			byte 0,1 - pointer to null terminated protocol
;			byte 2,3 - pointer to null terminated hostname
;                       byte 4,5 - pointer to null terminated mount source
;                       byte 6,7 - pointer to null terminated user id
;                       byte 8,9 - pointer to null terminated passwd
; The "device number" - or where it's to be mounted - i.e. "drive 0 to 3"
; is in the system variable v_mountnumber.
F_do_mount
	ld e, (ix+0)		; protocol
	ld d, (ix+1)
	ld hl, STR_fstype
	ld bc, 4
.cploop
	ld a, (de)		; Effectively this is a "strncmp" to check
	cpi			; that the passed protocol is "dev" plus
	jr nz, .notourfs	; a null.
	inc de
	jp pe, .cploop

	; Now we know the filesystem is for us, attempt to mount it.
	; In our case, the mount will never fail, but in the case of other
	; filesystems, an attempt to do whatever's needed to mount it should
	; be done, then code like this should run to put the page number
	; of the ROM into the mount table.
	ld a, (v_mountnumber)	; Get the user requested mount number.
	add VFSVECBASE%256	; Add the vector table base address to
	ld l, a			; form the LSB of the table address to fill.
	ld h, 0x3F		; 0x3F = system variables block
	ld a, (v_pgb)		; Find our ROM number.
	ld (hl), a		; And put it in the mount table.
	or 1			; reset Z and C flags - mounted OK
	ret

	; This wasn't a protocol that we know about, so tell the control
	; routine, which will go on to ask any other modules.
.notourfs
	xor a			; ...by setting the zero flag.
	ret
	

;---------------------------------------------------------------------------
; F_umount: Unmounts the filesystem
; Given this filesystem is purely in memory, there's not actually a lot
; that needs to be done, other than remove the entry from the FS list.
; On entry the A register contains the mount point handle.
;
; This function is where you would free up any resources associated with
; the mounted file system (perhaps close connections, free memory,
; do something to a piece of hardware etc.)
F_umount
	add VFSVECBASE%256	; A = LSB of the table address
	ld h, 0x3F
	ld l, a			; HL now points at the table address
	ld (hl), 0		; Clear the mount point handle.
	ret

STR_fstype
	defb "dev",0
