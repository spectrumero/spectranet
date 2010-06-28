;The MIT License
;
;Copyright (c) 2009 Dylan Smith
;
;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:
;
;The above copyright notice and this permission notice shall be included in
;all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;THE SOFTWARE.

; Initialize and handle tape traps.

;---------------------------------------------------------------------------
; F_settrap: Sets up tape traps for the named file.
; This must be called immediately after ZX_STK_FETCH to get the string.
F_settrap
	ld hl, INTERPWKSPC
	call F_basstrcpy	; get the string from the interpreter
	
	ld a, (v_trapfd)	; File already open?
	and a			; if so this will be nonzero
	call nz, F_releasetrap	; and the old file should be closed.

	ld hl, INTERPWKSPC	; try to open the file
	ld d, 0x00		; no flags
	ld e, O_RDONLY		; read only
	call OPEN
	ret c			; exit now on error
	ld (v_trapfd), a	; save the file descriptor
	
	ld de, v_trap_blklen	; read the TAP block length to "prime the
	ld bc, 2		; system" as it were.
	call READ
	jp c, J_cleanup_traperr	; clean up if an error occurs (EOF is 
				; considered an error at this point too)

	ld hl, TAPETRAPBLOCK	; Program the CPLD NMI trap
	call SETTRAP
	ret

TAPETRAPBLOCK
	defb	0xFF		; this page
	defw	F_loadbytes	; function to call
	defw	0x0564		; address at time of NMI
	defw	0x0562		; address to trap with NMI

DEFAULTTRAPBLOCK
	defb	0xFF		; this page
	defw	F_bootfile	; function to call
	defw	0x0564		; address at time of NMI
	defw	0x0562		; address to trap with NMI

;---------------------------------------------------------------------------
; F_releasetrap: Closes the file associated with the tape trap and disables
; the trap itself.
F_releasetrap
	push ix
	ld a, 1
	out (254), a
	ld a, (v_trapfd)
	call VCLOSE		; close the file
	call DISABLETRAP	; disable the tape trap address
	xor a
	ld (v_trapfd), a	; clear the fd variable
	pop ix
	ret

;---------------------------------------------------------------------------
; F_loadbytes: Does the job of LD-BYTES in the main Spectrum ROM, but loading
; from a filesystem instead of tape.
; Parameters:		IX - address to load with data
;			DE - how many bytes to load
;			A - 0x00 for a header, 0xFF for data
;			Carry flag is set for loading, reset for verify
; On return, the carry flag is the *opposite* to normal Spectranet code -
; the routines that call loadbytes expect carry to be set if there's NOT
; an error.
F_loadbytes
	push ix			; store address
F_loadbytes_nopush		; (if IX has already been pushed)
	ld ix, 4		; point IX at the stacked registers
	add ix, sp

	ld hl, (NMISTACK)	; get the old stack pointer
	ld (hl), 0x3F		; and set the return address to
	inc hl
	ld (hl), 0x05		; 0x053F SA/LD-RET in the Spectrum ROM

	ld a, (v_trapfd)	; this could be better optimized...
	ld bc, 1
	ld de, INTERPWKSPC
	push ix
	call READ		; get the "flag" byte.
	pop ix
	jr c, .cleanuperror1

	ld a, (INTERPWKSPC)	; compare the flag byte read with the flag
	cp (ix+1)		; passed in A to LD-BYTES

	jr nz, .skip		; if they aren't the same skip the block

	ld c, (ix+6)		; get the requested length into
	ld b, (ix+7)		; BC
	pop de			; and the address into DE
	ld h, b			; remaining length in HL
	ld l, c
.readloop
	ld a, (v_trapfd)
	push hl
	push ix
	call READ
	pop ix
	pop hl
	jr c, .cleanuperror2
	sbc hl, bc		; decrement length remaining
	ld b, h			; update requested bytes
	ld c, l
	jr nz, .readloop	; continue until 0 bytes remain

	ld a, (v_trapfd)
	ld bc, 3		; now read the "check sum" + next block length
	ld de, INTERPWKSPC
	push ix
	call READ
	pop ix
	jr c, .checkeof		; EOF?
	ld hl, (INTERPWKSPC+1)	; Get the length of the next block and copy
	ld (v_trap_blklen), hl	; to the length storage.
.success
	ld (ix+2), 1		; set carry flag in return stack
	jp PAGETRAPRETURN

.checkeof
	cp EOF			; End of file - not an error condition
	jr nz, .cleanuperror2
	call F_releasetrap	; Close the file and release the trap
	ld (ix+2), 1		; Signal success to ROM
	jp PAGETRAPRETURN

.cleanuperror1
	pop hl			; restore the stack (originally ix)
.cleanuperror2
	call F_releasetrap	; Release the trap and close files
	ld (ix+2), 0		; reset the carry flag to signal error
	jp PAGETRAPRETURN

.skip				; TODO: when seek() is working...
	call F_releasetrap
	pop de			; restore stack
	pop ix
	ld a, 2
	out (254), a		; for debugging
	ld (ix+2), 0		; ensure C is cleared
	jp PAGETRAPRETURN

J_trapreturn

;---------------------------------------------------------------------------	
J_cleanup_traperr
	push af
	ld a, (v_trapfd)
	call VCLOSE
	pop af
	ret

;--------------------------------------------------------------------------
; F_initbootfile: Sets up LOAD ""
F_initbootfile
	ld hl, DEFAULTTRAPBLOCK	; Program the CPLD NMI trap
	call SETTRAP
	ret

;--------------------------------------------------------------------------
; F_bootfile
; Handles the case of an unsolicited LOAD "". It will try to load the file
; "boot" in the current working directory. If the file doesn't exist, it
; releases the trap and returns control to the tape loader.
F_bootfile
	push ix
	ld hl, DEFAULTFILE	; first copy the filename into memory
	ld de, INTERPWKSPC	; that's accessable by the FS module
	ld bc, DEFAULTFILELEN
	ldir

	ld hl, INTERPWKSPC	; try to open the file
	ld d, 0x00		; no flags
	ld e, O_RDONLY		; read only
	call OPEN
	jr c, .usetape		; On error, simply pass control back to the
				; ROM tape loader.
	ld (v_trapfd), a	; save the file descriptor
	
	ld de, v_trap_blklen	; read the TAP block length to "prime the
	ld bc, 2		; system" as it were.
	call READ
	jr c, .cleanupusetape	; any errors, then clean up and use tape. (EOF 
				; considered an error at this point too)
	
	ld hl, TAPETRAPBLOCK	; Reprogram the NMI trap.
	call SETTRAP
	jp F_loadbytes_nopush	; and go to loadbytes to do the work.

.cleanupusetape
	ld a, (v_trapfd)
	call VCLOSE		; close the file
.usetape
	pop ix
	jp PAGETRAPRETURN

DEFAULTFILE
	defb	"boot.zx",0
DEFAULTFILELEN equ $-DEFAULTFILE

