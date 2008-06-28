	org 0x8000
	include "../rom/w5100_defines.asm"
	di
	ld a, 1
	ld bc, 0x80EF	; port for page in
	out (c), a	; page in
	call F_clear

	; Test the workspace
	ld hl, STR_testwkspc
	call F_print
	ld hl, 0x3000
	ld de, 0
	ld bc, 0x1000
	call F_randfill
	ld hl, 0x3000
	ld de, 0
	ld bc, 0x1000
	call F_randreadback
	jp nz, J_readfail
	ld hl, STR_ok
	call F_print

	; Test RAM paging
	ld hl, STR_pageram
	call F_print
	ld b, 0x1F	; number of pages
.ramloop
	ld a, b
	or 0xC0		; RAM = chip 3, upper two bits high
	call F_setpageA
	call F_printpage
	push bc
	ld d, 0
	ld e, b
	ld bc, 0x1000
	ld hl, 0x1000
	call F_randfill
	pop bc
	djnz .ramloop

	ld a, '\n'
	call F_putc_5by8

	ld b, 0x1F
.ramreadloop
	ld a, b
	or 0xC0		; RAM = chip 3, upper two bits high
	call F_setpageA
	call F_printpage
	push bc
	ld d, 0
	ld e, b
	ld bc, 0x1000
	ld hl, 0x1000
	call F_randreadback
	pop bc
	call nz, F_pagereadfail
	djnz .ramreadloop

	ld hl, STR_complete
	call F_print

	ld hl, STR_w5100
	call F_print

	ld a, REGPAGE
	call F_setpageA
	ld hl, HWADDR		; test: set hwaddr and ipaddr registers
	ld de, SHAR0
	ld bc, 10
	ldir
	ld b, 10
	ld de, HWADDR
	ld hl, buffer
.regloop
	ld a, (de)
	call F_itoh8
	inc de
	djnz .regloop

	ld hl, buffer
	call F_print
	ld a, '\n'
	call F_putc_5by8

EXIT
	ld a, 0
	ld bc, 0x80EF
	out (c), a	; page out
	ei
	ret

J_readfail
	ex de, hl
	ld hl, STR_readfail
	call F_print
	ld hl, buffer
	ld a, d	
	call F_itoh8
	ld a, e
	call F_itoh8
	ld hl, buffer
	call F_print
	ld a, '\n'
	call F_putc_5by8
	jr EXIT

F_printpage
	push hl
	push de
	push bc
	push af
	ld hl, buffer
	call F_itoh8
	ld hl, buffer
	call F_print
	ld hl, STR_dotdotdot
	call F_print
	pop af
	pop bc
	pop de
	pop hl
	ret

F_pagereadfail
	push hl
	push de
	push bc
	push af
	ex de, hl
	ld hl, STR_pfail
	call F_print
	ld hl, buffer
	ld a, d	
	call F_itoh8
	ld a, e
	call F_itoh8
	ld hl, buffer
	call F_print
	ld hl, STR_dotdotdot
	call F_print
	pop af
	pop bc
	pop de
	pop hl
	ret

; Fill a block of memory with random values
; hl = start address
; de = start seed
; bc = size
F_randfill
	ld (v_seed), de		; set seed to known value
.loop
	push hl
	call F_rand16
	ex de, hl		; random number in DE
	pop hl
	ld (hl), e
	inc hl
	ld (hl), d
	inc hl
	dec bc
	dec bc
	ld a, b
	or c
	jr nz, .loop
	ret

; Check that the pseudo random memory fill reads back the same values.
; hl = start address
; de = start seed
; bc = number of bytes
; zero flag is set if readback is correct
F_randreadback
	ld (v_seed), de
.loop
	push hl
	call F_rand16
	ex de, hl
	pop hl
	ld a, (hl)		; compare what's in memory to newly
	cp e			; generated pseudo random value
	ret nz			; oops
	inc hl
	ld a, (hl)
	cp d
	ret nz
	inc hl
	dec bc
	dec bc
	ld a, b
	or c
	jr nz, .loop
	ret

	include "../rom/sysdefs.asm"
	include "../rom/pager.asm"
	include "../rom/utility.asm"
	include "test_output.asm"
	include "../rom/ui_charset.asm"
	block 0x8700-$,0
	include "../rom/ui_lookup.asm"


STR_pageram defb "Paging RAM...\n",0
STR_pagerom defb "Paging ROM...\n",0
STR_testwkspc defb "Testing workspace...\n",0
STR_pagefail	defb "Readback failure in page ", 0
STR_readfail	defb "Readback failed at address ",0
STR_ok		defb "Readback OK\n",0
STR_dotdotdot	defb "...",0
STR_pfail	defb "F=",0
STR_complete	defb "\nReadback complete\n",0
STR_w5100	defb "Paging W5100\n",0
HWADDR		defb 0x01,0x03,0x07,0x0F,0x1F,0x3F
IPADDR		defb 0x7F,0xFF,0xAA,0x55

; some variables
v_seed	defw 0
v_column	defb 0		; Current column for 42 col print.
v_row		defw 0		; Current row address for print routine
v_rowcount	defb 0		; current row number
v_pr_wkspc	defb 0		; Print routine workspace
v_pga		defb 0		; Current memory page in area A
v_pgb		defb 0		; Current memory page in area B
v_hlsave	defw 0
v_desave	defw 0
v_bcsave	defw 0
v_stringptr	defw 0
buffer		defb 0,0,0,0,0,0,0,0,0,0,0,0

UNPAGE		equ 0x007C

