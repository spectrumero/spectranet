; This example demonstrates trapping an address in RAM. Execution at
; 0x8200 (33280) is trapped, and the routine 'EXECTRAP' is called
; when this trap is triggered.
	include "../rom/spectranet.asm"
	org 0x8000
	ld hl, CLEAR42		; Clear the screen for Spectranet PRINT42
	call HLCALL

	ld ix, PRINT42		; Call PRINT42 to use the 42-col print routine	
	ld hl, STR_testtrap	; Print the string 'Testing programmable traps'
	call IXCALL

	ld hl, trapblock	; Address of trap setup block
	ld ix, SETTRAP		; Call the SETTRAP routine
	call IXCALL
	ret			; Return to BASIC.

; Note that when EXECTRAP is run by the NMI handler, the Spectranet ROM
; is paged in - so no need to use HLCALL/IXCALL to access ROM routines,
; call them directly. If you need to call Spectrum ROM routines use the
; CALLBAS method. (On a 128K machine you will need to ensure the right
; Spectrum ROM is active, too).
EXECTRAP
	call CLEAR42		; Clear the screen
	ld hl, STR_exectrap	; Print a message
	call PRINT42
	jp TRAPRETURN		; Fix the stack, return, and unpage Spectranet

STR_testtrap	defb "Testing programmable traps.\n",0
STR_exectrap	defb "Executed the trap.\n",0

; This is the parameter block passed to the SETTRAP routine. We don't want
; to change page area B (0x2000-0x2FFF).
trapblock	defb 0		; no page to page in - set to zero
		defw EXECTRAP	; address to jump to
		defw comefrom	; what should be on the stack
		defw trapaddr	; address to trap
		
	block 0x8200-$,0
trapaddr			; We trap when this instruction is fetched...
	nop
comefrom			; ...but the CPU completes the instruction
	ret			; so the address on the stack will be 0x8201
	
