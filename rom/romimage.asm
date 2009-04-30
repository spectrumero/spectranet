	org 0x0000
	incbin "rom.out"
	block 0x1000-$,0xFF
	incbin "datarom.out"
	block 0x2000-$,0xFF
	incbin "utilrom.out"
	block 0x3000-$,0xFF
	incbin "jumptable.out"

