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

; General TNFS core utility functions.

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
; F_tnfs_strcat
; Concatenates two null terminated strings.
; Arguments		HL = pointer to first string buffer
;			DE = pointer to string to concatenate
;			BC = buffer size in bytes
; On return, carry is set if the buffer was too small
F_tnfs_strcat
	; find the end of the first string
	dec bc			; guarantee that we can null terminate it
.findend
	ld a, (hl)
	and a
	jr z, .string_end
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .findend
	scf			; buffer too short
	ret
.string_end
	ld a, (de)		; second string
	ld (hl), a
	and a			; null?
	ret z
	inc hl
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .string_end
	ld (hl), 0		; add a terminator
	scf			; buffer too small
	ret

;------------------------------------------------------------------------
; F_tnfs_abspath
; Make an absolute path from a supplied relative path.
; Parameters	HL = pointer to path string
;		DE = pointer to a buffer to store the resulting path
; On return DE points to the end of the new string.
F_tnfs_abspath
	ld a, (hl)		; is it already an absolute path?
	cp '/'
	ld b, 255
	jp z, F_tnfs_strcpy	; yes, so just copy it verbatim.

	push hl
	ld (v_desave), de	; save start of buffer
	ld hl, v_cwd		; first copy the working directory
.cploop
	ld a, (hl)
	and a			; zero?
	jr z, .stringend
	ld (de), a
	inc hl
	inc de
	djnz .cploop
.stringend
	ld a, 255		; did we actually copy anything?
	cp b
	jr z, .addslash		; no, so put on a leading /
	dec de
	ld a, (de)		; check for trailing /
	cp '/'
	inc de
	jr z, .parsepath	; trailing / is present, nothing to do
.addslash
	ld a, '/'
	ld (de), a		; add the trailing /
	inc de
.parsepath
	pop hl

	; Build up the actual path. If we encounter a ../, remove the
	; top path entry. If we encounter a ./, skip it.
.loop
	ld a, (hl)		; check for end of string
	and a
	jr z, .addnull		; finished so add a null to the destination
	call .relativepath	; check for relative path ../ or ./
	jr c, .loop		; relative path processed, don't copy any more
.copypath
	ld a, (hl)		; copy the byte
	ld (de), a
	inc hl
	inc de
	cp '/'			; up to a /
	jr z, .loop		; when we go for the next bit.
	and a			; hit the NULL at the end?
	ret z			; all done
	jr .copypath

.addnull
	xor a
	ld (de), a
	inc de
	ret

	; Deal with relative paths. When a ../ is encountered, the last
	; dir should be removed (stopping at the start of the string).
	; If a ./ is encountered it should be skipped.
.relativepath
	ld (v_hlsave), hl	; save pointer
	ld a, (hl)
	cp '.'
	jr nz, .notrelative	; definitely not a relative path
	inc hl
	ld a, (hl)
	cp '/'
	jr z, .omit		; It's a ./ - omit it
	and a			; or a . (null), same thing
	jr z, .omitnull
	cp '.'
	jr nz, .notrelative	; It's .somethingelse
	inc hl
	ld a, (hl)
	cp '/'
	jr z, .relative		; relative path
	and 0			; null terminator? also relative path
	jr z, .relativenull	; 
	jr .notrelative		; something else
.relative
	inc hl			; make HL point at next byte for return.
.relativenull
	ex de, hl		; do the work in HL
	push hl			; save the pointer.
	ld bc, (v_desave)	; get the pointer to the start of the buffer
	inc bc			; add 1 to it
	sbc hl, bc		; compare with the current address
	pop hl			; get current address back into HL
	jr z, .relativedone	; at the root already, so do nothing

	dec hl			; get rid of the topmost path element
	ld (hl), 0		; remove the trailing /
.chewpath
	dec hl
	ld a, (hl)		; is it a / ?
	cp '/'			; if so we're nearly done
	jr z, .relativealmostdone
	ld (hl), 0		; erase char
	jr .chewpath
.relativealmostdone
	inc hl			; HL points at next char
.relativedone
	ex de, hl
	scf			; indicate that path copy shouldn't take place
	ret

