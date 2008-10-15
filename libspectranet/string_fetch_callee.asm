; callee linkage for string_fetch
; unsigned int string_fetch(char *buf, int bufsz);
XLIB string_fetch_callee
XDEF ASMDISP_STRING_FETCH_CALLEE

	include "zxromdefs.asm"
.string_fetch_callee
	rst 16		; CALLBAS
	defw ZX_STK_FETCH ; fetch string expression - start in bc, length in de
	ld ix, 2
	add ix, sp	; point ix at the length arg
	ld a, (ix+1)	; msb of length
	cp b		; check against returned length
	jr c, copybuf
	jr nz, setlen
	ld a, (ix+0)	; lsb of length
	cp c		; check against lsb of returned length
	jr c, copybuf
.setlen
	ld c, a		; set length to copy to passed in length
	ld b, (ix+1)
.copybuf
	ex de, hl	; source addr to hl
	ld e, (ix+2)	; destination address
	ld d, (ix+3)
	push bc		; save byte count
	ldir		; copy the buffer
	pop bc
	ld (hl), 0	; put a NULL on the end

	pop hl		; unwind the stack - get sp
	pop de		; remove length param
	ex (sp), hl	; put return address back in its rightful place
	ld h, b		; return number of bytes copied
	ld l, c
	ret

;defc ASMDISP_STRING_FETCH_CALLEE = asmentry . string_fetch_callee

