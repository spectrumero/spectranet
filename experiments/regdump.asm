; This tool is to make sure various things don't meddle with registers
; they shouldn't.
	include "../rom/spectranet.asm"
	org 0x8000
	di

	ld a, 0
	or 1
	ld hl, 0
	ld de, 0
	ld bc, 0
	exx
	ex af, af'
	ld a, 0
	or 1
	ld hl, 0
	ld de, 0
	ld bc, 0
	ld ix, 0
	ld iy, 0

.loop
	halt
	call F_regdump
	jr .loop

F_regdump
	push hl
	push de
	push bc
	push af
	push ix
	push iy
	exx
	ex af, af'
	push hl
	push de
	push bc
	push af
	ld (spsave), sp

	ld hl, 0
	add hl, sp
	push hl

	ld hl, STRINGS
	ld (hlsave), hl
	ld b, NUMSTRINGS
.loop
	ld hl, (hlsave)
	call F_print
	ld hl, (hlsave)
	ld de, 5
	add hl, de
	ld (hlsave), hl
	pop hl
	call F_hltostring
	djnz .loop

	ld sp, (spsave)
	pop af
	pop bc
	pop de
	pop hl
	ex af, af'
	exx
	pop iy
	pop ix
	pop af
	pop bc
	pop de
	pop hl

	ret

F_print
	ld a, (hl)
	and a
	ret z
	ld (hltwosave), hl
	ld hl, PUTCHAR42
	call HLCALL
	ld hl, (hltwosave)
	inc hl
	jr F_print

F_hltostring
	ld a, h
	push hl
	ld hl, hexstring
	call F_itoh8
	pop hl
	ld a, l
	push hl
	ld hl, hexstring+2
	call F_itoh8
	ld hl, hexstring
	call F_print
	ld a, '\n'
	ld hl, PUTCHAR42
	call HLCALL
	pop hl
	ret
	
F_itoh8
        push af
        push bc
        ld b, a
        call .Num1
        ld a, b
        call .Num2
        xor a
        ld (hl), a      ; add null
        pop bc
        pop af
        ret

.Num1   rra
        rra
        rra
        rra
.Num2   or 0xF0
        daa
        add a,0xA0
        adc a,0x40

        ld (hl),a
        inc hl
        ret

F_topleft
	push de
	push bc
	push hl
	push af
	ld b, 3
	ld hl, AT
.loop
	ld a, (hl)
	rst 16
	inc hl
	djnz .loop
	pop af
	pop hl
	pop bc
	pop de
	ret

STRINGS
	defb "SP =",0
	defb "AF'=",0
	defb "BC'=",0
	defb "DE'=",0
	defb "HL'=",0
	defb "IY =",0
	defb "IX =",0
	defb "AF =",0
	defb "BC =",0
	defb "DE =",0
	defb "HL =",0
NUMSTRINGS	equ 11
AT	defb 0x16,0x02,0x00

hexstring	defb 0,0,0,0,0

hlsave	defw 0
bcsave	defw 0
spsave	defw 0
hltwosave defw 0

