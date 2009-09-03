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
	ld de, INTERPWKSPC+10		; where to put the strings
	ld (INTERPWKSPC), de		; set pointer
	ld hl, STR_proto		; TODO: take multiple protos
	ld bc, 5			; length of "tnfs",0
	ldir
	ex de, hl

	push hl
	rst CALLBAS
	defw ZX_STK_FETCH		; path string
	pop hl
	ld (INTERPWKSPC+4), hl		; pointer to path string
	call F_basstrcpy		; copy string from BASIC
	
	push hl
	rst CALLBAS
	defw ZX_STK_FETCH
	pop hl
	ld (INTERPWKSPC+2), hl		; hostname
	call F_basstrcpy		; copy the string

	push hl
	rst CALLBAS
	defw ZX_STK_FETCH
	pop hl
	ld (INTERPWKSPC+8), hl		; passwd
	call F_basstrcpy		; copy the hostname

	push hl
	rst CALLBAS
	defw ZX_STK_FETCH
	pop hl
	ld (INTERPWKSPC+6), hl		; username
	call F_basstrcpy		; done!
.mount
	ld ix, INTERPWKSPC		; mount structure address
	xor a				; TODO: More mount points
	call MOUNT
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
	ld a, (v_vfs_curmount)
	call UMOUNT
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
	call CHDIR
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
	cp TOKEN_CODE			; Check for CODE...
	jr z, .loadcode
	call STATEMENT_END		; If not, statment end for BASIC.

	;------ runtime for BASIC ------
	xor a				; type 0x00 is BASIC
.loader
	push af				; save type
	rst CALLBAS
	defw ZX_STK_FETCH		; fetch the filename
	ld hl, INTERPWKSPC
	call F_basstrcpy		; copy + convert to C string

	; Now call the loader routine with the filename in HL
	ld hl, INTERPWKSPC
	pop af				; get type id
	call F_tbas_loader
	jp c, J_tbas_error
	jp EXIT_SUCCESS

.loadcode
	; TODO - code to a specific address.
	rst CALLBAS
	defw ZX_NEXT_CHAR
	call STATEMENT_END

	;------ runtime for CODE with no addr -------
	ld a, 3				; type=CODE
	jr .loader			; get the filename then load.

;----------------------------------------------------------------------------
; F_tbas_save: Save a ZX file (BASIC, CODE etc.)
; The syntax is as for ZX BASIC SAVE.
; TODO: CODE et al.
F_tbas_save
	rst CALLBAS
	defw ZX_EXPT_EXP		; fetch the file name
	cp TOKEN_CODE			; for CODE
	jr z, .savecode
	cp TOKEN_SCREEN			; for SCREEN$
	jr z, .savescreen	
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
	pop bc				; retrieve the filename
	pop de
	call F_tbas_writefile		; Write it out.
	jp c, J_tbas_error
	jp EXIT_SUCCESS

	; Deal with SAVE "filename" CODE
.savecode
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
.savecodemain
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
	
.savescreen
	rst CALLBAS
	defw ZX_NEXT_CHAR		; advance to the end of the line
	call STATEMENT_END
	
	; Runtime
	ld hl, 6912			; Put the length of a SCREEN$
	push hl				; on the stack
	ld hl, 16384			; followed by the start address
	push hl
	jr .savecodemain		; and do as for CODE
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
	ld a, '.'
	ld (INTERPWKSPC), a		; default directory is CWD
	xor a
	ld (INTERPWKSPC+1), a
	ld hl, INTERPWKSPC
.makecat
	call OPENDIR			; open the directory
	jp c, J_tbas_error
	ld (v_vfs_dirhandle), a		; save the directory handle
	ld a, 2	
	rst CALLBAS			; set channel to 2
	defw 0x1601
.catloop
	ld a, (v_vfs_dirhandle)		; get the dir handle back
	ld de, INTERPWKSPC		; location for result
	call READDIR			; read dir
	jr c, .readdone			; read is probably at EOF
	ld hl, INTERPWKSPC
	call F_tbas_zxprint		; print a C string to #2
	ld a, '\r'			; newline
	rst CALLBAS
	defw 0x10
	jr .catloop
