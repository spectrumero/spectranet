	include "spectranet.asm"
	org 0x3000
	call F_copyconfig
.menuloop
	call F_showcurrent
	ld hl, STR_choose
	call PRINT42
	ld hl, MENU_config
	call F_genmenu

	ld hl, MENU_config
	call F_getmenuopt
	jr z, .menuloop

	; TODO: Better return to utility ROM.
	ld a, 0x02		; utility rom page
	call SETPAGEB
	ret

;-------------------------------------------------------------------------
; F_copyconfig
; This copies the last 16k sector of flash to the last 4 pages of RAM.
; This allows the configuration to be edited. (The next step is to erase
; the last 16k sector, then copy back the updated configuration plus the
; existing content in the remainder of the last sector of flash).
F_copyconfig
	ld a, 0xDC	; chip 3 page 0x1C - RAM
	call SETPAGEA	; page it into page area A
	ld a, 0x1C	; chip 0 page 0x1C - flash
	call SETPAGEB	; and mapped into area B
	ld hl, 0x2000	; and copy
	ld de, 0x1000
	ld bc, 0x1000
	ldir
	ld a, 0xDD	; chip 3 page 0x1D - RAM
	call SETPAGEA	; page it into page area A
	ld a, 0x1D	; chip 0 page 0x1D - flash
	call SETPAGEB	; page it into page area B
	ld hl, 0x2000	; and copy
	ld de, 0x1000
	ld bc, 0x1000
	ldir
	ld a, 0xDE	; chip 3 page 0x1E - RAM
	call SETPAGEA	; page it into page area A
	ld a, 0x1E	; chip 0 page 0x1E - flash
	call SETPAGEB	; page it into page area B
	ld hl, 0x2000	; and copy
	ld de, 0x1000
	ld bc, 0x1000
	ldir
	ld a, 0xDF	; chip 3 page 0x1F - RAM
	call SETPAGEA	; page it into page area A
	ld a, 0x1F	; chip 0 page 0x1F - flash
	call SETPAGEB	; page it into page area B
	ld hl, 0x2000	; and copy
	ld de, 0x1000
	ld bc, 0x1000
	ldir

	ret		; configuration settings are in RAM mapped in page A
buf_addr defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
buf_hex defb 0,0,0,0,0,0,0,0

	include "ui_config.asm"
	include "ui_menu.asm"
	include "flashwrite.asm"
	include "flashconf.asm"
	include "sysvars.sym"

