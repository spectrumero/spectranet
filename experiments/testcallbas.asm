	org 0x8000
	di
	ld a, 1		; page in spectranet memory
	ld bc, 0x80EF
	out (c), a

	ld a, 2		; chan. 2
	rst CALLBAS
	defw 0x1601	; routine to call
	ld hl, STR_kb
.loop
	ld a, (hl)
	and a
	jr z, .kb
	rst CALLBAS
	defw 0x0010	; put char routine
	inc hl
	jr .loop
.kb
	call F_getkey
	rst CALLBAS	; print pressed key
	defw 0x0010
	call F_keyup
	jr .kb

STR_kb
	defb "Keyboard test\r",0

CALLBAS	equ 0x10
	include "../rom/ui_input.asm"
	include "../rom/zxromcalls.asm"

