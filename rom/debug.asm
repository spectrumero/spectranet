; Some simple debug functions.
; hl = start address, b = byte count
F_hexdump
	push hl
	ld a, (hl)
	call F_inttohex8
	call F_print
	ld a, ' '
	call F_putc_5by8
	pop hl
	inc hl
	djnz F_hexdump
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

F_regdump
	push hl
	push de
	push bc
	push af

	ld a, '\n'
	call F_putc_5by8

	push hl
	ld a, h
	call F_inttohex8
	call F_print
	pop hl
	ld a, l
	call F_inttohex8
	call F_print
	ld a, ','
	call F_putc_5by8

	ld a, d
	call F_inttohex8
	call F_print
	ld a, e
	call F_inttohex8
	call F_print
	ld a, ','
	call F_putc_5by8
	
	ld a, b
	call F_inttohex8
	call F_print
	ld a, c
	call F_inttohex8
	call F_print
	ld a, ','
	call F_putc_5by8

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
	call F_putc_5by8

	pop af
	pop bc
	pop de
	pop hl
	ret

debugblue
	push af
	ld a, 1
	out (254), a
	pop af
	ret
debuggreen
	push af
	ld a, 4
	out (254), a
	pop af
	ret
debugred
	push af
	ld a, 2
	out (254), a
	pop af
	ret
debugmag
	push af
	ld a, 3
	out (254), a
	pop af
	ret
debugcyan
	push af
	ld a, 5
	out (254), a
	pop af
	ret
debugyel
	push af
	ld a, 6
	out (254), a
	pop af
	ret
debugblack
	push af
	xor a
	out (254), a
	pop af
	ret

