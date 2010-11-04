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
	ld a, 0x1D		; first configuration table
	ld (v_workspace), a
.fsconfigloop2: 
	call CLEAR42
	call F_showfs
	ld hl, MENU_setfs
	call F_genmenu
	ld hl, MENU_setfs
	call F_getmenuopt
	jr z,  .fsconfigloop2	; user has not finished
	ret

;---------------------------------------------------------------------------
; F_showfs
; Shows details of two mountpoints.
.globl F_showfs
F_showfs: 
	ld a, (v_workspace)	; form the base address
	ld h, a
	ld l, 0x00		; HL = 0x10..
	sub 0x1D		; calculate fs number for display
	rlca
	push af
	call F_showconfig
	ld hl, (v_hlsave)	; retrieve original base address
	ld l, 0x80		; set to second config
	pop af
	inc a
	call F_showconfig
	ret

;---------------------------------------------------------------------------
; F_showconfig
; Shows a configuration. (A tedious routine...)
; HL = base address of configuration set.
; A = intended mount point
.globl F_showconfig
F_showconfig: 
	push af
	ld (v_hlsave), hl	; keep a copy
	ld hl, STR_curfs
	call PRINT42
	pop af			; get mount point back
	add a, '0'		; turn it into a number
	call PUTCHAR42
	call F_cr

	ld hl, STR_proto	; print "Proto:"
	call PRINT42
	ld hl, (v_hlsave)
	inc l			; proto = base +1
	call F_printifset

	ld hl, STR_host		; Hostname
	call PRINT42
	ld hl, (v_hlsave)	; calculate the address of the config item
	ld de, DEF_FS_HOST0 % 256
	add hl, de
	call F_printifset

	ld hl, STR_rempath	; Path on server
	call PRINT42
	ld hl, (v_hlsave)
	ld de, DEF_FS_SRCPTH0 % 256
	add hl, de
	call F_printifset

	ld hl, STR_user
	call PRINT42
	ld hl, (v_hlsave)
	ld de, DEF_FS_USER0 % 256
	add hl, de
	call F_printifset
	jp F_cr
	

;---------------------------------------------------------------------------
; F_printifset: Only prints the item if it's actually set to something.
.globl F_printifset
F_printifset: 
	ld a, (hl)
	cp 0xFF			; Not set at all?
	jr z,  .notset5
	and a			; Set to null?
	jr nz,  .printit5
	ld hl, STR_null
	jr  .printit5
.notset5: 
	ld hl, STR_unset
.printit5: 
	call PRINT42
.globl F_cr
F_cr: 
	ld a, NEWLINE
	jp PUTCHAR42


; Menu definitions
MENU_setfs:
	defw	STR_show0and1, F_show0and1
	defw	STR_show1and2, F_show1and2
	defw	STR_chgproto, F_chgproto
	defw	STR_chghost, F_chghost
	defw	STR_chgpath, F_chgrempath
	defw	STR_chguser, F_chguserpasswd
	defw	STR_saveexit, F_saveexit
	defw	STR_abandon, F_abandon
	defw	0,0

;----------------------------------------------------------------------------
; F_show0and1
; Show details for FS0 and FS1
.globl F_show0and1
F_show0and1: 
	ld a, 0x1D		; MSB for FS0
	ld (v_workspace), a
	xor a			; set zero flag
	ret
.globl F_show1and2
F_show1and2: 
	ld a, 0x1E		; MSB for FS2A
	ld (v_workspace), a
	xor a
	ret

.globl F_chgproto
F_chgproto: 
	call F_askfsnum
	jr c, zeroexit		; user abandoned
	push hl
	ld hl, STR_proto	; question we want to ask
	ld de, DEF_FS_PROTO0 % 256	; requested address
	ld c, 6			; max size
	jp F_getprotostring

.globl F_chghost
F_chghost: 
	call F_askfsnum
	jr c, zeroexit		; user abandoned
	push hl
	ld hl, STR_host		; question we want to ask
	ld de, DEF_FS_HOST0 % 256	; requested address
	ld c, 41		; max size
	jp F_getprotostring

.globl F_chgrempath
F_chgrempath: 
	call F_askfsnum
	jr c, zeroexit		; user abandoned
	push hl
	ld hl, STR_rempath	; question we want to ask
	ld de, DEF_FS_SRCPTH0 % 256	; requested address
	ld c, 48		; max size

.globl F_getprotostring
F_getprotostring: 
	call F_cr		; carriage return
	call PRINT42		; print requested string
	pop hl			; get the base address
	add hl, de		; calculate address of protocol string
	ex de, hl
	call INPUTSTRING
zeroexit:
	xor a			; set Z
	ret

.globl F_chguserpasswd
F_chguserpasswd: 
	call F_askfsnum
	jr c, zeroexit
	push hl
	ld hl, STR_user
	ld de, DEF_FS_USER0 % 256
	ld c, 16
	call F_cr		; carriage return
	call PRINT42		; print requested string
	pop hl			; get the base address
	push hl			; save it for passwd
	add hl, de		; calculate address of protocol string
	ex de, hl
	call INPUTSTRING
	ld hl, STR_passwd
	ld de, DEF_FS_PASSWD0 % 256
	ld c, 16
	jp F_getprotostring	; will pop HL
	
.globl F_saveexit
F_saveexit: 
	ld hl, STR_updating
	call PRINT42

	; copy flash writer into RAM
	ld hl, FLASHPROGSTART
	ld de, 0x3000
	ld bc, FLASHPROGLEN
	ldir
	call 0x3000
	jr c, borked
	ld hl, STR_flashdone
	call PRINT42
.globl F_abandon
F_abandon: 
	or 1			; reset zero flag
	ret
borked:
	ld hl, STR_writebork
	call PRINT42
	jr F_abandon

;----------------------------------------------------------------------------
; F_askfsnum: Ask the user to enter a filesystem number.
.globl F_askfsnum
F_askfsnum: 
	ld hl, STR_fsnum
	call PRINT42
	ld c, 2			; Only one character
	ld de, v_workspace+1	; place to store the answer
	call INPUTSTRING
	ld a, (v_workspace+1)
	and a			; user abandoned?
	jr z,  .abandon16
	sub '0'			; convert to int
	cp 4
	jr nc,  .invalid16		; too big!
	ccf			; reset carry
	ld l, 0			; set LSB
	rra			; half and set carry if odd
	rr l			; and suck into msb of L
	add a, 0x1D		; set MSB
	ld h, a			; HL now points at base address
	ret

.invalid16: 
	ld hl, STR_invalidfs
	call PRINT42
	jr F_askfsnum

.abandon16: 
	scf
	ret
	
