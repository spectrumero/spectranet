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

; Filesystem example.
; This demonstrates a simple filesystem that can be mounted, a file opened,
; and written to, and closed.

	org 0x2000
	include "spectranet.asm"
	include "fsvars.asm"
	include "../../rom/sysvars.sym"
	
	; First, define the tables.
sig	defb 0xAA		; This is a valid ROM module
romid	defb 0xFE		; with ID 0xFE (generic filesystem ID)
reset	defw F_init		; reset vector
mount	defw F_do_mount		; The mount routine
	defw 0xFFFF
	defw 0xFFFF
	defw 0xFFFF
	defw 0xFFFF
idstr	defw STR_ident		; ROM identity string
modcall	ret			; No modcall code
	defw 0			; pad out to start of...

; The VFS table. This is a jump table for all the VFS entry points.
; Only some are implemented, the rest point to a routine that returns
; an error.
	jp F_umount		; Unmount routine
	jp F_opendir		; Open a directory
	jp F_open		; Open a file
	jp F_undef		; Unlink - not implemented
	jp F_undef		; Mkdir - not implemented
	jp F_undef		; Rmdir - not implemented
	jp F_size		; Filesystem size
	jp F_free		; Filesystem free space
	jp F_stat		; Filesystem 'stat' info
	jp F_undef		; Change mode - not implemented
	jp F_read		; Read a file
	jp F_write		; Write to a file
	jp F_undef		; Seek - not implemented
	jp F_close		; Close a file
	jp F_undef		; Poll - not implemented
	jp F_readdir		; readdir
	jp F_closedir		; Close a directory
	jp F_undef		; chdir
	jp F_undef		; reserved1
	jp F_undef		; reserved2

STR_ident
	defb "Example filesystem",0

; The 'undef' routine just returns an error. (Put all other routines
; here till they are done!)
F_size
F_free
F_stat
F_write
F_undef
	ld a, 2
	out (254), a
	scf
	ld a, 0xFF		; TODO: The proper return code
	ret

;----------------------------------------------------------------------------
; Manage memory.
; F_init: Claim a page of SRAM for our sysvars.
F_init
	ld a, (v_pgb)		; Who are we?
	call RESERVEPAGE	; Reserve a page of static RAM.
	jr c, .failed
	ld b, a			; save the page number
	ld a, (v_pgb)		; and save the page we got
	rlca			; in our 8 byte area in sysvars
	rlca			; which we find by multiplying our ROM number
	rlca			; by 8.
	ld h, 0x39		; TODO - definition for this.
	ld l, a
	ld a, b
	ld (hl), a		; put the page number in byte 0 of this area.
	ld hl, STR_init
	call PRINT42
	ret
.failed
	ld hl, STR_allocfailed
	call PRINT42
	ret
STR_allocfailed	defb	"No memory pages available\n",0
STR_init	defb	"Example filesystem initialized\n",0

;-----------------------------------------------------------------------------
; F_fetchpage
; Gets our page of RAM and puts it in page area A.
F_fetchpage
	push af
	push hl
	ld a, (v_pgb)		; get our ROM number and calculate
	rlca			; the offset in sysvars
	rlca
	rlca
	ld h, 0x39		; address in HL
	ld l, a
	ld a, (hl)		; fetch the page number
	and a			; make sure it's nonzero
	jr z, .nopage
	inc l			; point hl at "page number storage"
	ex af, af'
	ld a, (v_pga)
	ld (hl), a		; store current page A
	ex af, af'
	call SETPAGEA		; Set page A to the selected page
	pop hl
	pop af
	or a			; ensure carry is cleared
	ret
.nopage
	pop hl			; restore the stack
	pop af
	ld a, 0xFF		; TODO: ENOMEM return code
	scf
	ret

F_printA
	push af
	push hl
	push de
	push bc
	ld hl, 0x3000
	call ITOH8
	ld hl, STR_a
	call PRINT42
	ld hl, 0x3000
	call PRINT42
	ld a, '\n'
	call PUTCHAR42
	pop bc
	pop de
	pop hl
	pop af
	ret
STR_a	defb "ROM A = ",0

;---------------------------------------------------------------------------
; F_restorepage
; Restores page A to its original value.
F_restorepage
	push af
	push hl
	ld a, (v_pgb)		; calculate the offset...
	rlca
	rlca
	rlca
	inc a			; +1
	ld h, 0x39
	ld l, a
	ld a, (hl)		; fetch original page
	call SETPAGEA		; and restore it
	pop hl
	pop af
	ret

; Now include the code that does all the work.
	include "mount.asm"
	include "file.asm"
	include "directory.asm"

; The list of our "files" (align with a 256 byte boundary)
	block 0x2300-$, 0xFF
FILETABLE	defw STR_file1
		defw STR_file2
		defw STR_file3

STR_file1	defb "foo",0
STR_file2	defb "bar",0
STR_file3	defb "baz",0

NUMFILES	equ 3

