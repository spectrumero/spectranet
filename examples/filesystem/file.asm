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

; File functions.

;---------------------------------------------------------------------------
; F_open
; This opens a file (if it exists), or returns an error if it doesn't.
; Opening a file consists of looking to see if the filename exists, and if
; it does, setting up a new file descriptor. 
; Parameters:		HL = pointer to the null terminated filename
;			D  = Flags
;			E  = Mode
;			A = mount point handle
F_open
	ld (v_hlsave), hl	; Save filename pointer
	ld hl, FILETABLE
	ld b, NUMFILES
.loop
	ld (v_bcsave), bc	; and save the counter (it's molested by cpi)
	ld e, (hl)		; Get the pointer to our file list
	inc hl
	ld d, (hl)
	inc hl
	push hl			; save the address
	ld de, (v_hlsave)	; and get the requested file back...
.compare
	ld a, (de)
	cpi
	jr nz, .notthis
	ld a, (de)		; check for end of string
	and a
	jr z, .found
	inc de
	jr .compare
.notthis
	pop hl
	ld bc, (v_bcsave)
	djnz .loop
.found
	pop hl			; restore the stack
	
	; The file is now found so we can now try to allocate a file
	; descriptor. The file descriptor has two parts - the fd itself
	; which contains some flags (the lower 5 bits being device specific)
	; and the page table for the file descriptor, which should be set
	; to point at this ROM. The ALLOCFD routine takes care of setting
	; the page number in the page table, but returns the address of
	; the fd itself in HL for us to fill in with any system specific
	; bits.
	ld a, (v_pgb)		; fetch our ROM number
	call ALLOCFD		; Find a free FD
	jr c, .nofds		; Exit if there's not one free.
	ld bc, (v_bcsave)	; We'll use the counter as our "fs specific"
				; part of the fd
	ld a, b			; and also set bit 5 to 
	or 0x20			; indicate "not a socket"
	ld (hl), a

	; At this stage, the fd is now allocated, and set, and our file
	; is open. L contains the actual number that should be returned
	; to a program - this should be returned in A.
	ld a, l
	ret

.nofds
	ld a, 0xFF		; TODO - proper return code
	ret

;--------------------------------------------------------------------------
; F_close
; A real filesystem needs to do a lot more than this.
F_close
	; ...all that must be done for this example is to free up the 
	; file descriptor data in the system variables area.
	jp FREEFD

;-------------------------------------------------------------------------
; F_read
; Reads data from the "file" into a buffer pointed to by DE, to a maximum
; of BC bytes.
; A real filesystem will need to ensure that the file is opened for reading.
; Parameters:	A = file descriptor
; 		DE = buffer to fill
;		BC = max bytes
F_read
	call F_fetchpage		; get our private SRAM page
	call F_getfileptr		; HL now is the file pointer pointer
.loop
	push hl
	call F_readbyte
	pop hl
	jr c, .finish			; EOF reached
	ld (de), a			; transfer data to buffer
	inc de
	dec bc
	ld a, b
	or c				; check for exceeded max count
	jr nz, .loop
.finish
	call F_restorepage	
	ret

; Utility routine to fetch an fd's file pointer 
F_getfileptr
	push af
	sub FDBASE % 256		; calculate the offset by subtracting
	rlca				; the lowest FD number and multiplying
	add a, v_fptr1 % 256		; by 2, then adding our vars base
	ld h, 0x10			; address of our private SRAM
	ld l, a				; (hl) = file pointer
	pop af
	ret

; HL = address of file pointer
F_readbyte
	push bc
	ld c, (hl)			; get file pointer
	inc l
	ld b, (hl)
	ld a, (de)			; get byte
	inc bc				; inc file pointer
	ld (hl), b			; save the pointer
	dec l
	ld (hl), c
	ld bc, PTRCTROFFS
	add hl, bc			; check bytes left
	ld c, (hl)
	inc l
	ld b, (hl)
	ex af, af'
	ld a, b
	or c
	jr z, .eof			; EOF
	dec bc
	ld (hl), b			; save new bytes remaining
	dec l
	ld (hl), c
	ex af, af'
	pop bc
	ret
.eof
	pop bc
	ld a, 0x21			; EOF - TODO - errno
	scf
	ret

FILE1
STR_readstring	defb "The Hello World of filesystems\n",0
FILE1END
FILE2
STR_foobar	defb "Foo bar baz\n",0
FILE2END
FILE3
STR_something	defb "Bamus batis bant\n",0
FILE3END

FILE1EOF	defw FILE1END
FILE2EOF	defw FILE2END
FILE3EOF	defw FILE3END

