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

; BASIC extensions

;--------------------------------------------------------------------------
; F_connect: Receives the %connect command, opens a socket,
; and connects it to a host.
; Syntax is %connect stream,"hostname",port
F_connect
        rst CALLBAS
        defw ZX_EXPT1_NUM               ; stream number to open
	cp ','
	jp nz, PARSE_ERROR
	rst CALLBAS
	defw ZX_NEXT_CHAR

        rst CALLBAS
        defw ZX_EXPT_EXP                ; string parameter - hostname
	cp ','
	jp nz, PARSE_ERROR
	rst CALLBAS
	defw ZX_NEXT_CHAR

	rst CALLBAS
	defw ZX_EXPT1_NUM		; check for port number

        call STATEMENT_END

        ;-------- runtime --------
        rst CALLBAS
        defw ZX_FIND_INT2		; port number
	push bc				; save it

	rst CALLBAS
	defw ZX_STK_FETCH		; hostname
	push bc				; save length
	push de				; and source

        rst CALLBAS
        defw ZX_FIND_INT2		; stream
	push bc				; save stream
        jp F_connect_impl


;-----s--------------------------------------------------------------------
; F_close: Closes an open stream.
; Syntax is %close stream
F_close
	rst CALLBAS
	defw ZX_EXPT1_NUM	; Check for a number
	call STATEMENT_END	; followed by the end of the command

	; Runtime
	rst CALLBAS
	defw ZX_FIND_INT2	; Get the 16 bit integer (stream number)
	push bc			; save it on the stack
	jp F_close_impl		; Jump to the meat of the routine

;--------------------------------------------------------------------------
; Copy a BASIC string to a C string.
; BASIC string in DE, C string (dest) in HL
F_basstrcpy 
        ld a, b                         ; end of string?
        or c
        jr z, .terminate
        ld a, (de)
        ld (hl), a
        inc hl 
        inc de 
        dec bc 
        jr F_basstrcpy
.terminate
        xor a                           ; put the null on the end
        ld (hl), a
        inc hl
        ret

