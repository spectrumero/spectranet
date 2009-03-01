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

; TNFS BASIC extensions
	include "../../rom/zxromdefs.asm"

;----------------------------------------------------------------------------
; F_tnfs_interpinit
; Initializes the interpreter.
F_tnfs_interpinit
	ld hl, PARSETABLE
	ld b, NUMCMDS
.loop
	push bc
	call ADDBASICEXT
	pop bc
	jr c, .installerror
	djnz .loop
	ld hl, STR_basicinit
	call PRINT42
	ret
.installerror
	ld hl, STR_basinsterr
	call PRINT42
	ret

;---------------------------------------------------------------------------
; F_tbas_mount
; BASIC interpreter for "mount"
; Syntax: %mount "user", "passwd", "host", "/path/to/mountpoint"
F_tbas_mount
	; Syntax and runtime
	rst CALLBAS
	defw ZX_EXPT_EXP		; string parameter - user
	cp ','				; comma
	jp nz, PARSE_ERROR
	rst CALLBAS
	defw ZX_NEXT_CHAR

	rst CALLBAS
	defw ZX_EXPT_EXP		; string parameter - passwd
	cp ','				; comma
	jp nz, PARSE_ERROR
	rst CALLBAS
	defw ZX_NEXT_CHAR

	rst CALLBAS
	defw ZX_EXPT_EXP		; string parameter - host
	cp ','				; comma
	jp nz, PARSE_ERROR
	rst CALLBAS
	defw ZX_NEXT_CHAR

	rst CALLBAS
	defw ZX_EXPT_EXP		; string parameter - path

	call STATEMENT_END		; followed by statement end

	; -------- Runtime only ---------
	rst CALLBAS
	defw ZX_STK_FETCH		; path string
	ld hl, INTERPWKSPC+8		; where the data will go
	ld (INTERPWKSPC+2), hl		; pointer to user string
	call F_basstrcpy		; copy string from BASIC
	
	push hl
	rst CALLBAS
	defw ZX_STK_FETCH
	pop hl
	ld (INTERPWKSPC), hl		; hostname
	call F_basstrcpy		; copy the string

	push hl
	rst CALLBAS
	defw ZX_STK_FETCH
	pop hl
	ld (INTERPWKSPC+6), hl		; passwd
	call F_basstrcpy		; copy the hostname

	push hl
	rst CALLBAS
	defw ZX_STK_FETCH
	pop hl
	ld (INTERPWKSPC+4), hl		; username
	call F_basstrcpy		; done!
.mount
	ld ix, INTERPWKSPC		; mount structure address
	call F_tnfs_mount
	jp c, J_tbas_error		; display the error message

	jp EXIT_SUCCESS

	; Copy a BASIC string to a C string.
	; BASIC string in DE, C string (dest) in HL
F_basstrcpy
	ld a, b				; end of string?
	or c
	jr z, .terminate
	ld a, (de)
	ld (hl), a
	inc hl
	inc de
	dec bc
	jr F_basstrcpy
.terminate
	xor a				; put the null on the end
	ld (hl), a
	inc hl
	ret	

;----------------------------------------------------------------------------
; F_tbas_umount
; Umount the mounted filesystem.
F_tbas_umount
	call STATEMENT_END		; no parameters

	;--------- runtime ---------
	call F_tnfs_umount
	jp c, J_tbas_error
	jp EXIT_SUCCESS	

;----------------------------------------------------------------------------
; F_tbas_chdir
; Handle changing directory
F_tbas_chdir
	rst CALLBAS
	defw ZX_EXPT_EXP		; expect a string expression
	call STATEMENT_END
	
	;-------- runtime --------
	rst CALLBAS
	defw ZX_STK_FETCH		; get the string
	ld hl, INTERPWKSPC
	call F_basstrcpy		; convert to a C string
	ld hl, INTERPWKSPC
	call F_tnfs_chdir
	jp c, J_tbas_error		; carry set = error
	jp EXIT_SUCCESS

;----------------------------------------------------------------------------
; F_tbas_ls
; List a directory
; Two forms - either %cat or %cat "directory"
F_tbas_ls
	cp 0x0d
	jr z, .noargs
	cp ':'
	jr z, .noargs
	
	; we have an argument supplied.
	rst CALLBAS
	defw ZX_EXPT_EXP		; expect a string
	call STATEMENT_END

	; --------- runtime ----------
	rst CALLBAS
	defw ZX_STK_FETCH		; get the directory arg
	ld hl, INTERPWKSPC
	call F_basstrcpy		; convert it to a C string
	ld hl, INTERPWKSPC
	jr .makecat

.noargs
	call STATEMENT_END
	
	; --------- runtime ----------
	ld hl, STR_cwd			; use the current dir
.makecat
	call F_tnfs_opendir		; open the directory
	jp c, J_tbas_error
	ld (V_dirhandle), a		; save the directory handle
.catloop
	ld de, INTERPWKSPC		; location for result
	call F_tnfs_readdir		; read dir
	jr c, .readdone			; read is probably at EOF
	ld hl, INTERPWKSPC
	call F_tbas_zxprint		; print a C string to #2
	ld a, (V_dirhandle)		; get the dir handle back
	jr .catloop
.readdone
	push af				; save error code while
	ld a, (V_dirhandle)		; we close the dir handle
	call F_tnfs_closedir
	pop hl				; pop into hl to not disturb flags
	jp c, J_tbas_error		; report any error
	ld a, h				; get original error code
	cp EOF				; EOF is good
	jp nz, J_tbas_error		; everything else is bad, report it
	jp EXIT_SUCCESS
	
;----------------------------------------------------------------------------
; handle errors and return control to BASIC.
; A=tnfs error number
J_tbas_error
	push af				; save error number
	call F_tnfs_geterrstr		; get the error string
	pop af
	jp REPORTERR			; exit to BASIC with error string

;----------------------------------------------------------------------------
; Data.
STR_basicinit	defb	"TNFS BASIC extensions installed\n",0
STR_basinsterr	defb	"Failed to install TNFS BASIC extensions\n",0

INTERPWKSPC	equ	0x3000		; interpreter workspace
NUMCMDS		equ	4
TNFS_PAGE	equ 	0		; for testing
PARSETABLE	
P_mount		defb	0x0b
		defw	CMD_MOUNT
		defb	TNFS_PAGE
		defw	F_tbas_mount	; Mount routine
P_umount	defb	0x0b
		defw	CMD_UMOUNT
		defb	TNFS_PAGE
		defw 	F_tbas_umount	; Umount routine
P_chdir		defb	0x0b
		defw	CMD_CHDIR
		defb	TNFS_PAGE
		defw	F_tbas_chdir	; Chdir routine
P_cat		defb	0x0b
		defw	CMD_LS
		defb	TNFS_PAGE
		defw	F_tbas_ls

CMD_MOUNT	defb	"%mount",0
CMD_UMOUNT	defb	"%umount",0
CMD_CHDIR	defb	"%cd",0
CMD_LS		defb	"%cat",0

