; Enter with DE=start of block, BC=count, A = test byte
; Returns with A = byte read, E = byte that should have been read and the
; zero flag reset on error.
; Zero flag is set if OK
F_simplefilltest
	ld (0x3000), de
	ld (0x3002), bc
	ld h, d
	ld l, e
	ld (hl), a
	inc de
	dec bc
	ldir

	ld hl, (0x3000)
	ld bc, (0x3002)
	ld e,a
.testloop
	ld a, (hl)
	cp e
	ret nz
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .testloop
	
	ret

	
