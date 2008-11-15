; An example ROM module. This extends BASIC with the "2 byte POKE" routine
; that is in the tutorials.

	include "spectranet.asm"	; Definitions.
	org 0x2000			; All ROM modules start at this addr.
; vector table
	defb 0xAA		; Code ROM
	defb 0xFE		; ROM ID
	defw F_installcmd	; reset vector
	defw 0xFFFF		; the next few vectors are reserved
	defw 0xFFFF
	defw 0xFFFF
	defw 0xFFFF
	defw 0xFFFF
	defw STR_ident		; Pointer to a string that identifies this mod

;----------------------------------------------------------------------------
; This module doesn't really need a MODULECALL function, but this
; is provided to demonstrate the use of MODULECALL.
F_main
	ld a, l			; save parameter that's passed in L
	push af
	ld hl, STR_main		; show a string
	call PRINT42
	pop af
	ld hl, v_workspace
	call ITOH8		; Convert the value that was passed in L
	ld hl, v_workspace	; to a string and display it.
	call PRINT42
	ld a, '\n'
	call PUTCHAR42
	ret			; Done.

;----------------------------------------------------------------------------
; This routine gets called on power up or reset. In this instance, we can
; use this routine to register a new BASIC command, *poke.
F_installcmd
	ld hl, PARSETABLE	; Address of the command's information
	call ADDBASICEXT	; register the new command.
	ret nc			; and if no error, we're finished.
.error
	ld hl, STR_error
	call PRINT42
	ret

	; The following is the data structure that is used by the Spectranet
	; additional command parser. It's important to note that the
	; structure itself is copied into the Spectranet's system variables,
	; but the string is not! So don't overwrite the memory used by the
	; string.
PARSETABLE
	defb 0x0B		; C Nonsense in BASIC
	defw CMDSTRING		; Pointer to string (null terminated)
	defb 0xFF		; This is filled with our page
	defw RUNCMD		; Address of routine to call
CMDSTRING
	defb "*poke",0

;----------------------------------------------------------------------------
; This routine is invoked when *poke is encountered by BASIC.
RUNCMD
	; This code is run twice - once at syntax time to check syntax,
	; and once at runtime. The statement end call will handle returning
	; to the ZX ROM at syntax time, but will return as normal during
	; runtime.
	rst CALLBAS		; CALLBAS exit point
	defw NEXT_2NUM		; Call the ZX ROM 'NEXT_2NUM' routine
	call STATEMENT_END	; Check for statement end.

	; This code does not get called at syntax time, because the
	; 'call STATEMENT_END' doesn't return conventionally at syntax time
	; as noted above.
	rst CALLBAS		; Call ZX ROM's
	defw FIND_INT2		; routine that fetches a 16 bit int
	push bc			; which is returned in BC
	rst CALLBAS		; Then do it again to get the 16
	defw FIND_INT2		; bit value for the address
	push bc			; and transfer it to HL
	pop hl
	pop bc			; retrieve the value to be poked
	ld (hl), c		; poke the LSB
	inc hl
	ld (hl), b		; poke the MSB
	jp EXIT_SUCCESS		; and pass control back to ZX ROM

;----------------------------------------------------------------------------
; Some strings.
STR_ident	defb "16 bit POKE command",0
STR_error	defb "Unable to add BASIC extension\n",0
STR_main	defb "Main called with L=",0

; Definitions.
CALLBAS equ     0x10  		; RST 10
FIND_INT2 equ   0x1E99		; Spectrum ROM routine address
NEXT_2NUM equ   0x1C79		; Spectrum ROM routine address
v_workspace equ 0x3900		; Spectranet fixed RAM

