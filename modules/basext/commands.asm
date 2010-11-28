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
.include	"zxrom.inc"
.include	"spectranet.inc"
.include	"defs.inc"
.include	"fcntl.inc"
.include	"sysvars.inc"
.include	"zxsysvars.inc"
.text
;---------------------------------------------------------------------------
; F_tbas_mount
; BASIC interpreter for "mount"
; Syntax: %mount mountpoint, "url"
.globl F_tbas_mount
F_tbas_mount:
	; Syntax and runtime
	rst CALLBAS
	defw ZX_EXPT1_NUM
	cp ','				; comma
	jp nz, PARSE_ERROR
	rst CALLBAS
	defw ZX_NEXT_CHAR

	rst CALLBAS
	defw ZX_EXPT_EXP		; string parameter - an URL

	call STATEMENT_END		; followed by statement end

	; -------- Runtime only ---------
	ld hl, INTERPWKSPC		; clear space for the
	ld de, INTERPWKSPC+1		; mount argument structure
	ld bc, 9
	ld (hl), 0
	ldir

	rst CALLBAS
	defw ZX_STK_FETCH		; path string
	ld hl, INTERPWKSPC+10
	call F_basstrcpy		; copy string from BASIC
	ld ix, INTERPWKSPC		; where to place the mount struct
	ld hl, INTERPWKSPC+10		; location of the string to parse
	call F_parseurl
	jr c, .badurl1

	rst CALLBAS			; fetch the mount point
	defw ZX_FIND_INT2
	
.mount1:
	ld a, c				; mount point in BC
	call MOUNT
	jp c, J_tbas_error		; display the error message

	jp EXIT_SUCCESS

.badurl1:
	ld a, EBADURL
	jp J_tbas_error

	; Copy a BASIC string to a C string.
	; BASIC string in DE, C string (dest) in HL
.globl F_basstrcpy
F_basstrcpy:
	ld a, b				; end of string?
	or c
	jr z, .terminate2
	ld a, (de)
	ld (hl), a
	inc hl
	inc de
	dec bc
	jr F_basstrcpy
.terminate2:
	xor a				; put the null on the end
	ld (hl), a
	inc hl
	ret	

;----------------------------------------------------------------------------
; F_tbas_umount
; Umount the mounted filesystem.
.globl F_tbas_umount
F_tbas_umount:
	rst CALLBAS
	defw ZX_EXPT1_NUM		; 1 parameter - mount point number
	call STATEMENT_END

	;--------- runtime ---------
	rst CALLBAS
	defw ZX_FIND_INT2
	ld a, c				; mount point is in BC	
	call UMOUNT
	jp c, J_tbas_error
	jp EXIT_SUCCESS	

;----------------------------------------------------------------------------
; F_tbas_chdir
; Handle changing directory
.globl F_tbas_chdir
F_tbas_chdir:
	rst CALLBAS
	defw ZX_EXPT_EXP		; expect a string expression
	call STATEMENT_END
	
	;-------- runtime --------
	rst CALLBAS
	defw ZX_STK_FETCH		; get the string
	ld hl, INTERPWKSPC
	call F_basstrcpy		; convert to a C string
	ld hl, INTERPWKSPC
	call CHDIR
	jp c, J_tbas_error		; carry set = error
	jp EXIT_SUCCESS

;---------------------------------------------------------------------------
; F_tbas_aload: Loads an arbitary file from the TNFS filesystem.
; The syntax is %aload "filename" CODE address. This allows the user
; to load an arbitrary file with no ZX formatting into memory.
.globl F_tbas_aload
F_tbas_aload:
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
.globl F_tbas_load
F_tbas_load:
	rst CALLBAS
	defw ZX_EXPT_EXP		; expect a string expression
	cp TOKEN_CODE			; Check for CODE...
	jr z, .loadcode6
	call STATEMENT_END		; If not, statment end for BASIC.

	;------ runtime for BASIC ------
	xor a				; type 0x00 is BASIC
