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

; Core work functions for the FTP filesystem.
;-----------------------------------------------------------------------
; F_ftp_connect:
; Connects to an FTP server using the data stored in system vars
; This gets called by the mount function, but may also get called if
; the connection is dropped on us.
F_ftp_connect
        ld c, SOCK_STREAM
        call SOCKET
        ret c

        ld (v_controlsock), a   ; This is for the control channel
        ld de, (v_ftp_servaddr) ; get the server address
        ld bc, 21               ; port 21 = FTP
        call CONNECT
        ret c

	call F_ftp_decodersp	; Check the response is OK.
	ret c

	ld a, CMD_USER % 256	; Send a USER command
	ld hl, v_ftp_user
	call F_ftp_sendcmd
	ret c

	ld a, CMD_PASS % 256	; semd the password
	ld hl, v_ftp_passwd
	call F_ftp_sendcmd
	ret c

	; Set status to in use and connected
	ld a, FTP_INUSE|FTP_CONNECTED
	ld (v_ftp_status), a
	ret

;----------------------------------------------------------------------
; F_ftp_disconnect
; Disconnect all sockets, but don't unmount (yet). 
F_ftp_disconnect
	ld a, CMD_QUIT % 256
	ld hl, 0		; no args
	call F_ftp_sendcmd
	
	; ignore the return code from send - close the connection
	; regardless.
	ld a, (v_controlsock)
	call CLOSE
	xor a
	ld (v_controlsock), a
	ld (v_ftp_status), a
	ld a, (v_datasock)
	and a
	ret z
	call CLOSE
	xor a
	ld (v_datasock), a
	ret

;----------------------------------------------------------------------
; F_ftp_sendcmd
; Sends a straightforward command + string arg FTP command
; A = command number
; HL = pointer to parameter
F_ftp_sendcmd
	push hl
	ld l, a			; copy the desired command to the buffer
	ld h, FTPCMDS / 256
	ld de, v_ftp_wkspc
	ld b, FTP_MAXCMDLEN
	call F_ftp_strcpy
	pop hl			; copy the string argument
	ld a, h
	or l
	jr z, .terminate	; if argptr=NULL jump forward

	ld a, ' '		; add a space between cmd+arg
	ld (de), a		
	inc de			
	ld b, FTP_MAXARGLEN	
	call F_ftp_strcpy	; copy the argument

.terminate
	ex de, hl
	ld (hl), '\r'		; add the \r\n
	inc hl
	ld (hl), '\n'
	inc hl

	ld de, v_ftp_wkspc	; find the length of the command
	sbc hl, de
	ld b, h			; and put in BC
	ld c, l
	ld de, v_ftp_wkspc
	ld a, (v_controlsock)	; prepare to send it
	call SEND
	ret 

;----------------------------------------------------------------------
; F_ftp_decodersp: Decodes the response from an FTP server
; This decodes just the first line that comes back and throws away
; the rest.
F_ftp_decodersp
	call F_readcontrolconn
	ret c

	ld hl, v_ftp_wkspc
	ld de, v_ftp_lastcode
	ld b, FTP_CODELEN
	call F_ftp_strcpy

	ld a, (hl)		; read current character, if it's a dash
	cp '-'			; there's a bunch of useless stuff to
	ld bc, FTP_MAXMSGSZ-3
	call z, F_ftp_eat	; consume before we can continue.
	
	ret

;---------------------------------------------------------------------
; F_ftp_eat: Read data that the server is sending us but we don't care
; about.
; It is looking for a pattern \r\nnnn<space>.....\r\n
; Enter with HL=start of search, BC=current bytes in the buffer
F_ftp_eat
.eatloop
	ld a, '\n'		; find the last byte of the line
	cpir
	jr nz, .getmore
	xor a
	cp b
	jr nz, .checkcode
	ld a, c
	cp 5			; number of bytes away + 1
	jr nc, .codesplit
	inc hl			; advance pointer 5 bytes
	inc hl
	inc hl
	inc hl
	dec bc			; decrease counter by 5
	dec bc
	dec bc
	dec bc
	ld a, (hl)
	cp '-'			; more useless junk to consume...
	jr z, .eatloop

	; we now have the last line, try to find the terminating \r\n
	; (we just need to look for the \n). It *SHOULD* be the last
	; byte...
.endloop
	add hl, bc
	ld a, (hl)
	cp '\n'
	ret z			; all done

	call F_readcontrolconn
	ret c
	ld hl, v_ftp_wkspc
	jr .endloop

.getmore
	call F_readcontrolconn
	ret c
	ld hl, v_ftp_wkspc
	jr .eatloop

.codesplit
	ld a, c
	ld (v_remaining), a	; save the byte count remaining.
	call F_readcontrolconn
	ret c
	ld hl, v_ftp_wkspc
	ld a, (v_remaining)
	ld c, a
	ld a, 4			; max distance to the "-" or " "
	sub a, c
	add a, l		; increse LSB of HL to point there
	ld l, a
	cp '-'			; more junk to consume
	jr z, .eatloop
	jr .endloop		; last line to consume

;------------------------------------------------------------------------
; F_readcontrolconn
; Read the control connection into the workspace buffer.
F_readcontrolconn
	ld a, (v_controlsock)
	ld de, v_ftp_wkspc
	ld bc, FTP_MAXMSGSZ
	call RECV
	ret

;-----------------------------------------------------------------------
; F_ftp_parsecode
; Parse the three digit response from a server, determine whether it is
; an error code, if so set the carry flag and A=Spectranet filesystem
; error number.
F_ftp_parsecode
	
