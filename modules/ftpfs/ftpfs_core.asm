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

	; Set status to in use and connected
	ld a, FTP_INUSE|FTP_CONNECTED
	ld (v_ftp_status), a
	ret

;----------------------------------------------------------------------
; F_ftp_disconnect
; Disconnect all sockets, but don't unmount (yet). 
F_ftp_disconnect

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
	ld b, FTP_MAXARGLEN
	call F_ftp_strcpy

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
	ret c
; F_ftp_decodersp: Decodes the response from an FTP server
F_ftp_decodersp

	ret