.loader6:
	push af				; save type
	rst CALLBAS
	defw ZX_STK_FETCH		; fetch the filename
	ld a, b				; check for empty string
	or c
	jr nz, .havefilename6
	ld hl, STR_BOOTDOTZX
	ld de, INTERPWKSPC
	ld bc, STR_BOOTDOTZXLEN
	ldir
	jr .loadbasic6
.havefilename6:
	ld hl, INTERPWKSPC
	call F_basstrcpy		; copy + convert to C string
.loadbasic6:
	; Now call the loader routine with the filename in HL
	ld hl, INTERPWKSPC
	pop af				; get type id
	call F_tbas_loader
	jp c, J_tbas_error
	jp EXIT_SUCCESS

.loadcode6:
	; TODO - code to a specific address.
	rst CALLBAS
	defw ZX_NEXT_CHAR
	call STATEMENT_END

	;------ runtime for CODE with no addr -------
	ld a, 3				; type=CODE
	jr .loader6			; get the filename then load.

;----------------------------------------------------------------------------
; F_tbas_save: Save a ZX file (BASIC, CODE etc.)
; The syntax is as for ZX BASIC SAVE.
; TODO: CODE et al.
.globl F_tbas_save
F_tbas_save:
	rst CALLBAS
	defw ZX_EXPT_EXP		; fetch the file name
	cp TOKEN_CODE			; for CODE
	jr z, .savecode7
	cp TOKEN_SCREEN			; for SCREEN$
	jr z, .savescreen7	
	cp TOKEN_LINE			; then for LINE
	jr z, .savebasline7

	call STATEMENT_END		; a basic BASIC save.

	;------- runtime for simple BASIC save -------
	rst CALLBAS
	defw ZX_STK_FETCH		; Fetch the file name
	push de				; save the filename
	push bc
	xor a
	call F_tbas_mktapheader
	ld hl, 0xFFFF			; set param1 to >32767
	ld (INTERPWKSPC+OFFSET_PARAM1), hl
	jr .makebasicblock7

	; Deal with SAVE "filename" CODE
.savecode7:
	rst CALLBAS
	defw ZX_NEXT2_NUM		; check for 2 numbers
	call STATEMENT_END		; then end of command.
	
	; Runtime
	rst CALLBAS
	defw ZX_FIND_INT2		; Get the length
	push bc				; into BC and save it
	rst CALLBAS
	defw ZX_FIND_INT2		; and the start
	push bc				; and save that, too
.savecodemain7:
	rst CALLBAS
	defw ZX_STK_FETCH		; and get the filename
	ld a, 3				; type = 3 - CODE
	call F_tbas_mktapheader		; create the header template
	pop hl				; retrieve the start address
	ld (INTERPWKSPC+OFFSET_PARAM1), hl	; and put it in the header
	pop hl				; and the length
	ld (INTERPWKSPC+OFFSET_LENGTH), hl	; and put it in the header
	call F_tbas_writefile		; finally write it out
	jp c, J_tbas_error
	jp EXIT_SUCCESS
	
.savescreen7:
	rst CALLBAS
	defw ZX_NEXT_CHAR		; advance to the end of the line
	call STATEMENT_END
	
	; Runtime
	ld hl, 6912			; Put the length of a SCREEN$
	push hl				; on the stack
	ld hl, 16384			; followed by the start address
	push hl
	jr .savecodemain7		; and do as for CODE

.savebasline7:
	rst CALLBAS
	defw ZX_NEXT_CHAR
	rst CALLBAS
	defw ZX_EXPT1_NUM		; 1 number - the line number
	call STATEMENT_END

	; Runtime for save "x" LINE y
	rst CALLBAS
	defw ZX_FIND_INT2		; Fetch the number
	ld (v_bcsave), bc
	rst CALLBAS
	defw ZX_STK_FETCH		; Fetch the file name
	push de
	push bc
	xor a				; type = 0
	call F_tbas_mktapheader		; Create the header
	ld hl, (v_bcsave)		; get LINE parameter
	ld (INTERPWKSPC+OFFSET_PARAM1), hl ; Put it into parameter 1
