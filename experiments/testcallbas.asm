	org 0x8000
	di
	ld a, 1		; page in spectranet memory
	ld bc, 0x80EF
	out (c), a

	ld a, 2		; chan. 2
	rst 0x10	; callbas
	defw 0x1601	; routine to call
	ld hl, STR_hello
.loop
	ld a, (hl)
	and a
	jr z, .halt
	rst 0x10
	defw 0x0010	; put char routine
	inc hl
	jr .loop
.halt
	di
	halt
STR_hello
	defb "Hello, world.",0

	
