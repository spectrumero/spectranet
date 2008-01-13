; Test the execution trapper. Traps are conditionally implemented at
; 0x0000, 0x0038, 0x0066 (with event flip flop set), 0x0008 (with RST8EN_L
; set), and unconditionally at 0x3C00-0x3CFF.

	org 0
RESET
	di
	ld sp, 0xF000	; initialize stack pointer for our reset.
	jp do_reset

	block 0x0008-$,0
	; this routine at first glance appears to 'unbalance the stack'.
	; However, the 'ret' in the pageout jump will rewind the stack
	; to its proper position
rst_8
	di
	push af
	call F_syntax
	jr nz, .errexit
	pop af
	pop hl		; rewind stack 1 "too far"
	jp pageout	; the ret should land us back in the interpreter
	
.errexit
	pop af
	push hl		; make space for our exit address in the Speccy ROM
	ld hl, 0	; stack pointer must be munged to call ERROR_2
	add hl, sp	; routine in the Spectrum's ROM
	ld (hl), ERROR_2 % 256
	inc hl
	ld (hl), ERROR_2 / 256
	ld hl, (CH_ADD)	; this is what the Speccy's RST 8 routine does
	ld (X_PTR), hl
	jp pageout

	; no stack munging needed to be done here, it was our interrupt
	; so we're not going to run the Spectrum ROM ISR.
	block 0x0038-$,0
interrupt
	push hl
	push af
	ld hl, STR_int
	call F_print
	pop af
	pop hl
	jp pageout

	; same as for maskable interrupts
	block 0x0066-$,0
nmi
	push hl
	push af
	ld hl, STR_nmi
	call F_print
	pop af
	pop hl
	jp pageout

	; Jumping to 0x007c encounters a 'ret' instruction in the
	; Spectrum ROM. The trapper resets the event FF and ROMCS FF
	; when execution is encountered at this address which causes our
	; ROM to page out and the Spectrum ROM to page in.
	block 0x007b-$,0
pageout
	ei
pageout_noei
	ret

do_reset
	call F_clear		; white screen
	ld hl, STR_reset	; show a string
	call F_print
	call F_testroutine

	; copy jump table to workspace ram
	ld hl, JTABLE1
	ld de, 0x3FF8
	ld bc, 8
	ldir

	call F_waitforkey	; wait for a key to be pressed
	ld hl, 0
	add hl, sp		; point hl at sp to munge stack contents
	ld (hl), 0		; set current stack contents
	inc hl
	ld (hl), 0		; to zero so 'ret' does a reset
	jp pageout_noei		; and page out - Speccy ROM will now boot.

; Print utility routine.
F_print
	ld a, (hl)
	and a		; test for NUL termination
	ret z		; NUL encountered
	call putc_5by8	; print it
	inc hl
	jr F_print

; Simple cls routine
F_clear
	ld hl, 16384
	ld de, 16385
	ld bc, 6144
	ld (hl), 0
	ldir
	ld (hl), 56	; attribute for white
	ld bc, 767
	ldir
	xor a
	ld (v_column), a
	ld (v_rowcount), a
	ld hl, 16384
	ld (v_row), hl
	ret

; simple routine to show a successful call to the jump table.
F_jtentry
	di
	push hl
	push af
	call F_clear
	ld hl, STR_jptable
	call F_print
	call F_waitforkey
	pop af
	pop hl
	jp pageout

F_calltrap1
	di
	push bc
	push de
	push hl
	push af
	call F_clear
	ld hl, STR_calltrap1
	call F_print
	call F_waitforkey
	pop af
	pop hl
	pop de
	pop bc
	jp pageout

F_calltrap2
	di
	push hl
	push af
	call F_clear
	ld hl, STR_calltrap2
	call F_print
	call F_waitforkey
	pop af
	pop hl
	jp pageout

; Simple 'wait for the any key to get pressed' routine.
; Based largely on the concepts of the Spectrum's KEY-SCAN routine.
F_waitforkey
	ld bc, 0xFEFE	; B = counter, C = port
