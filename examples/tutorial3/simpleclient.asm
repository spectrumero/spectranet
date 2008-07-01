; A simple TCP client - this goes along with the following:
; http://spectrum.alioth.net/doc/index.php/Spectranet:_Tutorial_3

	include "spectranet.asm"
	org 0x8000		; Start with RAND USR 32768

	ld a, 2
	call 0x1601		; Set up rst 16 routine.
	ld a, 255
	ld (23692), a		; Stop the 'Scroll?' message (for 255 lines)

	ld hl, STR_looking	; Print 'Looking up' message.
	call PRINT

	; First - look up the hostname with gethostbyname, which will
	; hopefully give us the IP address of the name.
	ld hl, STR_address	; Address of the string containing the address
	ld de, ip_buffer	; Where to put the returned IP address
	ld ix, GETHOSTBYNAME	; and call the gethostbyname function
	call IXCALL
	jp c, ERROR		; If carry was set, there was an error.

	; Open the socket - this simply allocates the resources we
	; need, and gives us an identifier (file descriptor) for the socket.
	ld c, SOCK_STREAM	; We want a stream - i.e. TCP socket.
	ld hl, SOCKET		; Routine to call in ROM - SOCKET.
	call HLCALL
	jp c, ERROR		; Exit on error.
	ld (v_sockfd), a	; Save the socket.

	; Connect to the remote host. First print a message saying
	; that this is what we're trying.
	ld hl, STR_connect	
	call PRINT

	; ...now connect
	ld a, (v_sockfd)	; Get the socket file descriptor
	ld de, ip_buffer	; DE = the address of the IP address in memory
	ld bc, 80		; we want to connect to port 80
	ld hl, CONNECT		; call the CONNECT routine
	call HLCALL
	jp c, ERROR		; carry is set on error.

	; Now send some data - GET / HTTP/1.0 which will elicit a response.
	ld a, (v_sockfd)	; Get the socket file descriptor
	ld de, STR_send		; String to send
	ld bc, 18		; which is 18 bytes long
	ld hl, SEND		; to be passed to the ROM SEND routine
	call HLCALL
	jr c, ERROR

	; Get the response and print it to the screen. Display a message
	; saying we're waiting.
	ld hl, STR_receiving
	call PRINT

	ld a, (v_sockfd)
	ld de, resp_buffer	; the buffer we want to fill.
	ld bc, 1024		; up to 1K at a time
	ld hl, RECV		; and use the ROM's RECV routine
	call HLCALL
	jr c, ERROR
	
	; Make sure the returned buffer has a null on the end for
	; when we go to print it.
	ld hl, resp_buffer
	add hl, bc		; BC contains the number of bytes received.
	ld (hl), 0		; put a NULL on the end
	ld hl, resp_buffer	; and print the data we received
	call PRINT

	ld a, (v_sockfd)	; Get the socket fd
	ld hl, CLOSE		; and close it.
	call HLCALL

	ld hl, STR_done		; Print 'Done'
	call PRINT
	ret

; The next two routines are support routines - exit on error, and print
; a string.
ERROR
	ld hl, STR_error	; Error string
	call PRINT		; print it
	ld a, (v_sockfd)
	and a			; is the socket set?
	ret z			; no.. but if it is
	ld hl, CLOSE		; clean up the socket
	call HLCALL
	ret

; This routine prints a null-terminated string.
PRINT
	ld a, (hl)		; Get char to print
	and a			; Is it the end of the string?
	ret z			; Yes, so finish.
	rst 16			; Call ROM print routine
	inc hl			; Next byte
	jr PRINT		

; Note that the strings are C strings - they are all null terminated.
STR_address	defb "spectrum.alioth.net",0
STR_send	defb "GET / HTTP/1.0\r\n\r\n",0

STR_looking	defb "Looking up remote host...\r",0
STR_connect	defb "Connected.\r",0
STR_receiving	defb "Receiving data:\r",0
STR_error	defb "Failed!\r",0
STR_done	defb "Done.\r",0

v_sockfd	defb 0		; storage for socket file descriptor
ip_buffer	defb 0,0,0,0	; leave 4 bytes free for an IP address
resp_buffer			; put the response after everything else

