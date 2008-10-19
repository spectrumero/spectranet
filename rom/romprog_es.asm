	org 0x8000
	di
	ld bc, 0x80EF
	ld a, 1
	out (c), a

	call F_clear
	ld hl, STR_erasing
	call F_print
	call F_FlashEraseSectorZero
	jr c, .borked

	ld a, 1		; chip 0 page 1
	call F_setpageA
	ld a, 2		; chip 0 page 2
	call F_setpageB

	ld hl, STR_writing
	call F_print
	ld hl, PAYLOAD
	ld de, 0
	ld bc, 0x3000
.writeloop
	ld a, (hl)
	call F_FlashWriteByte
	jr c, .borked
	inc hl
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .writeloop
	ld a, 3
	call F_setpageB
	ld de, 0x2000		; start of page B
	ld bc, 0x1000		; 4k of data left to go
.writeloop2
	ld a, (hl)
	call F_FlashWriteByte
	jr c, .borked
	inc hl
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .writeloop2

	ld hl, STR_writedone
	call F_print
.exit
	ld bc, 0x80EF
	xor a
	out (c), a
	ei
	ret

.borked
	ld hl, STR_borked
	call F_print
	jr .exit

F_setpageA
	push bc
	ld bc, PAGEA
	ld (v_pga), a	; save the page we've just paged.
	out (c), a	; page it in
	pop bc
	ret

; Set paging area B. As for area A.
F_setpageB
	push bc
	ld bc, PAGEB
	ld (v_pgb), a
	out (c), a	; page it in
	pop bc
	ret

	include "../utils/flashwrite.asm"
	include "../test/test_output.asm"
	include "ui_charset.asm"

STR_erasing	defb "Erasing lower flash sector\n",0
STR_writing	defb "Writing payload...\n",0
STR_writedone	defb "Write done\n",0
STR_borked	defb "Operation failed.\n",0
	block 0x8800-$,0
col_lookup
        defb 0,0,1,2,3,3,4,5,6,6,7,8,9,9,10,11,12,12,13,14,15,15
        defb 16,17,18,18,19,20,21,21,22,23,24,24,25,26,27,27,28,29,30,30,31


v_column	defb 0
v_row		defw 0
v_pr_wkspc	defb 0
v_rowcount	defb 0
v_workspace	defb 0,0,0,0,0,0,0
v_pga		defb 0
v_pgb		defb 0
v_chipsel	defb 0

; various definitions
PAGEA		equ 0x80E9
PAGEB		equ 0x80EB
PAGERPORT	equ 0x80EF

PAYLOAD
	incbin "romimage_es.out"
PAYLOAD_END

