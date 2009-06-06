	org 0x0000
	incbin "rom.out"
	block 0x1000-$,0xFF
	incbin "datarom_es.out"
	block 0x2000-$,0xFF
	incbin "utilrom_es.out"
	block 0x3000-$,0xFF
	incbin "tnfs.out"
	block 0x3F00-$,0xFF
	incbin "jumptable.out"

