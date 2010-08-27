;The MIT License
;
;Copyright (c) 2010 Dylan Smith
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

; Handles post-BASIC initialization, allowing the machine to boot
; from a file named boot.zx.
;
; This routine does the following:
; If SHIFT is held, it tries to load 'boot.zx' off the currently
; mounted filesystem, using the normal BASIC loader that is contained
; in this module. The return stack is altered such that everything is
; skipped (the (c) message, entry into the editor etc) up to the point
; where lines get interpreted. If 'boot.zx' is loaded and was saved
; with a LINE parameter, this line is jumped to (by putting CONTINUE
; into the interpreter and setting OLDPPC to NEWPPC). If the LINE 
; parameter was not used, the BASIC program loaded is listed.
; 
; On error, the stack is restored back to its original state such that
; we re-enter BASIC at the point the (c) message is generated.

F_boot
	ld bc, 0xFEFE		; read SHIFT through V
	in a, (c)
	cp 0xBE			; SHIFT pressed?
	ret nz			; no, do nothing.
	ld hl, STR_bootmsg
	call PRINT42

	ld hl, 0
	add hl, sp		; hl = sp
	ld sp, (NMISTACK)
	pop de			; remove return addr from stack
	ld de, 0x12B4		; and return to ROM at CALL LINE-SCAN
	push de			; and place it on the ZX stack
	push hl			; save NMI stack pointer

	rst CALLBAS
	defw 0x16B0		; SET-MIN routine
	ld a, 0			
	rst CALLBAS		; Open K chan
	defw 0x1601		
	ld a, 0xFF		; ensure ERR_NR is set
	ld (ZX_ERR_NR), a

	ld hl, STR_BOOTDOTZX	; file to boot with
	ld de, INTERPWKSPC
	ld bc, STR_BOOTDOTZXLEN
	ldir			; move to common memory
	ld hl, INTERPWKSPC
	xor a			; file type = 0 (BASIC)
	call F_tbas_loader	; Try to load the file
	jr c, .err		; leave here if the loader had an error

	ld hl, (ZX_NEWPPC)	; get the value of NEWPPC
	ld a, h			; Is NEWPPC unset?
	or l
	jr z, .leave

	ld (ZX_OLDPPC), hl	; Put in OLDPPC so 'CONTINUE' jumps
	ld a, 0xE8		; keyword 'CONTINUE'
	rst CALLBAS
	defw 0x0F81		; ADD-CHAR
	ld a, '\n'
	rst CALLBAS
	defw 0x0F81
.leave
	pop hl			; get NMI stack pointer
	ld sp, hl		; and restore it
	ret
.err
	pop hl			; get NMI stack pointer
	pop de			; now restore return address
	ld de, 0x1299
	push de
	ld sp, hl		; and restore it
	ld hl, STR_loaderr	; or print an error message
	call PRINT42
	ret
STR_bootmsg	defb "Booting...\n",0
STR_loaderr	defb "Error loading boot.zx\n",0

