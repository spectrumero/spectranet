; Test the execution trapper. Traps are conditionally implemented at
; 0x0000, 0x0038, 0x0066 (with event flip flop set), 0x0008 (with RST8EN_L
; set), and unconditionally at 0x3C00-0x3CFF.

	include "w5100defines.asm"
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
	jp do_rst8

	block 0x10-$,0xFF
callbas
	ld (v_hlsave), hl
	ld (v_desave), de
	pop hl
	jp do_callbas

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
	call F_waitforkey
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
	call F_resetwkspc
	call F_clear		; white screen

	ld hl, 0xFFFF		; arbitrary delay
.delay	dec hl
	ld a, h
	or l
	jr nz, .delay

	ld hl, STR_reset	; show a string
	call F_print

	call F_testroutine

	ld hl, STR_ethinit
	call F_print
	call F_w5100init	; init the ethernet chip
	ld hl, STR_ethdone
	call F_print

	call F_w5100check	; read back config
	;call F_w5100test	; do a test listen

	; copy jump table to workspace ram
	ld hl, JTABLE1
	ld de, 0x3FF8
	ld bc, 8
	ldir
.waitforkey
	call F_waitforkey	; wait for a key to be pressed
	ld hl, 0
	add hl, sp		; point hl at sp to munge stack contents
	ld (hl), 0		; set current stack contents
	inc hl
	ld (hl), 0		; to zero so 'ret' does a reset
	jp pageout_noei		; and page out - Speccy ROM will now boot.

do_rst8
	ld (v_hlsave), hl	; save hl without disturbing stack
	pop hl			; get stack value - entry code
	push hl
	push af
	ld a, h			; check for zero - Spectrum ROM routine return
	or l
	jr z, .returnfromzxrom	; returning from a Spectrum ROM call
	call F_syntax
	jr nz, .errexit

	ld sp, (ERR_SP)		; Reset the interpreter
	ld hl, ERR_NR
	ld (hl), 0xFF
	ld hl, (FLAGS)
	bit 7, (hl)		; check what the interpreter was doing
	jr z, .stmtnext		; Syntax checking
	ld hl, 0x1B7D		; Return address is STMT-R-1
	push hl
	jp pageout
.stmtnext
	ld hl, 0x1BF4		; Return address is STMT-NEXT
	push hl
	jp pageout
	
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

.returnfromzxrom
	pop af		; restore af
	pop hl		; unwind past entry code
	ld hl, (v_hlsave)	; restore hl
	ret		; go back to the calling routine.
	
do_callbas
	ld e, (hl)		; Get the subroutine address into DE
	inc hl
	ld d, (hl)
	inc hl			; hl now is the return address
	push hl			; put the return address back on the stack
	ld hl, 0		; entry code to RST 8
	push hl
	ld hl, 8		; return address for Spectrum ROM to return
	push hl
	push de			; the actual address in ROM we want to call
	ld hl, (v_hlsave)	; restore HL
	ld de, (v_desave)	; restore de
	jp pageout		; page out

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

F_resetwkspc
	xor a
	ld hl, 0x3000
	ld de, 0x3001
	ld bc, 0xFFF
	ld (hl),a
	ldir
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
	; A rather rinkity dink interpreter to test handling
	; of a BASIC extension.
.interpret
	ld hl, (CH_ADD)
	dec hl
	ld a, (hl)
	cp '*'		; Our command?
	jr nz, .notmine
	inc hl
	ld a, (hl)
	cp 'f'		; Still our command?
	jr z, .flash
	cp 's'		; setup external interpreter?
	jr z, .setupext
	jr .notmine
.flash
	; workaround till I find out what I'm doing wrong when
	; returning to the BASIC interpreter.
	ld a, (v_runalready)
	xor 1
	ld (v_runalready), a
	
	; load the flash programmer
	inc hl
	ld (CH_ADD), hl
	call nz, F_startflashprog	; only call if xor 1 was nonzero
	xor a
	ret
.setupext
	inc hl
	ld (CH_ADD), hl
	ld hl, STR_setup
	call F_print
	ld hl, 0x8000
	ld (v_interpaddr), hl
	xor a
	ret
.notmine
	ld hl, (v_interpaddr)
	ld a, h
	or l
	jr nz, .jumpexternal
	or 1		; reset zero flag
	ret
