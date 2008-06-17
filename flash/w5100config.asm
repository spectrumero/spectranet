	; w5100config test code.
	; Set MAC addr, gateway, subnet etc.
F_w5100init
	; Page in the W5100
	; Chip selects put RAM in area B, W5100 in area A
	ld a, 0x40		; registers are in page 0 of the W5100
	call F_setpageA		; page it into area A

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

	; set up the socket buffers: 2k per socket buffer.
	ld a, 0x55
	ld (TMSR), a
	ld (RMSR), a
	
	; set the IMR
	ld a, %11101111
	ld (IMR), a

	ret

; Configuration data.
CFG_gateway	defb 172,16,0,1
CFG_subnet	defb 255,255,255,0
CFG_hwaddr	defb 0xAA,0x17,0x0E,0x00,0x3B,0xA6
CFG_ipaddr	defb 172,16,0,200
STR_cfg		defb "Config: ",0
