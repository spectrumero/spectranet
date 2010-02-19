;The MIT License
;
;Copyright (c) 2010 Dylan Smith
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

; Control channel for BASIC streams.
; The control channel allows the BASIC programmer to find out the state
; of a stream and do things to the stream.

; The control streams have different metadata than a normal file or
; socket. There should be only one control stream so it has only one
; (very short) buffer in a fixed location. Therefore the stream
; information block that normally holds things like buffer offsets instead
; has:
; byte 0: flags
; byte 1: current command
; byte 2: state of current cmd
; byte 3: stream to act upon

;-------------------------------------------------------------------------
; Control stream entry point
F_control
	bit 7, l
	jr nz, F_read_ctrlstream
; F_write_ctrlstream
; Sets the function of the control stream. This allows the BASIC
; programmer do something like "INPUT#4;"command";a%".
; Enter with L=stream
F_write_ctrlstream
	ex af, af'
	call F_findmetadata	; find our metadata table
	ex af, af'
	cp 0x21			; check it's not a control char of some sort
	jp c, F_leave		; if so ignore it
	ld (ix+OFS_CURCMD), a	; store the putative command
	ld (ix+OFS_CURSTATE), 0	; clear the current state
	jp F_leave

;-------------------------------------------------------------------------
; F_read_ctrlstream
F_read_ctrlstream
	call F_findmetadata	; stream metadata now pointed to by IX

        ld hl, ZX_TV_FLAG       ; the mode is considered unchanged
        res 3, (hl)
.isinkey			; The control stream only works with
	ld hl, (ZX_ERR_SP)	; INPUT#, make INKEY$ a no-op
	ld e, (hl)
	inc hl
	ld d, (hl)
	and a
	ld hl, 0x107F		; Compare with ED_ERROR
	sbc hl, de
	jp nz, .wasinkey

	ld a, (ix+OFS_CURCMD)	; find out the command in use
	cp CMD_POLLALL
	jp z, J_pollall
	and a
	jr z, .nocmd

.badcmd
	ld hl, STR_badcmd	; Unknown command
	jp F_sendbuf
.nocmd
	ld hl, STR_nocmd
	jp F_sendbuf
.wasinkey
	xor a			; Z and C reset - no data
	ld l, 1			; Don't fix the stack
	jp F_leave

;-------------------------------------------------------------------------
; J_pollall
; Find out which stream (if any) has data waiting for it.
; Note that not all sockets may be being used by BASIC, some may be used
; by ROM modules or other machine code programs. If a socket that's
; ready is not for a BASIC stream it gets ignored.
J_pollall
	ld a, (ix+OFS_CURSTATE)	; check current state
	and a			; if is zero, do the actual poll
	jr nz, .retsockstate	; return the socket state
	ld (ix+OFS_CURSTATE), 1	; set current state flag to "get status"

	; Check to find out whether there is pending data already
	; in the buffer.
.checkbufs
	; start with HL pointing at the first potential FD
	ld hl, BUFMETADATA+STRM_FLAGS+BUFDATASZ
	ld b, 15		; maximum number of iterations
	ld c, a			; store fd
.findloop_buf
	xor a			; check flags for the stream
	cp (hl)			; - for a socket, should all be zero
	jr nz, .nextbuf
	dec l			; point at the read buffer current
	dec l			; pointer
	cp (hl)
	jr nz, .bufrdy		; a buffer still has stuff in it
	inc l
	inc l			; restore HL
.nextbuf
	ld a, BUFDATASZ		; move to the next channel info
	add a, l
	ld l, a
	djnz .findloop_buf

	; no buffers have pending data, poll the sockets.
	call POLLALL		; poll all open sockets
	jr z, .none		; nothing waiting
	ld (ix+OFS_CURDATA), c	; save socket state

	; start with HL pointing at the first potential FD
	ld hl, BUFMETADATA+STRM_FLAGS+BUFDATASZ
	ld b, 15		; maximum number of iterations
	ld c, a			; store fd
.findloop
	xor a			; check flags for the stream
	cp (hl)			; - for a socket, should all be zero
	jr nz, .next
	ld a, c			; check FD = stream's FD	
	dec l
	cp (hl)
	jr z, .foundchan
	inc l
.next
	ld a, BUFDATASZ		; move to the next channel info
	add a, l
	ld l, a
	djnz .findloop
	jr .checkbufs		; something not ready for us, but check
				; our buffers too.

.bufrdy
	set BIT_RECV, (ix+OFS_CURDATA)
.foundchan
	ld a, 16		; maximum stream number
	sub b			; subtract where we got to
	ld hl, INTERPWKSPC	; and convert it to a string
	call ITOA8
	ld (hl), 0		; add the null
	ld hl, INTERPWKSPC	; and send it to BASIC's input buffer.
	jp F_sendbuf

.retsockstate
	ld (ix+OFS_CURSTATE), 0	; reset state flags
	ld a, (ix+OFS_CURDATA)	; get the socket's state
	bit BIT_RECV, a		; Received data?
	jr nz, .recv
	bit BIT_DISCON, a	; Disconnected?
	jr nz, .discon
	bit BIT_CONN, a		; Connected?
	jr nz, .connected
	ld hl, STR_unk
	jp F_sendbuf
.recv
	ld hl, STR_recv
	jp F_sendbuf
.discon
	ld hl, STR_discon
	jp F_sendbuf
.connected
	ld hl, STR_conn
	jp F_sendbuf
.none
	ld hl, STR_zero
	jp F_sendbuf

;-------------------------------------------------------------------------
; Send the command buffer. Buffer is at (HL)
F_sendbuf
	ld a, (hl)
	and a			; end of buffer?
	jr z, .bufdone
	push hl
	rst CALLBAS
	defw 0x0F85		; ZX_ADD_CHAR - put a character into
	pop hl			; INPUT's buffer.
	inc hl
	jr F_sendbuf
.bufdone
	ld a, 0x0d		; put a CR as the last item
	ld l, 0			; and signal "munge the stack"
	scf
	jp F_leave		; done.
	
; Some pre-defined strings to return to BASIC.
STR_badcmd	defb "err Bad command",0
STR_nocmd	defb "err No command",0
STR_unk		defb "unknown",0
STR_recv	defb "recv",0
STR_discon	defb "disconn",0
STR_conn	defb "conn",0
STR_zero	defb "0",0