.jumpexternal
	jp (hl)

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

F_regdump
	push hl
	push de
	push bc
	push af

	ld a, '\n'
	call putc_5by8

	push hl
	ld a, h
	call F_inttohex8
	call F_print
	pop hl
	ld a, l
	call F_inttohex8
	call F_print
	ld a, ','
	call putc_5by8

	ld a, d
	call F_inttohex8
	call F_print
	ld a, e
	call F_inttohex8
	call F_print
	ld a, ','
	call putc_5by8
	
	ld a, b
	call F_inttohex8
	call F_print
	ld a, c
	call F_inttohex8
	call F_print
	ld a, ','
	call putc_5by8

	pop af
	push af
	call F_inttohex8
	call F_print
	pop bc
	push bc
	ld a, c
	call F_inttohex8
	call F_print
	ld a, '\n'
	call putc_5by8

	pop af
	pop bc
	pop de
	pop hl
	ret

; hl = start address, b = byte count
F_hexdump
	push hl
	ld a, (hl)
	call F_inttohex8
	call F_print
	ld a, ' '
	call putc_5by8
	pop hl
	inc hl
	djnz F_hexdump
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

.testpager
	ld hl, STR_pagetest
	call F_print
	ld a, 0x0F	; RAM in both A and B page areas
	ld bc, 0x80ED	; port 0x80ED - (bit 15 high for 128k machines)
	out (c), a	; chip selects set
	
	ld b, 32	; 128k has 32 x 4k pages
	ld c, 0xE9	; port E9 = page area A (port %1110 1001)
.pageloop
	ld a, b
	ld b, 0x80
	out (c), a	; select page
	ld (0x1000), a	; set a byte in page area A
	ld b, a		; restore b
	call F_inttohex8
	call F_print
	ld a, ' '
	call putc_5by8
	djnz .pageloop
	ld a, '\n'
	call putc_5by8

	ld hl, STR_readback
	call F_print
	ld b, 32
.readback
	ld a, b
	ld b, 0x80
	out (c), a
	ld b, a
	ld a, (0x1000)
	call F_inttohex8
	call F_print
	ld a, ' '
	call putc_5by8
	djnz .readback
	ld a, '\n'
	call putc_5by8

	ld hl, STR_testsdone
	call F_print
	ret

.oops	ld hl, STR_oops
	call F_print
	ret

; A quick test of the W5100. (Do this after init).
; For socket 0, nothing needs to be added to Sn_
F_w5100test
	ld hl, 0x0100	; chip 1, page 0
	call F_setpageA	; page in W5100
.openport
	ld a, S_MR_TCP	; Create a TCP socket.
	ld (Sn_MR), a	; Set mode.
	ld a, 23	; Port 23 (note big endian)
	ld (Sn_PORT1), a
	xor a
	ld (Sn_PORT0), a
	ld a, S_CR_OPEN	; Open the socket.
	ld (Sn_CR), a
	ld a, (Sn_SR)	; Check status register.
	cp S_SR_SOCK_INIT	; Is it?
	jr z, .listen	; if so listen
	ld a, S_CR_CLOSE
	ld (Sn_CR), a	; try again
	jr .openport

.listen
	ld hl, STR_open	; Display message.
	call F_print

	ld a, S_CR_LISTEN
	ld (Sn_CR), a	; Set command register to listen.
	ld a, (Sn_SR)	; Check status register
	cp S_SR_SOCK_LISTEN
	jr z, .listening
	ld a, S_CR_CLOSE
	ld (Sn_CR), a	; try again
	jr .openport

.listening
	ld a, (Sn_SR)	; Check status register
	cp S_SR_SOCK_ESTABLISHED
	jr nz, .listening	; loop 'till we get a connection

.rxdata
	ld a, (Sn_RX_RSR0)	; data?
	ld hl, Sn_RX_RSR1
	or (hl)			; test for zero
	jr z, .rxdata		; loop until data is received.
.recv
	push hl
	ld hl, 0x8000		; clear out some memory
	ld (hl), 0
	ld de, 0x8001
	ld bc, 0x200
	ldir
	pop hl
	ld de, 0x8000		; destination address
	ld bc, 0x123		; Maximum length (completely arbitrary)
	call F_copyrxbuf	; Copy data

	ld hl, 0x8000
	ld b, 10
	call F_hexdump

