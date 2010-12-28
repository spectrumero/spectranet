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
.include	"zxrom.inc"
.include	"spectranet.inc"
.include	"sysvars.inc"
.include	"configdefs.inc"
.text
; Simple BASIC interface to allow the setting/getting of config values.
; The format of all set commands is:
; %cfgset section,id,value
; %cfgset$ section,id,"string"
; The format of all get commands is:
; %cfgget section,id
; To commit, %cfgcommit, to abandon, %cfgabandon
;--------------------------------------------------------------------------
; F_cfgcommit. Takes no args. Commits configuration to flash.
.globl F_cfgcommit
F_cfgcommit: 
	call STATEMENT_END

	; runtime
	call F_commitConfig
	jp c, F_handle_error
	jp EXIT_SUCCESS

;--------------------------------------------------------------------------
; F_cfgabandon. Abandons RAM copy of configuration.
.globl F_cfgabandon
F_cfgabandon: 
	call STATEMENT_END

	; runtime
	call F_abandonConfig
	jp EXIT_SUCCESS

;--------------------------------------------------------------------------
; F_cfgset
; Sets byte and word values
.globl F_cfgset
F_cfgset: 
	; Syntax check time
	call F_cfgset_common

	rst CALLBAS
	defw ZX_NEXT_CHAR
	rst CALLBAS		; check for value (integer)
	defw ZX_EXPT1_NUM

	call STATEMENT_END

	; Runtime
	rst CALLBAS
	defw ZX_FIND_INT2	; get value
	push bc
	rst CALLBAS
	defw ZX_FIND_INT2
	push bc
	rst CALLBAS
	defw ZX_FIND_INT2
	push bc
	ld ix, 0		; point IX at params
	add ix, sp
	ld a, (ix+2)		; check argument
	and 0xC0
	cp 0xC0			; word?
	jp z, F_do_cfgset_word
	cp 0x80			; byte?
	jp z, F_do_cfgset_byte
	
	; todo: error
	jp J_badid

;--------------------------------------------------------------------------
; F_cfgset_string
; Sets a string
.globl F_cfgset_string
F_cfgset_string: 
	; Syntax check time
	call F_cfgset_common

	rst CALLBAS
	defw ZX_NEXT_CHAR
	rst CALLBAS		; check for string value
	defw ZX_EXPT_EXP

	call STATEMENT_END

	; runtime
	rst CALLBAS
	defw ZX_STK_FETCH	; get string
	ld hl, INTERPWKSPC
	push hl
	call F_basstrcpy
	rst CALLBAS		; get string ID
	defw ZX_FIND_INT2
	push bc
	rst CALLBAS		; get section ID
	defw ZX_FIND_INT2
	push bc
	ld ix, 0
	add ix, sp		; set IX to point at block
	jp F_do_cfgset_string

;--------------------------------------------------------------------------
; Common syntax checks
.globl F_cfgset_common
F_cfgset_common: 
	rst CALLBAS
	defw ZX_EXPT1_NUM	; check for section ID
	cp ','			; comma
	jp nz, PARSE_ERROR

	rst CALLBAS
	defw ZX_NEXT_CHAR
	rst CALLBAS		; check for entry ID
	defw ZX_EXPT1_NUM
	cp ','			; comma
	jp nz, PARSE_ERROR
	ret

;--------------------------------------------------------------------------
; F_prepwrite
; Actions that have to be done for any writeable cfg item.
; Section to use in DE
.globl F_prepwrite
F_prepwrite: 
	call F_cond_copyconfig
	ld d, (ix+1)
	ld e, (ix+0)
	call F_findsection
	ret
	
;--------------------------------------------------------------------------
; F_do_cfgset_byte
; IX points to a structure containing:
; IX+0 = section
; IX+3 = id
; IX+4 = value or pointer to string
; note all values are 16 bit
.globl F_do_cfgset_byte
F_do_cfgset_byte: 
	call F_prepwrite
	jp c, F_handle_error
	ld a,(ix+2)
	ld c,(ix+4)
	call F_setCFByte_dct
	jp EXIT_SUCCESS

.globl F_do_cfgset_word
F_do_cfgset_word: 
	call F_prepwrite
	jr c, F_handle_error
	ld a,(ix+2)
	ld c,(ix+4)
	ld b,(ix+5)
	call F_setCFWord_dct
	jp EXIT_SUCCESS

.globl F_do_cfgset_string
F_do_cfgset_string: 
	call F_prepwrite
	jr c, F_handle_error
	ld a,(ix+2)
	ld e,(ix+4)
	ld d,(ix+5)
	call F_setCFString_dct
	jp EXIT_SUCCESS

;-------------------------------------------------------------------------
; F_cfgnew
; Create a brand new config (wiping any that may already exist)
.globl F_cfgnew
F_cfgnew: 
	; Syntax time
	call STATEMENT_END	; no args

	; Run time
	call F_cond_copyconfig	; not necessary to actually copy it but
				; this sets up sysvars ready so we can commit
	call F_createnewconfig	; overwrite whatever's already there with
	jp EXIT_SUCCESS		; a new config.

;------------------------------------------------------------------------
; F_cfgnewsec
; Create a new section with the ID supplied.
.globl F_cfgnewsec
F_cfgnewsec: 
	; Syntax time
	rst CALLBAS
	defw ZX_EXPT1_NUM	; expect a single 16 bit number
	call STATEMENT_END

	; run time
	call F_cond_copyconfig	; ensure config is in RAM
	rst CALLBAS		; get the argument
	defw ZX_FIND_INT2	; which is now in BC.
	ld d, b
	ld e, c
	call F_createsection
	jp EXIT_SUCCESS

;-------------------------------------------------------------------------
; F_cfgrm
; Removes the id passed from the section
.globl F_cfgrm
F_cfgrm:
	; syntax time
	rst CALLBAS
	defw ZX_NEXT2_NUM	; Command is "section, item"
	call STATEMENT_END

	; runtime
	call F_mappage
	call F_cond_copyconfig
	rst CALLBAS
	defw ZX_FIND_INT2
	push bc			; save the config item ID
	rst CALLBAS
	defw ZX_FIND_INT2
	ld d, b			; transfer BC to DE, the section ID
	ld e, c
	call F_findsection
	pop bc
	jr c, F_handle_error
	ld a, c			; get the LSB (= the id to remove)
	call F_rmcfgitem_core
	call F_leave
	jr c, F_handle_error
	jp EXIT_SUCCESS
	
;-------------------------------------------------------------------------
        ; Copy a BASIC string to a C string.
        ; BASIC string in DE, C string (dest) in HL
.globl F_basstrcpy
F_basstrcpy: 
        ld a, b                         ; end of string?
        or c
        jr z,  .terminate12
        ld a, (de)
        ld (hl), a
        inc hl
        inc de
        dec bc
        jr F_basstrcpy
.terminate12: 
        xor a                           ; put the null on the end
        ld (hl), a
        inc hl
        ret

.globl F_handle_error
F_handle_error: 
	; TODO: integrate with messages module
	ld hl, STR_cfgerr
	jp REPORTERR
J_badid:
	ld hl, STR_badid
	jp REPORTERR

.data
STR_cfgerr:
	defb "Configuration error",0
STR_badid:
	defb "Bad config ID",0
