; Gets the Spectranet version from ROM.
.include	"spectranet.inc"
.text
	ld hl, 0xFA02		; module FA call 02
	call MODULECALL
	jr c, .nocall		; call doesn't exist
	ret			; version number in BC	

.nocall:
	ld bc, 0
	ret

