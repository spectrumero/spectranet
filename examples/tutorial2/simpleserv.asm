; A simple TCP server - this goes along with the following:
; http://spectrum.alioth.net/doc/index.php/Spectranet:_Tutorial_2

	include "spectranet.asm"
	org 0x8000		; start with RAND USR 32768

	; First, tell the Spectrum ROM to display text in the main
	; part of the screen.
	ld a, 2			; stream 2, main screen
	call 0x1601		; ROM routine to set the stream

	; Open the socket - this simply allocates the resources we
	; need, and gives us an identifier (file descriptor) for the socket.
	ld c, SOCK_STREAM	; We want a stream - i.e. TCP socket.
	ld hl, SOCKET		; Routine to call in ROM - SOCKET.
	call HLCALL
	jp c, ERROR		; Exit on error.
	ld (v_sockfd), a	; Save the socket.

	; Now bind it to the local port - this is the port we listen on.
	ld de, 2000		; Port 2000
	ld hl, BIND		; Call the BIND routine
	call HLCALL
	jp c, ERROR

	; Set the socket to be one that listens for incoming connections.
	ld a, (v_sockfd)	; Get the socket descriptor back.
	ld hl, LISTEN		; Call the LISTEN routine
	call HLCALL
	jp c, ERROR

	; Print a message on the screen.
	ld hl, STR_start
	call PRINT

.accept_loop			; We're going to come back here...

	; Now wait for and accept an incoming connection. The new socket
	; that gets created by ACCEPT is returned in the A register.
	ld a, (v_sockfd)	; Get the socket descriptor into A
	ld hl, ACCEPT		; Call the ACCEPT routine
	call HLCALL		; The program blocks here until connected...
	jp c, ERROR
	ld (v_connfd), a	; The new connection's descriptor is in A.

	ld hl, STR_connect
	call PRINT

	; Send some data to the remote host. Note that we use connfd, rather
	; than sockfd to send and receive data.
	ld a, (v_connfd)	; Get the connection's descriptor.
	ld de, STR_hello	; Address of the data we will send
	ld bc, 12		; which is 12 bytes long.
	ld hl, SEND		; Call the SEND routine
	call HLCALL
	jp c, ERROR

	; Clear out the buffer before we use it with a simple LDIR
	ld hl, BUFFER
	ld de, BUFFER+1
	ld bc, 511
	ld (hl), 0
	ldir

	; Now wait for some data to come back and display it on our
	; screen.
	ld de, BUFFER		; Address of the buffer we want to put it.
	ld bc, 512		; up to 512 bytes.
	ld a, (v_connfd)	; Use the connection's socket fd.
	ld hl, RECV		; Call the RECV routine.
	call HLCALL
	jr c, ERROR

	; Now print the buffer contents.
	ld hl, STR_data		; Print 'We received something'
	call PRINT
	ld hl, BUFFER		; Print what we received
	call PRINT

	; Close the connection.
	ld a, (v_connfd)	; Get the connection's file descriptor
	ld hl, CLOSE		; and call the CLOSE routine
	call HLCALL
	jr c, ERROR

	; Should we exit? If the client sends us 'x', then return to
	; BASIC.
	ld a, (BUFFER)		; first byte of the buffer
	cp 'x'			; Does it contain 'x'?
	jr nz, .accept_loop	; If not, wait for another connection.

	ld a, (v_sockfd)	; Get the listening socket's descriptor
	ld hl, CLOSE		; and close it
	call HLCALL
	jr c, ERROR

	; Print a message and return to BASIC.
	ld hl, STR_exit
	call PRINT
	ret
	

; The next two routines are support routines - exit on error, and print
; a string.
ERROR
	ld hl, STR_error	; Error string
	call PRINT		; print it
	ret

; This routine prints a null-terminated string.
PRINT
	ld a, (hl)		; Get char to print
	and a			; Is it the end of the string?
	ret z			; Yes, so finish.
	rst 16			; Call ROM print routine
	inc hl			; Next byte
	jr PRINT		

v_sockfd	defb 0		; Storage for the socket file descriptor
v_connfd	defb 0		; Storage for the data socket file descriptor

; Some strings to display to the user.
STR_start	defb "Listening on port 2000\r",0
STR_connect	defb "Connection established\r",0
STR_data	defb "Received a string:\r",0
STR_close	defb "Closing connection.\r",0
STR_exit	defb "Finished.\r",0
STR_error	defb "Oops, an error occurred\r",0

; The string to send to the user.
STR_hello	defb "Hello, world\n",0

; The buffer to fill - anything past the end of our program.
BUFFER

