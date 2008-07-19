	org 0x0000
	incbin "rom.out"
	block 0x1000-$,0xFF
	incbin "datarom.out"
	block 0x1F00-$,0xFF
	incbin "jumptable.out"
	block 0x2000-$,0xFF
	incbin "utilrom.out"

