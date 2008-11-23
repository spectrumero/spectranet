	org 0x8000
	include "spectranet.asm"

	call PAGEIN

        ; Open the socket - this simply allocates the resources we
        ; need, and gives us an identifier (file descriptor) for the socket.
        ld c, SOCK_STREAM       ; We want a stream - i.e. TCP socket.
	call SOCKET
        jp c, ERROR             ; Exit on error.
        ld (v_sockfd), a        ; Save the socket.

        ; Now bind it to the local port - this is the port we listen on.
        ld de, 2000             ; Port 2000
	call BIND
        jp c, ERROR

        ; Set the socket to be one that listens for incoming connections.
        ld a, (v_sockfd)        ; Get the socket descriptor back.
        call LISTEN
        jp c, ERROR

	ld hl, STR_waiting
	call PRINT42

.accept
	ld a, (v_sockfd)
	call ACCEPT
	jp c, ERROR
	ld (v_connfd), a

.startscreen
	ld de, 16384		; frame buffer
	ld hl, 6144
	ld (v_remaining), hl
.readloop
	push de
	ld a, (v_connfd)
	ld bc, 1024
	call RECV
	jp c, ERROR
	ld hl, (v_remaining)
	sbc hl, bc
	ld (v_remaining), hl
	ld a, h
	or l
	jr z, .startscreen
	pop hl
	add hl, bc		; advance pointer
	ex de, hl
	jp .readloop
	
ERROR
	ld hl, STR_error
	call PRINT42
	jp PAGEOUT

STR_error	defb "Oops, died.\n",0
STR_waiting	defb "Waiting for data...\n",0

v_sockfd	defb 0
v_connfd	defb 0
v_remaining	defw 0

