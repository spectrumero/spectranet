;The MIT License
;
;Copyright (c) 2008 Dylan Smith
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

; BASIC extensions.
; Checking for extensions is performed here, but the page 0 ROM does
; not actually extend BASIC. The routines are provided for other code
; to extend BASIC.
;
; BASIC sets the IY flag to point to the system variables area, this
; is used extensively to examine flags and sysvars. The tokens 'D_xxx'
; are a displacement for (iy+d) operations.
;
; Credits - Garry Lancaster for pointers on how the ZX error
; handler works and some sample code.
; Melbourne House for the Complete Shadow ROM disassembly, which was very
; instructive in this endeavour.
;---------------------------------------------------------------------------
; F_addbasext: Adds a new BASIC command or extension.
; Parameters: HL = pointer to info table for new command.
; The table is formatted as follows, and is 6 bytes long:
;  byte 0   - ZX error code that's relevant to the command
;  byte 1,2 - pointer to command string
;  byte 3   - ROM page (0 if none)
;  byte 4,5 - pointer to routine to call
; Carry flag is set if we have run out of space.
F_addbasicext
	ld de, (v_tabletop)	; get the current table pointer
	ld a, 0xFB		; last byte possible
	cp e
	ret c			; e > a
	ld bc, 6		; 6 bytes
	ldir
	ld (v_tabletop), de	; save new table pointer
	dec de
	dec de
	dec de			; point DE at the page byte
	ex de, hl
	ld a, (hl)
	cp 0xFF			; if it's 0xFF then we find the ROM page
	ccf
	ret nz
	ld a, (v_pgb)		; copy the currently paged page
	ld (hl), a
	and a			; reset carry flag
	ret

;---------------------------------------------------------------------------
; The main RST 8 error recovery handler.
; This is jumped to when RST 8 is trapped, and looks to see if the ROM
; has passed us something of interest.
; Note that changing the Spectranet system variable 'v_rst8vector' allows
; you to completely replace this routine with something else.
J_rst8handler
	ld a, (v_tabletop)	; Check there's something to do
	and a			; if the LSB of tabletop is 0, nothing to do
	jp z, J_rst8done
	ex de, hl		; address of code is in DE
	rst CALLBAS
	defw ZX_GET_ERR		; get the error code (which may be in ZX ROM)
	cp 0x0B			; Nonsense in BASIC?
	jr z, .handled
	cp 0x0E			; Invalid filename?
	jr z, .handled
	cp 0x17			; Invalid stream?
	jr z, .handled
	cp 0x12			; Bad device?
	jp nz, J_rst8done
.handled
	ld (ZX_ERR_NR), a	; Save the error number in ZX sysvars
	ld (v_errnr_save), a	; and ours.
	ld hl, (ZX_CH_ADD)	; save current CH_ADD
	ld (v_chaddsave), hl
	pop af			; discard top value of the stack
	bit 5, (iy + D_FLAGX)	; Input mode?
	jp nz, J_romerr
	ld a, (v_interpflags)	; Check our flags
	bit 0, a		; This is set to 1 if we are running our cmds
	jp nz, J_romerr		; so we shouldn't really get here.
	or 1			; set 'our command' flag
	ld (v_interpflags), a
	bit 7, (iy + D_FLAGS)	; Syntax time or runtime?
	jr nz, .runtime
	ld a, 0xFF		; signal syntax time 
	ld (ZX_PPC_HI), a
.runtime
	ld b, (iy + D_SUBPPC)	; Statement counter
	ld c, 0			; Quote mark counter
	bit 7, (iy + D_PPC_HI)	; Program area?
	jr z, .progline
	push bc			; Save counters
	rst CALLBAS
	defw ZX_E_LINE_NO	; Call E_LINE_NO to update CH_ADD to 1st char
	pop bc
	rst CALLBAS
	defw ZX_GET_CHAR	; HL=first char in line	
	jr .sstat		; jump forward to the DJNZ
	; the following mess sorts out rewinding CH_ADD and removing
	; floating point values.
.progline
	ld hl, (ZX_PROG)	; get address of program
.sc_l_loop
	ld a, (ZX_PPC_HI)	; compare with current line
	cp (hl)
	jr nc, .testlow		; jump if <= line to be searched for
.nreport1
	ld hl, STR_badcmd	; Return with our equiv of nonsense in BASIC
	ld a, 1
	jp J_reporterr
.testlow
	inc hl			; lsb of line number
	jr nz, .line_len	; jump if current line is not the expected one
	ld a, (ZX_PPC_LO)	; Compare the next byte
	cp (hl)
	jr c, .nreport1		; Error if the line does not exist
.line_len
	inc hl			; inc the pointer
	ld e, (hl)
	inc hl
	ld d, (hl)		; fetch length into DE
	inc hl			; point to the start of the line
	jr z, .sstat		; jump if the line is found
	add hl, de		; increment pointer to next line
	jr .sc_l_loop		; continue until found
.skip_num
	ld de, 0x06		; length of a float
	add hl, de		; skip the float
