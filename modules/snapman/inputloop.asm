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

;------------------------------------------------------------------------
; Handle user interaction for the snapshot manager.

; Create the user interface and enter the input loop.
F_startui
	call F_fetchpage
	jp c, F_nopage
	call CLEAR42
	xor a
	ld (v_viewflags), a	; reset view flags
	ld (v_inputflags), a	; and input flags
	call F_makestaticui	; create the static user interface
	call F_printcwd		; initialize the CWD line
	call F_printcurfile	; show the current file
	call F_loaddir		; get the contents of the current dir
	ld a, (v_numsnas)
	ld hl, BOXSTARTADDR
	ld bc, BOXDIMENSIONS
	ld de, v_snatable	; start with the snapshot view
	call F_makeselection	

;----------------------------------------------------------------------
; Main UI loop
F_mainloop
	call F_inputloop	; call UI control input loop, wait for a key
	ld b, a			; save the keypress in B
	ld c, 0			; use C as a counter
	ld hl, INPUTTABLE
.getactionloop
	ld a, (hl)
	and a			; check for "end of list"
	jr z, F_mainloop	; invalid key, ignore it
	cp b			; See if the key press is recognised.
	jr z, .handlekey
	inc c			; inc. counter
	inc hl
	jr .getactionloop
.handlekey
	rlc c			; double the counter to form the offset
	ld b, 0			; in BC
	ld hl, INPUTADDRS	; Calculate the address of the address
	add hl, bc		; that we need to find
	ld e, (hl)		; and get its LSB
	inc hl
	ld d, (hl)		; and MSB
	ex de, hl		; put it in hl
	ld de, .return
	push de			; effectively, we want to CALL (HL)
	jp (hl)
.return
	ld a, (v_inputflags)
	bit 0, a		; signal to leave?
	jr z, F_mainloop	; ...no, so continue
	res 0, a
	ld (v_inputflags), a	; reset the flag
	jp F_leave		; restore memory and leave

;------------------------------------------------------------------------
; F_exit
; Leave the main input loop, by setting the 'done' flag.
F_exit
	ld a, (v_inputflags)
	set 0, a
	ld (v_inputflags), a
	ret

;------------------------------------------------------------------------
; F_enterpressed
F_enterpressed
	call F_getselected
	ret z			; nothing to do - no entries
	ld a, (v_viewflags)
	and 1			; bit 1 set - directory mode
	jr z, .loadsnap
	ld de, WORKSPACE	; copy directory name to where the
	call F_strcpy		; FS module will be able to see it
	ld hl, WORKSPACE
	call CHDIR
	jp c, F_error
	call F_printcwd
	call F_loaddir
	ld hl, BOXSTARTADDR	; start address of the box
	ld bc, BOXDIMENSIONS	; box dimensions
	ld de, v_dirtable
	ld a, (v_numdirs)
	jp F_makeselection 	; make the selection and return.
.loadsnap
	ld de, WORKSPACE
	push hl
	call F_strcpy		; copy the filename into common workspace
	pop hl
	ld de, v_curfilename	; copy the filename to our "current file"
	call F_strcpy
	ld hl, WORKSPACE	; filename pointed to by HL
	call F_loadsnap		; load the snapshot
F_error				; ends up here if there is an error
	ld a, 2
	out (254), a
	ret

;------------------------------------------------------------------------
; F_saveas
F_saveas
	ld hl, STR_filename
	ld de, v_strbuf
	ld c, FNAMESZ
	call F_userinput
	ret z			; nothing entered, continue

	ld de, v_curfilename	; copy the string entered to the current
	ld hl, v_strbuf
	call F_strcpy		; filename.
	ld hl, v_strbuf
F_saveas2
	ld de, WORKSPACE	; and copy it to the workspace
	call F_strcpy		; so the FS module can see it too
	ld hl, WORKSPACE
	call F_savesna
	jp c, F_error
	call F_printcurfile

	ret

;------------------------------------------------------------------------
; F_save
F_save
	ld a, (v_viewflags)	; directory view or file view?
	and 1
	jr nz, .needfilename
	call F_getselected
	jr z, F_saveas
	ld (v_hlsave), hl	; save the pointer but don't disturb stack
	ld de, v_curfilename
	call F_strcmp		; selected = current?
	jr nz, .confirm
.save
	ld hl, (v_hlsave)
	jp F_saveas2
.confirm
	ld hl, STR_cfoverwrite
	ld de, v_strbuf
	ld c, 2
	call F_userinput
	ret z			; nothing entered, nothing to do
	ld a, (v_strbuf)	
	cp CHAR_YES
	ret nz			; user didn't answer "yes"
	ld hl, (v_hlsave)
	ld de, v_curfilename
	call F_strcpy		; set this as the current file
	jr .save
.needfilename
	ld a, (v_curfilename)	; Already have a filename?
	and a			; if zero, no
	jr z, F_saveas
			
;------------------------------------------------------------------------
; F_userinput
; HL = pointer to prompt string
; DE = pointer to buffer in which to return the data
;  C = size of input buffer
F_userinput
        push bc
        push hl
        ld bc, 0x1600           ; line 24, col 0
        call F_printat          ; HL now is the address of the line
        pop hl                  ; prompt to print
        call PRINT42
        pop bc
        push de                 ; save buffer address
        call INPUTSTRING
        ld bc, 0x1600           ; set the position again...
        call F_printat
        ld bc, 32
        call F_clearline2       ; ...to clear the line
        pop hl
        ld a, (hl)
        and a                   ; return with Z set if nothing entered
        ret

;----------------------------------------------------------------------
; F_switchdirview
; Switch between directory and file views.
F_switchdirview
	ld a, (v_viewflags)
	xor 1			; flip "dir view" bit
	ld (v_viewflags), a	; and save
	rra			; push lsb into the carry flag
	jr c, .showdir		; switch from file to dir view
	ld de, v_snatable
	ld a, (v_numsnas)
.makesel
	ld hl, BOXSTARTADDR	; start address of the box
	ld bc, BOXDIMENSIONS	; box dimensions
	jp F_makeselection 	; make the selection and return.
.showdir
	ld de, v_dirtable
	ld a, (v_numdirs)
	jr .makesel

; We end up here if the allocated page wasn't found.
F_nopage
	ld hl, STR_nomempage
	call PRINT42
	ret

	