.notrelative
	ld hl, (v_hlsave)
	and a			; set Z flag if zero
	ret
.omit
	inc hl			; advance pointer to next element of the path
.omitnull
	scf			; set carry
	ret

;------------------------------------------------------------------------
; F_tnfs_header_w
; Creates a TNFS header at a fixed address, buf_tnfs_wkspc, with the
; extant session id
F_tnfs_header_w
	ld hl, buf_tnfs_wkspc
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
	push af
	ld a, (v_tnfs_seqno)
	inc a			; pre-increment the sequence number
	ld (hl), a
	ld (v_tnfs_seqno), a	; so that the seqno in memory = current seq
	pop af
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
; Sends the block of data starting at buf_tnfs_wkspc and ending at DE.
F_tnfs_message_w
	ex de, hl		; end pointer into HL for length calc
F_tnfs_message_w_hl		; entry point for when HL is already set
	ld de, buf_tnfs_wkspc	; start of block
	sbc hl, de		; calculate length
	ld b, h
	ld c, l
;------------------------------------------------------------------------
; F_tnfs_message
; Sends the block of data pointed to by DE for BC bytes and gets the
; response.
F_tnfs_message
	ld a, tnfs_max_retries	; number of retries
	ld (v_tnfs_retriesleft), a	; into memory

.retryloop
	ld a, (v_tnfssock)	; socket descriptor
	ld hl, v_tnfssockinfo	; info structure
	push de			; stack the parameters
	push bc
	call SENDTO		; send the data
	jr nc, .pollstart
	pop bc			; error, leave now after restoring stack
	pop de
	ret
	
	; wait for the response by polling
.pollstart
	call F_tnfs_poll
	jr nc, .continue	; a message is ready
	ld a, (v_tnfs_retriesleft) ; get retries left
	dec a			; decrement it
	ld (v_tnfs_retriesleft), a ; and store it
	and a			; is it at zero?
	pop bc			; fetch parameters to either restore stack
	pop de			; or get ready for the next try
	jr nz, .retryloop
	ld a, TTIMEOUT		; error code - we tried...but gave up
	scf			; timed out
	ret

.continue
	pop bc			; restore stack
	pop de
	ld a, (v_tnfssock)
	ld hl, v_tnfssockinfo	; current connection info
	ld de, tnfs_recv_buffer	; Address to receive data
	ld bc, 1024		; max message size
	call RECVFROM
	ld a, (tnfs_recv_buffer + tnfs_seqno_offset)
	push bc
	ld b, a
	ld a, (v_tnfs_seqno)
	cp b			; sequence number match? if not
	pop bc
	jr nz, .pollstart	; see if the real message is still to come
	ret

;-------------------------------------------------------------------------
; F_tnfs_poll
; Polls the tnfs fd for 1 time unit. Returns with carry set if the time
; expired.
F_tnfs_poll
	ld bc, tnfs_polltime
.loop
	push bc
	ld a, (v_tnfssock)
	call POLLFD
	pop bc
	ret nz			; done - fd is ready
	dec bc
	ld a, b
	or c
	jr nz, .loop
	scf			; poll unit time over
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
	ld a, TNOTMOUNTED	; No filesystem mounted
	ret			

;----------------------------------------------------------------------------
; F_tnfs_pathcmd
; Many TNFS commands are just the command id + null terminated path.
; This routine handles the assembly of the data block for all of these.
; Arguments: A = command
;           HL = pointer to string argument
F_tnfs_pathcmd
	push hl
	call F_tnfs_header_w	; create the header in the workspace area
	ex de, hl		; de now points at current address
	pop hl
	call F_tnfs_abspath	; create absolute path
	call F_tnfs_message_w	; send the message and get the reply.
	ret

; As above but handles the return code too.
F_tnfs_simplepathcmd
	call F_fetchpage
	ret c
	call F_tnfs_pathcmd
; Entry point for simple exit handler
F_tnfs_simpleexit
	jp c, F_leave
	ld a, (tnfs_recv_buffer+tnfs_err_offset)
	and a
	jp z, F_leave
	scf
	jp F_leave

