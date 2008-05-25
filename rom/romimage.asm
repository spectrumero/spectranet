	org 0x0000
	incbin "rom.out"
	block 0x2000-$,0xFF
	incbin "utilrom.out"

