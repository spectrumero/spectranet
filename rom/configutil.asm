; This is merely a version of the configuration utility that is
; run from a Spectrum's memory (and can be loaded from disc).
	include "spectranet.asm"
	org 0x8000
	call PAGEIN
	include "configmain.asm"
	jp PAGEOUT
	include "ui_config.asm"
	include "ui_menu.asm"
	include "flashwrite.asm"
	include "flashconf.asm"
	include "sysvars.sym"