.each_st
	ld a, (hl)		; Get a char from the line
	cp 0x0E			; Number marker?
	jr z, .skip_num		; Skip the number
	inc hl			; point to next char
	cp '"'			; Quote symbol?
	jr nz, .chkend		; No
	dec c			; decrement " counter
.chkend
	cp ':'			; Colon?
	jr z, .chkeven		; Yes
	cp 0xCB			; THEN token?
	jr nz, .chkend_l
.chkeven
	bit 0, c		; Even number of " chars?
	jr z, .sstat		; Jump if the statement is finished
.chkend_l
	cp 0x80			; Line finished?
	jr nz, .each_st		; No, continue the loop
	jr .nreport1		; Give an error - wrong number of quotes
.sstat	
	djnz .each_st		; Continue with next stmt
	dec hl			; HL now points to start address of stmt
	ld (ZX_CH_ADD), hl	; store in CH_ADD
	bit 7, (iy + D_FLAGS)	; Checking syntax?
	jr nz, .cl_work
	bit 7, (iy + D_PPC_HI)	; Give error if line is not in editing area
	jp z, J_err_6

	; Remove all 6 byte FP numbers put in by the ZX ROM interpreter
	dec hl			; balance inc below
	ld c, 0			; clear C
.rcln_num
	inc hl			; Point to next char
	ld a, (hl)		; Get char
	cp 0x0E			; Start of a number?
	jr nz, .nextnum		; no
	push bc			; save BC
	rst CALLBAS		; call RECLAIM-2 in ZX ROM
	defw ZX_RECLAIM_2	; to reclaim the number
	push hl			; save the pointer to the number
	ld de, (v_chaddsave)	; jp forward if the 6 bytes were
	and a			; reclaimed after the char pointed to
	sbc hl, de		; in the saved CH_ADD
	jr nc, .nxt_1
	ex de, hl		; otherwise update saved ch_add
	ld bc, 6		; was moved 6 bytes down
	and a
	sbc hl, bc
	ld (v_chaddsave), hl	; save the new value
.nxt_1
	pop hl			; restore pointer and counter
	pop bc
.nextnum
	ld a, (hl)		; jump back until the line is finished
	cp 0x0D
	jr nz, .rcln_num
.cl_work			; Clear workspace
	rst CALLBAS
	defw ZX_SET_WORK	; ZX SET-WORK routine
	call F_parser		; If this returns, command not found.
J_err_6
	ld hl, (v_chaddsave)	; restore initial CH_ADD
	ld (ZX_CH_ADD), hl
	jp J_romerr		; Main rom error handler

;---------------------------------------------------------------------------
; J_rst8done
; Early escape from RST 8 routine when we've identified the error code
; isn't something we're interested in. It restores the stack and restarts
; the ZX ROM's RST8 routine.
J_rst8done
	ld hl, 0x000B		; return address, after 'ld hl, (CH_ADD)'
	ex (sp), hl		; put it on the stack, discarding old value
	ld hl, (ZX_CH_ADD)	; 1st instruction in ZX ROM RST8 routine
	jp UNPAGE

;---------------------------------------------------------------------------
; J_zxrom_exit
; This exits to the BASIC ROM, resetting our private flags.
; First stack entry should contain address where control should be returned.
J_zxrom_exit
	xor a
	ld (v_interpflags), a	; reset our flags
	jp UNPAGE

;--------------------------------------------------------------------------
; F_statement_end / J_exit_success
; This performs 'end of statement' actions. If the statment isn't actually
; ended it triggers the ROM error routine.
; Jumping in at J_exit_success performs the post-command actions.
F_statement_end
	cp 0x0D			; ZX char for enter
	jr z, .synorrun		; if so check for syntax or run time
	cp ':'			; The other statement end char is :
	jr z, .synorrun		; If neither, return with 'nonsense' code
	ld hl, STR_badcmd
	ld a, 1
	jp J_sherror
.synorrun
	bit 7, (iy + D_FLAGS)	; Syntax time or run time?
	ret nz			; Run time - return and allow exec actions.
J_exit_success
	ei			; ensure interrupts are enabled (else we hang)
	ld sp, (ZX_ERR_SP)	; restore the stack
	ld (iy + D_ERR_NR), 0xFF ; clear error status
	ld hl, ZX_STMT_NEXT	; return address in BASIC ROM
	bit 7, (iy + D_FLAGS)	; Syntax or run time?
	jr z, .syntaxtime	; Do the syntax time return action
	ld a, 0x7F		; Check for BREAK - port 0x7FFE
	in a, (0xFE)
	rra
	jr c, .runtime		; BREAK is not being pressed
	ld a, 0xFE		; port 0xFEFE
	in a, (0xFE)
	jr nc, .break		; BREAK was pressed
.runtime
	ld hl, ZX_STMT_R_1	; ROM return address at runtime
.syntaxtime
	push hl
	jp J_zxrom_exit		; Page out and return to Spectrum ROM
.break
	ld (iy + D_ERR_NR), 0x14 ; L - BREAK into program and fall out
				; via J_romerr
