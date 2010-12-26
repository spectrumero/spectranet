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
.include	"automount.inc"
.include	"spectranet.inc"
.include	"ctrlchars.inc"
.include	"stdmodules.inc"
.text

; The automounter.
; Depends on the config module (which must exist or none of this will
; work).

;-------------------------------------------------------------------------
; Mount the filesystems listed in the configuration.
.globl F_automount
F_automount:
	ld hl, CFG_FINDSECTION
	ld de, AM_CONFIG_SECTION
	rst MODULECALL_NOPAGE
	ret c

	ld b, AM_MAX_FS			; loop through all possible fs
					; mount points
	ld a, AM_FS0
	ld (AM_ASAVE), a
.mountloop:
	push bc
	ld a, (AM_ASAVE)
	ld hl, CFG_GETCFSTRING
	ld de, AM_WORKSPACE_URL
	rst MODULECALL_NOPAGE		; get the config string
	call nc, .mount			; if there was a string try to
	ld a, (AM_ASAVE)
	inc a				; next mount string
	ld (AM_ASAVE), a
	pop bc				
	djnz .mountloop
	ret

.mount:
	ld hl, STR_mount		; print some information
	call PRINT42
	ld a, (AM_ASAVE)
	add a, '0'
	call PUTCHAR42
	ld a, ':'
	call PUTCHAR42
	ld hl, AM_WORKSPACE_URL
	call PRINT42
	ld a, NEWLINE
	call PUTCHAR42

	ld de, AM_WORKSPACE_URL		; since F_parseurl actually lives
	ld ix, AM_WORKSPACE_MOUNT	; within this module we'll call
	call F_parseurl			; it directly
	jr c, .noparse
	ld a, (AM_ASAVE)
	call MOUNT			; Mount it
	jr c, .nomount
	ret

.noparse:
	ld hl, STR_parseerr
	call PRINT42
	ret
.nomount:
	ld hl, STR_nomount
	call PRINT42
	ret

.data
STR_mount:	defb "Mounting ",0
STR_parseerr:	defb "Unable to parse URL",NEWLINE,0
STR_nomount:	defb "Cannot mount URL",NEWLINE,0
	