.readdone
	push af				; save error code while
	ld a, (v_vfs_dirhandle)		; we close the dir handle
	call CLOSEDIR
	pop hl				; pop into hl to not disturb flags
	jp c, J_tbas_error		; report any error
	ld a, h				; get original error code
	cp EOF				; EOF is good
	jp nz, J_tbas_error		; everything else is bad, report it
	jp EXIT_SUCCESS

;---------------------------------------------------------------------------
; F_tbas_tapein
; Handle the %tapein command, which takes a filename as a parameter.
F_tbas_tapein
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
F_tbas_info
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
	call F_geterrstr		; get the error string
	pop af
	jp REPORTERR			; exit to BASIC with error string

;----------------------------------------------------------------------------
; F_tnfs_geterrstr
; Enter with A=error number
; Exits with HL=pointer to null terminated error string
F_geterrstr
	ld hl, STR_SUCCESS	; pointer at start of table
	and a			; code 0 (success?)
	ret z			; return now.
	ld d, a			; set counter
	xor a			; reset A to search for terminator
	ld bc, ERR_TABLE_END - STR_SUCCESS
.findloop
	cpir			; find next null
	ret po			; cpir ran out of data?
	dec d			; decrement loop counter
	jr nz, .findloop	; if Z is not set go for another run
	ret z			; HL now points at error string

STR_proto	defb	"tnfs",0

STR_SUCCESS	defb	"Success",0				; 0x00
STR_EPERM	defb	"Operation not permitted",0		; 0x01
STR_ENOENT	defb	"No such file or directory",0		; 0x02
STR_EIO		defb	"I/O error",0				; 0x03
STR_ENXIO	defb	"No such device or address",0		; 0x04
STR_E2BIG	defb	"Too many arguments",0			; 0x05
STR_EBADF	defb	"Bad file descriptor",0			; 0x06
STR_EAGAIN	defb	"Operation would block",0		; 0x07
STR_ENOMEM	defb	"Out of memory",0			; 0x08
STR_EACCES	defb	"Permission denied",0			; 0x09
STR_EBUSY	defb	"Device or resource busy",0		; 0x0A
STR_EEXIST	defb	"File exists",0				; 0x0B
STR_ENOTDIR	defb	"Not a directory",0			; 0x0C
STR_EISDIR	defb	"Is a directory",0			; 0x0D
STR_EINVAL	defb	"Invalid argument",0			; 0x0E
STR_ENFILE	defb	"File table overflow",0			; 0x0F
STR_EMFILE	defb	"Too many open files",0			; 0x10
STR_EFBIG	defb	"File too large",0			; 0x11
STR_ENOSPC	defb	"Filesystem full",0			; 0x12
STR_ESPIPE	defb	"Attempt to seek on a pipe",0		; 0x13
STR_EROFS	defb	"Read only filesystem",0		; 0x14
STR_ENAMETOOLONG defb	"Filename too long",0			; 0x15
STR_ENOSYS	defb	"Not implemented",0			; 0x16
STR_ENOTEMPTY	defb	"Directory not empty",0			; 0x17
STR_ELOOP	defb	"Too many links",0			; 0x18
STR_ENODATA	defb	"No data available",0			; 0x19
STR_ENOSTR	defb	"Out of streams",0			; 0x1A
STR_EPROTO	defb	"Protocol error",0			; 0x1B
STR_EBADFD	defb	"File descriptor state bad",0		; 0x1C
STR_EUSERS	defb	"Too many users",0			; 0x1D
STR_ENOBUFS	defb	"No buffer space available",0		; 0x1E
STR_EALREADY	defb	"Operation already running",0		; 0x1F
STR_ESTALE	defb	"Stale TNFS handle",0			; 0x20
STR_EOF		defb	"End of file",0				; 0x21

; Non-protocol error messages
STR_TIMEOUT	defb	"Operation timed out",0			; 0x22
STR_NOTMOUNTED	defb	"Filesystem not mounted",0		; 0x23
STR_BADLENGTH	defb	"Incorrect header length",0		; 0x24
STR_BADTYPE	defb	"Incorrect block type",0		; 0x25
STR_UNKTYPE	defb	"Unknown file type",0			; 0x26
STR_MISMCHLEN	defb	"Data block length mismatch",0		; 0x27

ERR_TABLE_END
STR_UNKNOWN	defb	"Unknown error",0

