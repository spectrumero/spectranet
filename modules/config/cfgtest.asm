; This exercises the configdata code.
; This can be run in an emulator to check the structures get created
; correctly.
.text
.globl F_start
F_start:
	call F_createnewconfig
	ld de, 0x1ff		; create section 0x1ff
	call F_createsection

	ld de, STR_string1
	xor a			; add a string with id=0
	call F_addCFString

	ld de, STR_string2
	ld a, 1
	call F_addCFString

	ret

.globl F_copyconfig
F_copyconfig:
	ret

STR_string1:	defb	"String 1",0
STR_string2:	defb	"String 2",0

