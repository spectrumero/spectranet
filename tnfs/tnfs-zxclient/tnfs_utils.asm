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

; General TNFS utility functions

;------------------------------------------------------------------------
; F_tnfs_strcpy
; Copy a null terminated string in HL to the buffer in DE, up to B bytes long
; Returns with DE set to the buffer end + 1
F_tnfs_strcpy
.loop
	ld a, (hl)
	ld (de), a
	inc de
	and a			; NULL terminator?
	ret z
	inc hl
	djnz .loop
	xor a			; if we exhaust the maximum length,
	ld (de), a		; make sure there's a NULL on the end.
	inc de
	ret

;------------------------------------------------------------------------
; F_tnfs_header_w
; Creates a TNFS header at a fixed address, buf_workspace, with the
; extant session id
F_tnfs_header_w
	ld hl, buf_workspace
	ld de, (v_tnfs_sid)
; F_tnfs_header
; Creates a TNFS header. Session ID in DE. Command in A. HL is a pointer
; to the buffer to fill.
; HL points to the end of the header on exit.
F_tnfs_header
	ld (hl), e
	inc hl
	ld (hl), d
	inc hl
	ld (hl), 0		; initially retry = 0
	inc hl
	ld (hl), a		; command
	inc hl
	ret

;------------------------------------------------------------------------
; F_tnfs_opensock
; Open the socket for TNFS datagrams.
; Returns with carry set and A=error on error.
; HL=pointer to 4 byte IP address
F_tnfs_opensock
	ld de, v_tnfssockinfo	; copy IP address information into sock
	ldi			; info structure.
	ldi
	ldi
	ldi
	ld hl, 16384		; dest port
	ld (v_tnfssockinfo+4), hl
	ld hl, 0		; blank source port
	ld (v_tnfssockinfo+6), hl
	ld c, SOCK_DGRAM
	call SOCKET		; open a UDP socket.
	ret c
	ld (v_tnfssock), a
	ret

;------------------------------------------------------------------------
; F_tnfs_message_w
; Sends the block of data starting at buf_workspace and ending at DE.
F_tnfs_message_w
	ex de, hl		; end pointer into HL for length calc
F_tnfs_message_w_hl		; entry point for when HL is already set
	ld de, buf_workspace	; start of block
	sbc hl, de		; calculate length
	ld b, h
	ld c, l
;------------------------------------------------------------------------
; F_tnfs_message
; Sends the block of data pointed to by DE for BC bytes and gets the
; response.
F_tnfs_message
	ld a, (v_tnfssock)	; socket descriptor
	ld hl, v_tnfssockinfo	; info structure
	call SENDTO		; send the data
	ret c
	
	; wait for the response by polling
	ld bc, tnfs_polltime
.poll
	ld a, (v_tnfssock)
	push bc
	call POLLFD
	pop bc
	jr nz, .continue
	dec bc
	ld a, b
	or c
	jr nz, .poll
	scf			; timed out
	ret

.continue
	ld a, (v_tnfssock)
	ld hl, v_tnfssockinfo	; current connection info
	ld de, tnfs_recv_buffer	; Address to receive data
	ld bc, 1024		; max message size
	call RECVFROM
	ret

;-------------------------------------------------------------------------
; F_tnfs_mounted
; Ask if a volume is mounted. Returns with carry reset if so, and
; carry set if not, with A set to the error number.
F_tnfs_mounted
	ld a, (v_tnfssock)
	and a
	ret nz			; valid handle exists, return
	scf			; no valid handle - set carry flag
	ret			; TODO: set A to error number!