.keyline
	in a, (c)	; read key line
	cpl		; 
	and 0x1F	; mask out unused bits and set flags
	ret nz		; key pressed, exit the loop
	rlc b		; shift counter
	jr c, .keyline	; scan if lines to be scanned
	jr F_waitforkey	; Restart routine for another pass.

; Check our rather basic BASIC extension. This allows us to do a "CAT n".
F_syntax
	ld hl, STR_rst8
	call F_print

	push de		; preserve de
	ld de, (CH_ADD)	; examine the interpreter buffer
	dec de		; look back 1 char
.dumploop
	ld a, (de)
	cp 0x0D		; end of string?
	inc de		; advance pointer without touching flags
	jr z, .interpret
	bit 7, a	; high bit set?
	jr z, .putchar
	call F_inttohex8 ; convert to hex, hl points at resulting string
	call F_print
	ld a, ' '	; add a space
	call putc_5by8
	jr .dumploop
.putchar
	call putc_5by8	; display the character in the buffer
	jr .dumploop

	; A rather rinkity dink interpreter to test handling
	; of a BASIC extension.
.interpret
	pop de
	ld hl, (CH_ADD)
	dec hl
	ld a, (hl)
	cp '*'		; Our command?
	jr nz, .notmine
	inc hl
	ld a, (hl)
	cp '.'		; Still our command?
	jr nz, .notmine
	inc hl
	ld a, (hl)
	cp 0x0D		; end?
	jr nz, .colon
.mine
	ld (CH_ADD), hl	; point CH_ADD at its new position
	ld hl, STR_ourcmd
	call F_print
	xor a		; set zero flag
	ret

.colon	cp ':'
	jr z, .mine
.notmine
	ld a, '\n'	; add a CR so the display does something
	call putc_5by8	; sensible.
	or 1		; reset zero flag
	ret

; F_inttohex8 - convert 8 bit number in A. On return hl=ptr to string
F_inttohex8
	push af
	push bc
	ld hl, v_workspace
	ld b, a
	call	.Num1
	ld a, b
	call	.Num2
	xor a
	ld (hl), a	; add null
	pop bc
	pop af
	ld hl, v_workspace
	ret

.Num1	rra
	rra
	rra
	rra
.Num2	or	0xF0
	daa
	add	a,0xA0
	adc	a,0x40

	ld	(hl),a
	inc	hl
	ret

; Exercise various parts of the hardware.
F_testroutine
	ld hl, STR_testwkspc
	call F_print
	ld a, 0xAA
	ld (0x3000), a
	ld a, (0x3000)
	cp 0xAA
	call nz, .oops

	ld hl, STR_testsdone
	call F_print
	ret

.oops	ld hl, STR_oops
	call F_print
	ret

; Include library routines
	include "print5by8.asm"

; Strings
STR_reset	defb "Reset event trapped...\n", 0
STR_rst8	defb "RST #8 trapped...", 0
STR_nmi		defb "Caught NMI.\n", 0
STR_int		defb "Caught maskable interrupt.\n",0
STR_jptable	defb "Jump table entry point used.\n", 0
STR_ourcmd	defb "\nA command for us has been recognised.\n",0
STR_calltrap1	defb "Calltrap 1 - CALL 0x3FF8 trapped.\n",0
STR_calltrap2	defb "Calltrap 2 - CALL 0x3FFB trapped.\n",0
STR_testwkspc	defb "Testing workspace...\n",0
STR_oops	defb "Test failed.\n",0
STR_testsdone	defb "Tests complete.\n",0

JTABLE1	jp F_calltrap1
JTABLE2	jp F_calltrap2
	jr JTABLE1


	block 0x0B00-$,0xFF	; 0xFF wears the flash chip less
	include "rclookup.asm"	; row/column lookup table
	include "charset.asm"

	block 0x3FFF-$,0xFF

; workspace for print routine
v_column	equ 0x3F00	; 1 byte
v_row		equ 0x3F01	; 2 bytes (row address)
v_rowcount	equ 0x3F03	; 1 byte
v_pr_wkspc	equ 0x3F04	; print routine wkspc
v_workspace	equ 0x3F05	; up to a few bytes

; Spectrum ROM entry points
ERROR_2		equ 0x0053

; Spectrum system variables
CH_ADD		equ 23645
X_PTR		equ 23647

