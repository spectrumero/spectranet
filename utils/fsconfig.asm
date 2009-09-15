	org 0x8000

	include "../rom/spectranet.asm"

	call PAGEIN
	

J_exit
	jp PAGEOUT

	include "../rom/flashwrite.asm"

