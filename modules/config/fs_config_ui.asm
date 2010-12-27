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
.include	"spectranet.inc"
.include	"ctrlchars.inc"
.include	"flashconf.inc"
.include	"sysvars.inc"
.include	"automount.inc"
.include	"stdmodules.inc"

.text
;---------------------------------------------------------------------------
; Handle BASIC entry/exit
.globl F_start
F_start: 
	call STATEMENT_END

	; runtime
	call F_fsconfigmain
	jp EXIT_SUCCESS

;---------------------------------------------------------------------------
; Main configuration menu.
.globl F_fsconfigmain
F_fsconfigmain: 
	call F_cond_copyconfig
.fsconfigloop2: 
	call CLEAR42
	call F_showconfig

	ld hl, STR_separator
	call PRINT42

	ld hl, MENU_setfs
	call F_genmenu
	ld hl, MENU_setfs
	call F_getmenuopt
	jr z,  .fsconfigloop2	; user has not finished
	ret

;--------------------------------------------------------------------------
; F_showconfig
; Shows the current configuration.
F_showconfig:
	call F_cond_copyconfig
	ld de, AM_CONFIG_SECTION
	call F_findsection
	jr c, .makesection
.continue:
	ld b, AM_MAX_FS			; number of times to loop
	ld a, AM_FS0			; FS number to start with
.disploop:
	push bc
	ld (AM_ASAVE), a
	ld hl, STR_fsnum
	call PRINT42
	ld a, (AM_ASAVE)
	add a, '0'
	call PUTCHAR42
	ld a, NEWLINE
	call PUTCHAR42

	ld a, (AM_ASAVE)		; Now get the existing FS details
	ld de, AM_WORKSPACE_URL
	call F_getCFString_dct
	jr c, .nothing
	ld hl, AM_WORKSPACE_URL
	call PRINT42
	ld a, NEWLINE
	call PUTCHAR42

.disploop1:
	ld a, (AM_ASAVE)
	inc a
	ld (AM_ASAVE), a
	pop bc
	djnz .disploop	

.showboot:
	ld hl, STR_bootflag
	call PRINT42
	ld a, AM_AUTOBOOT
	call F_getCFByte_dct
	and a				; zero or 1?
	jr z, .zero
	ld hl, STR_yes
	call PRINT42
	ret
.zero:
	ld hl, STR_no
	call PRINT42
	ret

.nothing:
	ld hl, STR_unset
	call PRINT42
	jr .disploop1

.makesection:
	ld de, AM_CONFIG_SECTION
	call F_createsection
	ld de, AM_CONFIG_SECTION
	call F_findsection
	jr c, .fatalerror
	jr .continue
.fatalerror:
	ld hl, STR_createfail
	call PRINT42
	ret

;-------------------------------------------------------------------------
; F_geturl
; Asks for a filesystem url.
F_geturl:
	ld hl, STR_geturl
	call PRINT42
	ld c, 40		; allow up to 40 chars
	ld de, AM_WORKSPACE_URL	; where to store
	call INPUTSTRING
	ld a, (AM_WORKSPACE_URL)
	and a			; user abandoned?
	jr z,  .abandonurl
	ld ix, AM_WORKSPACE_MOUNT
	ld hl, PARSEURL		; make sure the URL is valid
	rst MODULECALL_NOPAGE
	ret nc			; URL is OK.
	ld hl, STR_invalidurl
	call PRINT42
	jr F_geturl

.abandonurl:
	scf
	ret

;------------------------------------------------------------------------
; F_seturl
F_seturl:
	call F_askfsnum	
	ret c
	call F_geturl
	ret c
.urlcont:
	ld a, (AM_ASAVE)
	ld de, AM_WORKSPACE_URL	; pointer to the URL
	call F_setCFString_dct	; set the string
	jr c, .unable
	xor a			; set zero flag
	ret

.unable:
	ld hl, STR_unable
	call PRINT42
	xor a			; set zero flag
	ret

;--------------------------------------------------------------------------
; F_unset_url
F_unset_url:
	call F_askfsnum
	ret c

	ld a, (AM_ASAVE)
	call F_rmcfgitem_dct
	jr c, .unable
	xor a			; set zero flag
	ret

;--------------------------------------------------------------------------
; F_setboot: Sets/resets autoboot
F_setboot:
	ld a, AM_AUTOBOOT		; byte id
	call F_getCFByte_dct
	jr nc, .setup		; set it up if it's not set already
	xor a			; reset A if it's not set
.setup:
	xor 1			; flip the bottom bit
	ld c, a
	ld a, AM_AUTOBOOT
	call F_setCFByte_dct
	xor a			; set Z flag
	ret

;--------------------------------------------------------------------------
; F_saveexit
F_saveexit:
	ld hl, STR_committing
	call PRINT42
	call F_commitConfig
	jr c, .commitfail
	ld hl, STR_committed
	call PRINT42
	or 1			; make sure Z is reset
	ret
.commitfail:
	ld hl, STR_commitfail
	call PRINT42
	or 1
	ret
F_abandon:
	call F_abandonConfig
	ld hl, STR_abandoned
	call PRINT42
	or 1			; make sure Z is reset
	ret

;----------------------------------------------------------------------------
; F_askfsnum: Ask the user to enter a filesystem number.
.globl F_askfsnum
F_askfsnum: 
	ld hl, STR_fsnum
	call PRINT42
	ld c, 2			; Only one character
	ld de, AM_ASAVE		; place to store the answer
	call INPUTSTRING
	ld a, (AM_ASAVE)
	and a			; user abandoned?
	jr z,  .abandon16
	sub '0'			; convert to int
	cp 4
	jr nc,  .invalid16	; too big!
	ld (AM_ASAVE), a
	and a			; reset carry
	ret

.invalid16: 
	ld hl, STR_invalidfs
	call PRINT42
	jr F_askfsnum

.abandon16: 
	scf
	ret
	
; Menu definitions
.data
MENU_setfs:
	defw	STR_seturl, F_seturl
	defw	STR_unseturl, F_unset_url
	defw	STR_setboot, F_setboot
	defw	STR_saveexit, F_saveexit
	defw	STR_abandon, F_abandon
	defw	0,0

