; This example shows how to accept two 16 bit numbers from BASIC.
; It's important to note that the Spectranet is paged in during new
; command execution!
; This example runs in main RAM - install the new command with RAND USR 32768

	include "spectranet.asm"	; Spectranet ROM symbols

	org 0x8000
	ld hl, PARSETABLE		; Pointer to the table entry to add
	ld ix, ADDBASICEXT		; the ADDBASICEXT system call
	call IXCALL			; call it
	jr c, .installerror		; failure to install - tell user

	ld hl, STR_ok			; New command added OK
.exit
	ld ix, PRINT42			; and print the message that it's OK
	call IXCALL
	ret	

.installerror
	ld hl, STR_error
	jr .exit

	; The following is the data structure that is used by the Spectranet
	; additional command parser. It's important to note that the
	; structure itself is copied into the Spectranet's system variables,
	; but the string is not! So don't overwrite the memory used by the
	; string.
PARSETABLE
	defb 0x0B			; C Nonsense in BASIC
	defw CMDSTRING			; Pointer to string (null terminated)
	defb 0				; Don't do any memory paging
	defw RUNCMD			; Address of routine to call

CMDSTRING
	defb "*poke",0

	; Now here is the program for the command itself. You will see that
	; the above structure points to it.
RUNCMD
	; This code is run twice - once at syntax time to check syntax,
	; and once at runtime. The statement end call will handle returning
	; to the ZX ROM at syntax time, but will return as normal during
	; runtime.
	rst CALLBAS			; CALLBAS exit point
	defw NEXT_2NUM			; Call the ZX ROM 'NEXT_2NUM' routine
	call STATEMENT_END		; Check for statement end.

	; This code does not get called at syntax time, because the
	; 'call STATEMENT_END' doesn't return conventionally at syntax time
	; as noted above.
	rst CALLBAS			; Call ZX ROM's
	defw FIND_INT2			; routine that fetches a 16 bit int
	push bc				; which is returned in BC
	rst CALLBAS			; Then do it again to get the 16
	defw FIND_INT2			; bit value for the address
	push bc				; and transfer it to HL
	pop hl
	pop bc				; retrieve the value to be poked
	ld (hl), c			; poke the LSB
	inc hl
	ld (hl), b			; poke the MSB
	jp EXIT_SUCCESS			; and pass control back to ZX ROM

; Some defines
CALLBAS	equ	0x10			; RST 10
FIND_INT2 equ	0x1E99			; Spectrum ROM routine address
NEXT_2NUM equ	0x1C79			; Spectrum ROM routine address

; Strings
STR_ok	defb "BASIC extension added.\n",0
STR_error	defb "Failed to add command.\n",0