.makebasicblock7:

	; Fill in the header, length and length without vars
	ld hl, (ZX_E_LINE)		; get the length of the BASIC prog
	ld de, (ZX_PROG)		; by calculating it
	scf
	sbc hl, de		
	ld (INTERPWKSPC+OFFSET_LENGTH), hl	; prog + vars
	ld hl, (ZX_VARS)		; now save the length - vars
	sbc hl, de			; calculate it...
	ld (INTERPWKSPC+OFFSET_PARAM2), hl
	pop bc				; retrieve filename
	pop de
	call F_tbas_writefile		; Write it out.
	jp c, J_tbas_error
	jp EXIT_SUCCESS

;----------------------------------------------------------------------------
; F_tbas_ls
; List a directory
; Two forms - either %cat or %cat "directory"
.globl F_tbas_ls
F_tbas_ls:
	cp 0x0d
	jr z, .noargs8
	cp ':'
	jr z, .noargs8
	
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
	jp F_listdir

.noargs8:
	call STATEMENT_END
	
	; --------- runtime ----------
	ld a, '.'
	ld (INTERPWKSPC), a		; default directory is CWD
	xor a
	ld (INTERPWKSPC+1), a
	ld hl, INTERPWKSPC
.makecat8:
	jp F_listdir

;---------------------------------------------------------------------------
; F_tbas_tapein
; Handle the %tapein command, which takes a filename as a parameter.
.globl F_tbas_tapein
F_tbas_tapein:
	rst CALLBAS
	defw ZX_EXPT_EXP		; expect a string expression
	call STATEMENT_END
	
	;-------- runtime --------
	rst CALLBAS
	defw ZX_STK_FETCH		; get the string
	call F_settrap
	jp c, J_tbas_error		; carry set = error
	jp EXIT_SUCCESS

;----------------------------------------------------------------------------
; F_tbas_info
; Handle the %info command
.globl F_tbas_info
F_tbas_info:
	rst CALLBAS
	defw ZX_EXPT_EXP		; expect a string
	call STATEMENT_END

	;-------- runtime ----------
	rst CALLBAS
	defw ZX_STK_FETCH
	call F_showfileinfo		; Try to open the file and show
	jp c, J_tbas_error		; the information.
	jp EXIT_SUCCESS

;----------------------------------------------------------------------------
; F_tbas_fs
; Sets the current filesystem.
.globl F_tbas_fs
F_tbas_fs:
	rst CALLBAS
	defw ZX_EXPT1_NUM		; expect one number - the FS number
	call STATEMENT_END

	;-------- runtime ----------
	rst CALLBAS
	defw ZX_FIND_INT2		; get the fs number
	ld a, c				; get it from BC
	call SETMOUNTPOINT
	jp nc, EXIT_SUCCESS		; No carry = FS change OK
	ld a, EBADFS
	jp J_tbas_error

;----------------------------------------------------------------------------
; F_loadsnap
; Loads a snapshot file.
.globl F_loadsnap
F_loadsnap:
	rst CALLBAS
	defw ZX_EXPT_EXP		; filename string
	call STATEMENT_END

	;---------- runtime -----------
	rst CALLBAS
	defw ZX_STK_FETCH		; get the filename
	ld hl, INTERPWKSPC+256
	call F_basstrcpy		; copy filename as a C string
	ld de, INTERPWKSPC+256
	ld hl, 0xFB01			; Module ID = 0xFB, call ID = 0x01
	rst MODULECALL_NOPAGE
	jp J_tbas_error			; If we get here, an error occurred