;---------------------------------------------------------------------------
; J_romerr/J_sterror
; Exit with an error with the '?' marker set to the right place.
; J_romerr also sets bit 3 of TV_FLAGS.
J_romerr
	res 3, (iy + D_TV_FLAG) ; mode unchanged
J_sterror
	ld sp, (ZX_ERR_SP)	; reset the stack
	ld hl, (ZX_CH_ADD)	; copy character reached
	ld (ZX_X_PTR), hl	; to the place where the ? marker should be
	ld hl, ZX_SET_STK	; return via SET_STK routine in BASIC ROM
	push hl
	jp J_zxrom_exit

;--------------------------------------------------------------------------
; J_sherror
; Exits via J_sterror if syntax checking, or falls through into
; J_reporterr if not
J_sherror
	bit 7, (iy + D_FLAGS)	; Syntax or runtime?
	jr z, J_sterror
;--------------------------------------------------------------------------
; J_reporterr
; Reports an error message and returns control to the ZX BASIC ROM.
; Pass the error number in A, error string in HL.
J_reporterr
	push hl			; save pointer to message
	ld (ZX_ERR_NR), a	; save the error number
	xor a			; clear interpreter flags
	ld (v_interpflags), a
	res 5, (iy + D_FLAGS)	; ready for new key
	ld h, a
	ld l, a
	ld (ZX_FLAGX), a	; clear FLAGX
	ld (ZX_X_PTR_HI), a	; clear X_PTR_HI
	ld (ZX_DEFADD), hl	; clear DEFADD
	inc l			; hl = 1
	ld (0x5C16), hl		; stream 0 = 0x0001 (K channel)
	rst CALLBAS
	defw ZX_SET_MIN		; clear calculator
	res 5, (iy + D_FLAGS)	; editing mode
	rst CALLBAS
	defw ZX_CLS_LOWER	; clear lower 2 lines
	set 5, (iy + D_TV_FLAG) ; set TV flags accordingly
	res 3, (iy + D_TV_FLAG)
	pop hl			; get error string back
.reportloop			; string pointed to by HL is null terminated
	ld a, (hl)		; get char
	and a			; null terminator?
	jr z, .endreport
	push hl
	rst CALLBAS
	defw ZX_PRINT_A_1	; Print the character
	pop hl
	inc hl
	jr .reportloop
.endreport
	ld sp, (ZX_ERR_SP)	; reset stack
	inc sp			; ignore first address
	inc sp	
	ld hl, ZX_ERRMSG_RET	; return halfway through ZX BASIC errmsg routine
	push hl
	jp J_zxrom_exit

;---------------------------------------------------------------------------
; Generic default error message, morally equivalent to 'Nonsense in BASIC'
; but different so it's easy to tell we generated it.
STR_badcmd	defb "Bad command",0

;===========================================================================
; The extra command parser.
; This uses a table (normally at 0x3A00) of vectors which point to
; the strings defining new commands, the error code that they respond to
; (normally Nonsense in BASIC, 0x0B), the ROM page they are in (if any)
; and address of the routine that handles the command.

;---------------------------------------------------------------------------
; F_parser
; A simple command parser.
F_parser
	ld a, (v_pgb)		; get current page B 
	ld (v_origpageb), a	; and save it
	ld hl, TABLE_basext	; start at the start of the parser's table
.ploop
	ld a, (hl)		; get the error code this command responds to
	and a			; if it's zero, the table has ended
	jr z, .notfound
	inc hl
	ld e, (hl)		; get the address of the command string
	inc hl
	ld d, (hl)
	inc hl
	ld a, (hl)		; which page?
	inc hl
	and a			; Z set if none
	call nz, F_setpageB	; page this page into page area B
	ex de, hl		; put string address in hl
	push de			; save table pointer
	call F_pstrcmp		; compare it with what's at CH_ADD
	pop hl			; restore table pointer into hl
	jr nz, .skip		; skip fetching the address if no match
	ld e, (hl)		; fetch address
	inc hl
	ld d, (hl)
	inc hl
	ex de, hl
	pop de			; fix the stack by removing return addr
	jp (hl)			; jump to the address specified.
.skip
	inc hl
	inc hl
	jr .ploop
.notfound
	ld a, (v_origpageb)	; restore page B
	call F_setpageB
	ret	

;------------------------------------------------------------------------
; F_pstrcmp
; HL = pointer to string to compare
; Returns with zero flag set if strings match.
F_pstrcmp
	ld de, (ZX_CH_ADD)
	inc de
.loop
	ld a, (de)
	; is the character in the string pointed to by HL a
	; null, return, colon or space - i.e. separator character?
	cp ' '
	jr z, .match
	cp ':'
	jr z, .match
	cp 0x0D
	jr z, .match
	cp (hl)			; does it match the target string?
	inc hl			; yes, so match the next char
	inc de
	jr z, .loop
	or 1			; make sure zero flag is not set
	ret
.match
	ld (ZX_CH_ADD), de	; save syntax buffer pointer in CH_ADD
	ld b, a			; save char
	; string matched so far - check it's actually ended, too.
	xor a
	cp (hl)			; set zero flag if OK
	ld a, b			; return with char at CH_ADD 
	ret


