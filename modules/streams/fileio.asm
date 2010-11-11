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
.include	"fcntl.inc"
.include	"spectranet.inc"
.include	"defs.inc"
.include	"sysvars.inc"
.text
; File manager - handles opening and closing of files

;--------------------------------------------------------------------------
; F_fileopen_impl
; Implementation of the file open routine.
; This routine is jumped into from the BASIC interpreter routine.
; Arguments are on the stack:
;	First entry: Stream number
;	Second: File to open (string)
;	Third: r, w or rw (string)
; This function must restore the stack. Like F_connect_impl, it also
; initializes the strean's info structure.
.globl F_fileopen_impl
F_fileopen_impl:
	call F_fetchpage		; fetch our memory
	call c, F_allocpage		; allocate it if it's not been done
	jr c, .memerr1			; Could not allocate

	pop bc				; Fetch the stream number
	ld (v_bcsave), bc		; and save it.

	pop de				; get the start and the
	pop bc				; length of the filename string
	ld hl, INTERPWKSPC
	call F_basstrcpy		; make a copy

	pop hl				; get the start and the
	pop bc				; length of the filemode string
	call F_getfilemode		; D=flags E=file mode
	push de				; save flags

	ld hl, INTERPWKSPC		; pointer to the filename
	call OPEN			; Try to open the file.
	jr c, .openerror1

	push af				;:Save the FD we got back
	
	; The file is now open, so create the new channel and attach a
	; stream.
	ld a, (v_bcsave)		; get the stream number
	call F_createchan		; Create a channel and attach
	ld a, (v_bcsave)
	rlca				; get the address of the
	rlca				; stream information area
	rlca
	ld h, 0x10			; HL points at it.
	ld l, a

	; TODO: Allocate only one buffer for RO on WO files
        call F_findfreebuf              ; create a write buffer
        jr c, .nobufcleanup1
        ld (hl), a                      ; save the buffer number
        inc l
        call F_findfreebuf              ; create a read buffer
        jr c, .nobufcleanup1
        ld (hl), a
        inc l

        ld (hl), 0                      ; Set write buffer pointer
        inc l
        ld (hl), 0                      ; Set read buffer pointer
        inc l                           ; Next address is the FD
	pop af				; get the FD back
        ld (hl), a                      ; store the FD
        inc l
        ld (hl), ISFILE                 ; Set "is a file" flag bit
	pop de				; get the file mode flags back
	ld a, O_RDONLY			
	cp e				; Read only file?
	jr nz, .writeable1
	set BIT_RDONLY, (hl)		; set read only bit in our flags

.writeable1:
        call F_leave                    ; restore memory page A
        jp EXIT_SUCCESS

.openerror1:
	; TODO: Proper error message here (indirect call to BASEXT rom)
	pop de				; restore the stack
	ld hl, STR_fileerr
	jp REPORTERR	
.memerr1:
	pop hl				; unwind the stack
	pop hl
	pop hl
	pop hl
	pop hl
	ld hl, STR_nomem
	jp REPORTERR

.nobufcleanup1:
	pop af				; get FD
	call VCLOSE			; close the file
	jp NOBUFCLEANUP			; clean up our structures

;-------------------------------------------------------------------------
; F_getfilemode: Parses the filemode string pointed to by HL with length
; BC, and returns the VFS filemode flags in E.
.globl F_getfilemode
F_getfilemode:
	ld b, c		; set byte counter
	ld de, 0	; clear flags register
.loop2:
	ld a, (hl)
	cp 'r'		; Read?
	jr nz, .next2
	set 0, e	; Set the read flag
.next2:	cp 'w'		; Write?
	jr nz, .next12
	set 1, e	; Set the write flag
.next12:
	cp 'a'		; Append?
	jr nz, .next22
	set 0, d
.next22:
	cp 'c'		; Create?
	jr nz, .next32
	set 1, d
.next32:
	cp 't'		; Truncate?
	jr nz, .next42
	set 3, d
.next42:
	inc hl
	djnz .loop2

	bit 1, e	; If the file is writeable, we need
	ret z		; to ensure there are sensible defaults for
	ld a, d		; the flags - truncate should be set by
	and 0x0F	; default if no flags were explicitly set.
	ret nz
	ld d, O_TRUNC|O_CREAT
	ret	

;-------------------------------------------------------------------------
; F_opendir_impl
; Opens a directory
; There's no need to create a buffer for a directory.
.globl F_opendir_impl
F_opendir_impl:
        call F_fetchpage                ; fetch our memory
        call c, F_allocpage             ; allocate it if it's not been done
        jr c, .memerr3                   ; Could not allocate

        pop bc                          ; Fetch the stream number
        ld (v_bcsave), bc               ; and save it.

        pop de                          ; get the start and the
        pop bc                          ; length of the filename string
        ld hl, INTERPWKSPC
        call F_basstrcpy                ; make a copy

	ld hl, INTERPWKSPC
	call OPENDIR			; try to open the dir
	jr c, .opendirerr3

	push af				;:Save the FD we got back
	
	; The file is now open, so create the new channel and attach a
	; stream.
	ld a, (v_bcsave)		; get the stream number
	call F_createchan		; Create a channel and attach
	ld a, (v_bcsave)
	rlca				; get the address of the
	rlca				; stream information area
	rlca
	ld h, 0x10			; HL points at it.
	add a, 4			; point A at the fd byte
	ld l, a				; HL = fd byte
	pop af
	ld (hl), a			; set directory descriptor
	inc l
	ld (hl), ISDIR|RDONLY
	
	call F_leave
	jp EXIT_SUCCESS			; done

.memerr3:
	pop hl				; restore stack
	pop hl
	pop hl
	ld hl, STR_nomem
	jp REPORTERR

.opendirerr3:
	; TODO: get proper error code
	call F_leave
	ld hl, STR_direrr
	jp REPORTERR

