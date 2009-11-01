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

;------------------------------------------------------------------------

; Snapshot handler routines.

;------------------------------------------------------------------------
; F_detectsnap
; Determine if the filename passed in HL is a snapshot file we can handle
; and call the correct routine to handle it. On error, it returns.
; If no error is encountered, the snapshot is run.
F_detectsnap
	ld d, 0			; no flags
	ld e, O_RDONLY		; file mode = RO
	call OPEN		; open the snapshot
	ret c			; and return on error.
	ld (v_snapfd), a	; save the FD

	ld (v_stacksave), sp	; Save the current stack pointer
	ld sp, v_snapstack	; Set the stack for snapshot loading.

	call F_loadsna48	; Test

	ld sp, (v_stacksave)	; Restore the stack
	ret

