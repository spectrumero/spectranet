; This file just serves to ensure the code for these functions gets
; pulled into the resulting binary. Code in a library that isn't referenced
; by anything doesn't get put in the resulting binary so we must define
; these values to putt the code required.
_F_putc_5by8_impl:	equ F_putc_5by8_impl
_F_clear_impl:		equ F_clear_impl
_F_backspace_impl:	equ F_backspace_impl
