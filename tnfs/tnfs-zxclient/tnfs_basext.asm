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

;---------------------------------------------------------------------------
; F_tbas_aload: Loads an arbitary file from the TNFS filesystem.
; The syntax is %aload "filename" CODE address. This allows the user
; to load an arbitrary file with no ZX formatting into memory.
F_tbas_aload
	rst CALLBAS
	defw ZX_EXPT_EXP		; expect a string expression
	cp TOKEN_CODE			; expect CODE
	jp nz, PARSE_ERROR
	rst CALLBAS			; fetch the next bit 
	defw ZX_NEXT_CHAR		; which must be a number
	rst CALLBAS
	defw ZX_EXPT1_NUM
	call STATEMENT_END		; and then the end of statement

	;------- runtime -------
	rst CALLBAS
	defw ZX_FIND_INT2		; find the 16 bit int	
	push bc				; save it
	rst CALLBAS
	defw ZX_STK_FETCH		; get the filename
	ld hl, INTERPWKSPC		; save it in workspace...
	call F_basstrcpy
	
	; Now read the file into memory
	ld hl, INTERPWKSPC
	pop de				; retrieve address
	call F_tbas_readrawfile
	jp c, J_tbas_error
	jp EXIT_SUCCESS

;----------------------------------------------------------------------------
; F_tbas_load: Loads a ZX file (BASIC, CODE etc.)
; The syntax is as for ZX BASIC LOAD, except %load.
; TODO: CODE et al.
F_tbas_load
	rst CALLBAS
	defw ZX_EXPT_EXP		; expect a string expression
	call STATEMENT_END		; and then the end

	;------ runtime ------
	rst CALLBAS
	defw ZX_STK_FETCH		; fetch the filename
	ld hl, INTERPWKSPC
	call F_basstrcpy		; copy + convert to C string

	; Now call the loader routine with the filename in HL
	ld hl, INTERPWKSPC
	call F_tbas_loader
	jp c, J_tbas_error
	jp EXIT_SUCCESS

;----------------------------------------------------------------------------
; F_tbas_save: Save a ZX file (BASIC, CODE etc.)
; The syntax is as for ZX BASIC SAVE.
; TODO: CODE et al.
F_tbas_save
	rst CALLBAS
	defw ZX_EXPT_EXP		; fetch the file name
;	rst CALLBAS
;	defw ZX_NEXT_CHAR		; Examine the next char
;	cp TOKEN_CODE			; for CODE
;	jr z, .savecode
;	cp TOKEN_SCREEN			; for SCREEN$
;	jr z, .savescreen	
;	cp TOKEN_LINE			; then for LINE
;	jr z, .savebasline

	call STATEMENT_END		; a basic BASIC save.

	;------- runtime for simple BASIC save -------
	rst CALLBAS
	defw ZX_STK_FETCH		; There is only a filename.
	push de				; save params
	push bc
	xor a				; type = 0
	call F_tbas_mktapheader		; Create the header

	; Fill in the header, length and length without vars
	ld hl, (ZX_E_LINE)		; get the length of the BASIC prog
	ld de, (ZX_PROG)		; by calculating it
	scf
	sbc hl, de		
	ld (INTERPWKSPC+OFFSET_LENGTH), hl	; prog + vars
	ld hl, (ZX_VARS)		; now save the length - vars
	sbc hl, de			; calculate it...
	ld (INTERPWKSPC+OFFSET_PARAM2), hl
	ld a, 0x80			; When no LINE, put 0x80 in PARAM1
	ld (INTERPWKSPC+OFFSET_PARAM1+1), a

	pop bc				; retrieve the filename
	pop de
	call F_tbas_writefile		; Write it out.
	jp c, J_tbas_error
	jp EXIT_SUCCESS

.savecode
.savescreen
.savebasline
	ld a, TBADTYPE			; TODO - code etc.
	jp J_tbas_error

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
	ld a, 2	
	rst CALLBAS			; set channel to 2
	defw 0x1601
.catloop
	ld a, (V_dirhandle)		; get the dir handle back
	ld de, INTERPWKSPC		; location for result
	call F_tnfs_readdir		; read dir
	jr c, .readdone			; read is probably at EOF
	ld hl, INTERPWKSPC
	call F_tbas_zxprint		; print a C string to #2
	ld a, '\r'			; newline
	rst CALLBAS
	defw 0x10
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
; F_tbas_zxprint
; Prints a C string to the current ZX channel
; HL = pointer to string 
F_tbas_zxprint
	ld a, (hl)
	and a
	ret z
	rst CALLBAS
	defw 0x10
	inc hl
	jr F_tbas_zxprint
	
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
NUMCMDS		equ	7
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
P_aload		defb	0x0b
		defw	CMD_ALOAD	; Arbitrary load
		defb	TNFS_PAGE
		defw	F_tbas_aload
P_load		defb	0x0b
		defw	CMD_LOAD	; Standard LOAD command
		defb	TNFS_PAGE
		defw	F_tbas_load
P_save		defb	0x0b
		defw	CMD_SAVE
		defb	TNFS_PAGE
		defw	F_tbas_save

CMD_MOUNT	defb	"%mount",0
CMD_UMOUNT	defb	"%umount",0
CMD_CHDIR	defb	"%cd",0
CMD_LS		defb	"%cat",0
CMD_ALOAD	defb	"%aload",0
CMD_LOAD	defb	"%load",0
CMD_SAVE	defb	"%save",0
STR_cwd		defb	".",0

