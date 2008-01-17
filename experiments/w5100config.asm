	; w5100config test code.
	; Set MAC addr, gateway, subnet etc.
F_w5100init
	; Page in the W5100
	; Chip selects put RAM in area B, W5100 in area A
	ld a, %00001101
	out (0xED), a

	; W5100 page 0 in area A
	xor a
	out (0xE9), a

	; Perform a software reset by setting the reset flag in the MR.
	ld a, MR_RST
	ld (MR), a

	; Set memory mapped mode, all options off.
	xor a
	ld (MR), a

	; Copy configuration to W5100
	ld hl, CFG_gateway
	ld de, GAR0		; first byte of config. data area
	ld bc, SIPR3-MR
	ldir

	ret

F_w5100check
	ld hl, STR_cfg
	call F_print
	ld de, GAR0
	ld b, SIPR3-MR
.loop
	ld a, (de)
	call F_inttohex8
	call F_print
	ld a, ' '
	call putc_5by8
	inc de
	djnz .loop

	ld a, '\n'
	call putc_5by8
	ret

; Configuration data.
CFG_gateway	defb 172,16,0,1
CFG_subnet	defb 255,255,255,0
CFG_hwaddr	defb 0xAA,0x17,0x0E,0x00,0x3B,0xA6
CFG_ipaddr	defb 172,16,0,10
STR_cfg		defb "Config: ",0
