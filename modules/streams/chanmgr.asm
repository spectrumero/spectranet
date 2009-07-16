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

; Channel manager - handles creation and deletion of channels

;------------------------------------------------------------------------
; F_connect_impl
; Implementation of the client connect routine.
; This routine is jumped into from the BASIC interpreter routine,
; arguments are stacked:
;	First entry: Stream number
;	Second: BASIC string for hostname
;	Third: Port number
; This function must restore the stack.
F_connect_impl
	call F_fetchpage		; fetch our memory
	call c, F_allocpage
	jr c, .memerr			; one already

	pop bc				; Get stream number
	ld (v_bcsave), bc		; save it

	pop de				; start addr of string
	pop bc				; length of string
	ld hl, INTERPWKSPC+5		; copy to workspace
	call F_basstrcpy

	ld hl, INTERPWKSPC+5		; Try to look up the supplied
	ld de, INTERPWKSPC		; hostname
	call GETHOSTBYNAME
	jr c, .sockerr3

	ld c, SOCK_STREAM		; Now try to connect to the host -
	call SOCKET			; open the socket...
	jr c, .sockerr3
	ld (INTERPWKSPC+4), a		; save the socket number

	pop bc				; get port number
	ld de, INTERPWKSPC		; address of IP address
	call CONNECT
	jr c, .sockerr4

	; All was well, so a channel can now be created and a stream
	; attached.
	ld a, (v_bcsave)		; Get channel number back
	call F_createchan		; Create/open channel and stream

	; initialize the output buffer
	ld a, (v_bcsave)
	rlca				; multiply by 4
	rlca
	ld h, 0x10			; Address 0x10xx
	ld l, a
	ld (hl), 0			; Buffer pointer starts at 0
	inc l				; Next address is the FD
	ld a, (INTERPWKSPC+4)
	ld (hl), a			; store the FD

	call F_leave			; restore memory page A
	jp EXIT_SUCCESS

.memerr
	pop hl				; restore the stack
	pop hl
	pop hl
	pop hl
	ld hl, STR_nomem
	jp REPORTERR			; Report "Out of memory"

.sockerr				; TODO - better error routine
	pop hl
.sockerr1
	pop hl
.sockerr2
	pop hl
.sockerr3
	pop hl
.sockerr4
	call F_leave
	ld hl, STR_sockerr
	jp REPORTERR

;------------------------------------------------------------------------
; F_close_impl
; Implementation of the close routine.
; This routine is jumped into from the BASIC interpreter, argument is on
; the stack.
F_close_impl
	call F_fetchpage
	pop hl				; Channel number.
	ld a, l
	rlca				; multiply by 4 to find metadata
	rlca
	ld h, 0x10			; hl now points at metadata
	ld l, a
	inc l				; hl now points at fd
	
	ld a, (hl)			; fetch the FD
	call CLOSE			; close the socket
	jr c, .closeerr
	call F_leave
	call EXIT_SUCCESS

.closeerr
	call F_leave
	ld hl, STR_closeerr
	jp REPORTERR


;------------------------------------------------------------------------
; F_createchan
; Creates the channel in BASIC and connects it to a stream
F_createchan
	ld (v_asave), a			; Save the argument
	ld hl, (ZX_PROG)		; get the start of the program area
	dec hl				; pointer to where to make space
	ld bc, CHAN_LEN			; request this many bytes
	rst CALLBAS
	defw ZX_MAKE_ROOM		; allocate memory
	inc hl				; point at 1st byte of channel area
	push hl
	ld de, 5			; calculate routine start addr
	add hl, de
	ex de, hl
	pop hl
	ld (hl), e			; set LSB
	inc hl
	push hl				; Save the address
	ld (hl), d			; set MSB
	inc hl
	push hl
	ld de, IOWROUTINE_LEN+3
	add hl, de			; calculate the rx routine start
	ex de, hl
	pop hl
	ld (hl), e			; set LSB
	inc hl
	ld (hl), d			; set MSB
	inc hl
	ld (hl), 'U'			; TODO: dynamically set this
	inc hl
	push hl				; save the address
	ex de, hl			; address to copy the IO routine from
	ld hl, IOROUTINE
	ld bc, IOROUTINE_LEN
	ldir				; copy the stub
	pop ix				; get start addr into IX
	ld a, (v_asave)			; get the stream number
	ld (ix+IOWCHAN), a		; Set write ID
	set 7, a			; set MSB
	ld (IX+IORCHAN), a		; Set read ID
	pop hl				; retrieve the 2nd byte address
	ld de, (ZX_CHANS)		; get CHANS sysvar
	and a				; and calculate the offset
	sbc hl, de
	ex de, hl
	ld hl, ZX_STRMS
	ld a, (v_asave)			; Get the stream number
	and 0x0F			; mask out the flag bits
	add a, 0x03			; Calculate the offset
	add a, a			; and put it into HL
	ld b, 0
	ld c, a
	add hl, bc
	ld (hl), e			; LSB of 2nd byte of channel data
	inc hl
	ld (hl), d			; MSB of 2nd byte of channel data
	ret

IOROUTINE
	ld h, STREAM_ROM_ID		; our ROM ID
IOWCHAN	equ ($+1)-IOROUTINE		; the byte to modify
	ld l, 0				; will be modified to provide channel
	call MODULECALL
	ret
IOWROUTINE_LEN	equ $-IOROUTINE

	ld h, STREAM_ROM_ID
IORCHAN equ ($+1)-IOROUTINE
	ld l, 0
	call MODULECALL
	bit 0, l			; need to do stack munging?
	jr z, .munge
	ret
.munge
	ld sp, (ZX_ERR_SP)		; Clear machine stack
	pop de				; Remove ED-ERROR
	pop de				; Old value of SP is restored
	ld (ZX_ERR_SP), de
	ret

IOROUTINE_LEN 	equ $-IOROUTINE
CHAN_LEN	equ (IOROUTINE_LEN * 2) + 5