;.send
;	ld hl, Sn_SR	
;	ld de, STR_open
;;	ld bc, STR_rxbytes-STR_open
;	call F_copytxbuf

.closeloop
	ld a, (Sn_SR)
	cp S_SR_SOCK_CLOSE_WAIT	; has the client gone away?
	jr nz, .rxdata		; no, wait for more data

.waitforclose
	ld a, (Sn_IR)
	and S_IR_DISCON
	jr z, .waitforclose
	ld hl, STR_closed
	call F_print
	ld a, S_CR_CLOSE
	ld (Sn_CR), a		; close our end

	ret

; Set paging area A. Page in HL (chip in H, page in L)
F_setpageA
	push bc
	ld b, 0x80	; upper bits of port address
	ld a, (v_chipsel)
	and 0xFC	; zero lower two bits
	or h		; insert chip select value
	ld (v_chipsel), a
	ld c, CHIPSEL
	out (c), a
	ld a, l
	ld (v_pga), a	; store new page number
	ld c, PAGEA
	out (c), a	; page it in
	pop bc
	ret

; Set paging area B. As for area A.
F_setpageB
	push bc
	ld b, 0x80	; upper bits of port address
	ld a, (v_chipsel)
	and 0xF3	; zero upper 2 bits of nibble
	rl h		; move chip select value into correct bits
	rl h		
	or h		; insert chip select value
	ld (v_chipsel), a
	ld c, CHIPSEL
	out (c), a	
	ld a, l
	ld (v_pgb), a
	ld c, PAGEB
	out (c), a	; page it in
	pop bc
	ret

F_startflashprog
	ld hl, 0x0003	; chip 0 page 3
	call F_setpageB
	ld hl, 0x2000	; start of page area B
	ld de, 0xF000	; flash programmer org addr.
	ld bc, ENDFLASH-STARTFLASH	; size
	ldir
	jp 0xF000

; Include library routines
	include "print5by8.asm"
	include "w5100config.asm"
	include "w5100buffer.asm"

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
STR_pagetest	defb "Testing pager: ",0
STR_readback	defb "Readback     : ",0
STR_ethinit	defb "Initializing W5100...",0
STR_ethdone	defb "Done.\n", 0
STR_open	defb "\nListening on port 23\n",0
STR_rxbytes	defb "Received bytes = ",0
STR_closed	defb "\nSocket closed.\n",0
STR_setup	defb "External interpreter set to 0x8000\n",0

JTABLE1	jp F_calltrap1
JTABLE2	jp F_calltrap2
	jr JTABLE1


	block 0x0B00-$,0xFF	; 0xFF wears the flash chip less
	include "rclookup.asm"	; row/column lookup table
	include "charset.asm"

	block 0x3000-$,0xFF
STARTFLASH
	incbin "../flash/flashprog.out"
ENDFLASH	defb 0

; Workspace defs.
v_column	equ 0x3F00	; Current column for print routine
v_row		equ 0x3F01	; Current row address for print routine
v_rowcount	equ 0x3F03	; Current row number for print routine
v_pr_wkspc	equ 0x3F04	; Print routine workspace
v_workspace	equ 0x3F05	; General purpose workspace
v_pga		equ 0x3F10	; Paging area A page
v_pgb		equ 0x3F11	; Paging area B page
v_chipsel	equ 0x3F12	; Chip select values

; Put these elsewhere so they don't collide with ROM testing
v_sockptr	equ 0x3000	; Pointer to socket register (2 bytes)
v_copylen	equ 0x3002	; Length to copy
v_copied	equ 0x3004	; Wrapped copied so far
v_hlsave	equ 0x3006	; save hl for callbas
v_desave	equ 0x3008
v_interpaddr	equ 0x300A	; extra interpreter to call
v_runalready	equ 0x300C	; 'run already' flag

; Spectrum ROM entry points
ERROR_2		equ 0x0053
ERR_SP		equ 23613
ERR_NR		equ 23610
FLAGS		equ 23611

; Spectrum system variables
CH_ADD		equ 23645
X_PTR		equ 23647

; various definitions
CHIPSEL		equ 0xED
PAGEA		equ 0xE9
PAGEB		equ 0xEB
