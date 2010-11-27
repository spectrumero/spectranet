.include	"spectranet.inc"
.include	"ctrlchars.inc"
.include	"sysvars.inc"

; Some simple debug functions.
; hl = start address, b = byte count
.text
.globl F_hexdump
F_hexdump:
	push de
	push af
	ld a, (hl)
	call F_inttohex8
	call PRINT42
	ld a, ' '
	call PUTCHAR42
	pop hl
	inc hl
	djnz F_hexdump
	pop af
	pop de
	ret

; F_inttohex8 - convert 8 bit number in A. On return hl=ptr to string
.globl F_inttohex8
F_inttohex8:
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

.Num1:	rra
	rra
	rra
	rra
.Num2:	or	0xF0
	daa
	add	a,0xA0
	adc	a,0x40

	ld	(hl),a
	inc	hl
	ret

F_printhl:
	push hl
	inc hl
	ld a, (hl)
	call F_inttohex8
	call PRINT42
	pop hl
	push hl
	ld a, (hl)
	call F_inttohex8
	call PRINT42
	pop hl
	ret

.globl F_regdump
F_regdump:
	push ix
	push hl
	push de
	push bc
	push af
	
	ld hl, 0
	add hl, sp

	push hl
	ld hl, STR_af
	call PRINT42
	pop hl
	call F_printhl

	inc hl
	inc hl
	push hl
	ld hl, STR_bc
	call PRINT42
	pop hl
	call F_printhl

	inc hl
	inc hl
	push hl
	ld hl, STR_de
	call PRINT42
	pop hl
	call F_printhl

	inc hl
	inc hl
	push hl
	ld hl, STR_hl
	call PRINT42
	pop hl
	call F_printhl

	inc hl
	inc hl
	push hl
	ld hl, STR_ix
	call PRINT42
	pop hl
	call F_printhl

	pop af
	pop bc
	pop de
	pop hl
	pop ix

	ret
.data
STR_ix:	defb NEWLINE,"IX:",0
STR_hl: defb NEWLINE,"HL:",0
STR_de: defb NEWLINE,"DE:",0
STR_bc: defb NEWLINE,"BC:",0
STR_af: defb NEWLINE,"AF:",0

