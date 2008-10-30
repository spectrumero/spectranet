; Simple flash writer for the Am29F010 (and probably any 1 megabit flash
; with 16kbyte sectors)
; Pass the page in A
; On error, carry flag set.
F_FlashEraseSectorZero
	ld a, 0xAA	; unlock code 1
	ld (0x555), a	; unlock addr 1
	ld a, 0x55	; unlock code 2
	ld (0x2AA), a	; unlock addr 2
	ld a, 0x80	; erase cmd 1
	ld (0x555), a	; erase cmd addr 1
	ld a, 0xAA	; erase cmd 2
	ld (0x555), a	; erase cmd addr 2
	ld a, 0x55	; erase cmd 3
	ld (0x2AA), a	; erase cmd addr 3
	ld a, 0x30	; erase cmd 4
	ld (0x0000), a	; erase sector address

	ld hl, 0
.wait
	bit 7, (hl)	; test DQ7 - should be 1 when complete
	jr nz, .complete
	bit 5, (hl)	; test DQ5 - should be 1 to continue
	jr z, .wait
	bit 7, (hl)	; test DQ7 again
	jr z, .borked

.complete
	or 0		; clear carry flag
	ret

.borked	
	scf		; carry flag = error
	ret

; F_FlashWriteByte
; Write the byte in A to the address pointed at by DE.
; On return, carry flag set = error
F_FlashWriteByte
	push bc
	ld c, a		; save A

	ld a, #AA	; unlock 1
	ld (0x555), a	; unlock address 1
	ld a, 0x55	; unlock 2
	ld (0x2AA), a	; unlock address 2
	ld a, 0xA0	; Program
	ld (0x555), a	; Program address
	ld a, c		; retrieve A
	ld (de), a	; program it

.wait
	ld a, (de)	; read programmed address
	ld b, a		; save status
	xor c		
	bit 7, a	; If bit 7 = 0 then bit 7 = data	
	jr z, .byteComplete

	bit 5, b	; test DQ5
	jr z, .wait

	ld a, (de)	; read programmed address
	xor c		
	bit 7, a	; Does DQ7 = programmed data? 0 if true
	jr nz, .borked

.byteComplete
	pop bc
	or 0		; clear carry flag
	ret

.borked
	pop bc
	scf		; error = set carry flag
	ret