;----------------------------------------------------------------------------
; F_tbas_mv
; Moves (renames) a file.
.globl F_tbas_mv
F_tbas_mv:
	rst CALLBAS
	defw ZX_EXPT_EXP		; source filename
	cp ','				; and a comma	
	jp nz, PARSE_ERROR
	rst CALLBAS
	defw ZX_NEXT_CHAR		; advance past ,

	rst CALLBAS
	defw ZX_EXPT_EXP		; destination filename
	call STATEMENT_END		; then the end of statement

	;------- runtime ---------
	rst CALLBAS
	defw ZX_STK_FETCH		; destination filename
	ld hl, INTERPWKSPC+256
	call F_basstrcpy		; copy to workspace as C string
	rst CALLBAS
	defw ZX_STK_FETCH		; source filename
	ld hl, INTERPWKSPC
	call F_basstrcpy		; copy to workspace
	ld hl, INTERPWKSPC		; source and dest filename pointers
	ld de, INTERPWKSPC+256
	call RENAME
	jp nc, EXIT_SUCCESS
	jp J_tbas_error

;---------------------------------------------------------------------------
; F_tbas_rm: Removes a file
.globl F_tbas_rm
F_tbas_rm:
	rst CALLBAS
	defw ZX_EXPT_EXP		; file to remove
	call STATEMENT_END

	;-------- runtime ---------
	call F_get_stringarg
	call UNLINK			; remove the file
	jp nc, EXIT_SUCCESS
	jp J_tbas_error

;----------------------------------------------------------------------------
; F_tbas_mkdir: Makes a directory
.globl F_tbas_mkdir
F_tbas_mkdir:
	rst CALLBAS
	defw ZX_EXPT_EXP		; directory to create
	call STATEMENT_END
	
	; ------- runtime ------
	call F_get_stringarg
	call MKDIR
	jp nc, EXIT_SUCCESS
	jp J_tbas_error

;----------------------------------------------------------------------------
; F_tbas_rmdir: Makes a directory
.globl F_tbas_rmdir
F_tbas_rmdir:
	rst CALLBAS
	defw ZX_EXPT_EXP		; directory to create
	call STATEMENT_END
	
	; ------- runtime ------
	call F_get_stringarg
	call RMDIR
	jp nc, EXIT_SUCCESS
	jp J_tbas_error

;----------------------------------------------------------------------------
; F_tbas_zxprint
; Prints a C string to the current ZX channel
; HL = pointer to string 
.globl F_tbas_zxprint
F_tbas_zxprint:
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
.globl J_tbas_error
J_tbas_error:
	push af				; save error number
	call F_geterrstr		; get the error string
	pop af
	jp REPORTERR			; exit to BASIC with error string

;----------------------------------------------------------------------------
; F_tnfs_geterrstr
; Enter with A=error number
; Exits with HL=pointer to null terminated error string
.globl F_geterrstr
F_geterrstr:
	ld h, 0xFC		; ID of messages module
	ld l, a			; Set the message ID to fetch
	ld de, 0x3000		; buffer
	xor a
	ld (de), a		; initialize with a NULL
	rst MODULECALL_NOPAGE
	ld hl, 0x3000		; address of the message
	ret

;---------------------------------------------------------------------------
; F_get_stringarg: gets a single string arg, returning a pointer to the
; null-terminated string in HL
F_get_stringarg:
	rst CALLBAS
	defw ZX_STK_FETCH
	ld hl, INTERPWKSPC
	call F_basstrcpy
	ld hl, INTERPWKSPC
	ret

.data
.globl STR_BOOTDOTZX
.globl STR_BOOTDOTZXLEN
STR_proto:	defb	"tnfs",0
STR_BOOTDOTZX:	defb	"boot.zx",0
STR_BOOTDOTZXEND:

STR_BOOTDOTZXLEN equ	STR_BOOTDOTZXEND-STR_BOOTDOTZX

EBADURL:		equ	0x28
EBADFS:		equ	0x29

