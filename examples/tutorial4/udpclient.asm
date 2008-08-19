; udpclient.asm - A simple example of a UDP client program.
; This is the example for the following tutorial:
; http://spectrum.alioth.net/doc/index.php/Spectranet:_Tutorial_4

	include "spectranet.asm"
	org 0x8000		; start with randomize usr 32768
	
	ld a, 2			; Set up Spectrum RST 16 routine.
	call 0x1601		; set current stream
	ld a, 255
	ld (23692), a		; Stop 'Scroll?' message for 255 lines.

	; Print 'Looking up ....' message.
	ld hl, STR_looking
	call PRINT
	ld a, '\r'
	rst 16

	; First, look up the address of the remote host using gethostbyname.
	; This should give us a big endian 4 byte IP address.
	ld hl, STR_address		; Address of the remote hostname string
	ld de, v_ipaddr			; Address of a buffer for the result
	ld ix, GETHOSTBYNAME		; gethostbyname routine
	call IXCALL			; call it
	jp c, ERROR			; abort on error

	; Open a SOCK_DGRAM socket. This is a UDP socket. It allocates
	; a new socket, and returns the file descriptor ('socket handle').
	ld c, SOCK_DGRAM		; datagram socket - UDP
	ld hl, SOCKET			; Rom routine to call
	call HLCALL			; call it
	jp c, ERROR			; on error, exit now
	ld (v_sockfd), a		; save the socket descriptor

	; Set up the rest of the ip information structure - we just
	; did the IP address with the gethostbyname call (note the address
	; we specified to return the IP), so now we set the port.
	ld hl, 2000			; port 2000
	ld (v_port), hl			; save it in memory

	ld hl, STR_sending		; tell the user we're doing it
	call PRINT

	; Send a datagram using the SENDTO rom routine.
	ld a, (v_sockfd)		; The socket descriptor
	ld hl, v_sockinfo		; Address of the sockinfo structure
	ld de, STR_sending		; The string to send
	ld bc, STR_sendend-STR_sending	; Number of bytes to send
	ld ix, SENDTO			; Routine to call
	call IXCALL
	jp c, ERROR			; Bale out on error

	ld hl, STR_receiving
	call PRINT

	; Now receive a reply using RECVFROM.
	ld a, (v_sockfd)		; The socket descriptor
	ld hl, v_sockinfo		; Address of the socket info.
	ld de, resp_buffer		; Address of the receive buffer
	ld bc, 512			; maximum of 512 bytes.
	ld ix, RECVFROM			; and use the RECVFROM routine.
	call IXCALL
	jp c, ERROR

	; Print the message that we got.
	ld hl, resp_buffer
	call PRINT

	; Close the socket and exit.
	ld a, (v_sockfd)		; The socket descriptor
	ld hl, CLOSE			; Call the CLOSE routine
	call HLCALL

	ret				; return to BASIC.

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

	

; Define some storage.
v_sockfd	defb	0		; 1 byte - socket descriptor

v_sockinfo				; Define the socket info structure...
v_ipaddr	defb	0,0,0,0		; 4 bytes - IP address
v_port		defw	0		; 2 bytes - remote port
v_localport	defw	0		; 2 bytes - local port

; Define some strings and values. Note that strings are null terminated
; C strings.
STR_looking	defb	"Resolving "
STR_address	defb	"172.16.0.2",0	; Remote host - null terminated string
STR_sending	defb	"Sending a UDP message...\r",0
STR_sendend
STR_receiving	defb	"Waiting for a response...\r",0
STR_error	defb "Failed!\r",0

; Define a receive buffer, after everything else.
resp_buffer

