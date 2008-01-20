; Copy from rx buffer and copy into txbuffer.
; These routines assume 2K buffers for both tx and rx (so they don't bother
; ANDing the low order of RX_MASK and TX_MASK ... so if you've changed the
; buffer size, this is probably why it broke)
; The buffers get mapped into page area A (0x1000 - 0x1FFF). On entry
; it is assumed the register area is already mapped into page area A.
;
; These are low level routines and should really only be getting called by
; the socket library. Call directly at your own risk - the call address
; is likely to change with every firmware revision!
;
; Finally, a reminder: W5100 hardware registers are BIG endian.
;
; F_copyrxbuf:
; Copy the receive buffer to a location in memory. 
; On entry:	H  = high order address of register area for socket.
;		DE = destination to move buffer contents
;		BC = size of destination buffer
; On return	BC = bytes copied
; Unchanged	IX, IY, shadow registers
F_copyrxbuf
	; Set de to the number of bytes that have been received.
	push de
	ld l, Sn_RX_RSR0 % 256	; (hl) = RSR's MSB
	ld d, (hl)
	inc l
	ld e, (hl)

	; check whether it exceeds the buffer. If so just use value of
	; BC as number of bytes to copy. If not, use the RSR as number
	; of bytes to copy.
	ld a, b			; MSB of length of our buffer
	cp d			; MSB of RSR
	jp m, .findoffset	; RSR > buffer
	jr nz, .setlen		; RSR < buffer, set actual length to RSR
	ld a, c			; LSB of RSR
	cp e			; LSB of length of our buffer
	jp m, .findoffset	; RSR > buffer len

	; BC now should equal actual size to copy
.setlen
	ld b, d
	ld c, e

	; de = offset when were are done here.
.findoffset
	ld l, Sn_RX_RD0 % 256	; RX read pointer register for socket
	ld a, (hl)		; MSB of RX offset
	and gSn_RX_MASK / 256	; mask with 0x07
	ld d, a
	inc l
	ld e, (hl)

	; page in the correct bit of W5100 buffer memory
.setpage
	ld (v_sockptr), hl	; Save the current socket register pointer
	ld a, h
	sub Sn_MR / 256		; derive socket number
	bit 1, a		; upper page or lower page?
	jr nz, .upperpage
	ld hl, 0x0106		; W5100 phys. address 0x6000
	call F_setpageA
	jr .willitblend
.upperpage
	ld hl, 0x0107		; W5100 phys. address 0x7000
	call F_setpageA

	; Does the circular buffer wrap around?
.willitblend
	dec bc			; ...to check for >, not >=
	ld h, d			; not ex hl, de because we need to preserve it
	ld l, e
	add hl, bc
	inc bc			; undo previous dec
	ld a, h
	cp 0x08			; Does copy go over 2k boundary?
	jp p, .wrappedcopy	; The circular buffer wraps.

	; A straight copy from the W5100 buffer to our memory.
.straightcopy
	ld hl, (v_sockptr)	; retrieve socket register pointer
	call F_getbaseaddr	; hl now = source address
	pop de			; retrieve destination address
	ld (v_copylen), bc	; preserve length
	ldir			; copy buffer contents

.completerx
	ld hl, 0x0100		; Registers are in W5100 physmem 0x0000
	call F_setpageA
	ld hl, (v_sockptr)	; retrieve socket pointer
	ld l, Sn_RX_RD0 % 256	; point it at MSB of bytes read register.
	ld d, (hl)		; d = MSB
	inc l
	ld e, (hl)		; e = LSB
	ld bc, (v_copylen)	; retrieve length copied
	ex de, hl
	add hl, bc		; hl = new RX_RD pointer
	ex de, hl
	ld (hl), e		; copy LSB
	dec l
	ld (hl), d		; copy MSB, RX_RD now set.
	ld l, Sn_CR % 256	; (hl) = socket command register
	ld (hl), S_CR_RECV	; tell hardware that receive is complete
	ret			; BC = length copied.

	; The circular buffer wraps around, leading to a slightly
	; more complicated copy.
	; Stack contains the destination address
	; BC contains length to copy
	; DE contains offset
.wrappedcopy
	ld (v_copylen), bc	; save length
	ld hl, 0x0800		; the highest offset you can have
	sbc hl, de		; hl = how many bytes before we hit the end
	ld (v_copied), hl	; save it
	ld hl, (v_sockptr)	; retrieve socket register ptr
	call F_getbaseaddr	; hl is now source address
	pop de			; destination buffer now in DE
	ld bc, (v_copied)	; first chunk length now in BC
	ldir			; copy chunk
	ld a, h			; roll HL back 0x0800
	sub 0x08
	ld h, a
	push hl			; save new address
	ld bc, (v_copied)	; bytes copied so far
	ld hl, (v_copylen)	; total bytes to copy
	sbc hl, bc		; hl = remaining bytes
	ld b, h
	ld c, l
	pop hl			; retrieve address
	ldir			; transfer remainder
	jr .completerx		; done

;============================================================================
; F_copytxbuf:
; Copy the receive buffer to a location in memory, set hardware registers
; to send the buffer contents. 
; On entry:	H  = high order address of register area for socket.
;		DE = source buffer to copy to hardware
;		BC = size of source buffer
; On return	BC = bytes copied
; Unchanged	IX, IY, shadow registers
;
; Notes: If sending >2k of data, data should only be fed into this routine
; in chunks of <=2k a time or it'll hang. The socket library's send() 
; call should do this.
F_copytxbuf
	ld l, Sn_TX_FSR0 % 256	; point hl at free space register
.waitformsb
	ld a, b			; MSB of argment
	cp (hl)			; compare with FSR
	jp m, .getoffset	; definitely enough free space
	jr nz, .waitformsb	; Buffer MSB > FSR MSB
				; Buffer MSB = FSR MSB, check LSB value
	inc l			; (hl) = LSB of hw register
.waitforlsb
	ld a, (hl)		; get LSB of FSR
	cp c			; and compare with LSB of passed value
	jp m, .waitforlsb	; if C > (hl) wait until it's not.

.getoffset
	ld (v_sockptr), hl	; save the socket register pointer
	ld (v_copylen), bc	; save the buffer length
	push de			; save the source buffer pointer
	ld l, Sn_TX_WR0 % 256	; (hl) = TX write register offset MSB
	ld a, (hl)
	and gSn_TX_MASK / 256	; and 0x07 - 2k buffers
	ld d, a			; high order of offset in d
	inc l
	ld e, (hl)		; de = offset

	; page in the correct bit of W5100 buffer memory. TX buffer for
	; socket 0 and 1 in page 0x0104 and for 2 and 3 in 0x0105, mapping
	; socket 0 and 2 to 0x1000, 1 and 3 to 0x1800.
.setpage
	ld a, h
	sub Sn_MR / 256		; derive socket number
	bit 1, a		; upper page or lower page?
	jr nz, .upperpage
	ld hl, 0x0104		; W5100 phys. address 0x4000
	call F_setpageA
	jr .willitblend
.upperpage
	ld hl, 0x0105		; W5100 phys. address 0x5000
	call F_setpageA

	; add de (offset) and bc (length) and see if it's >0x0800, in
	; which case buffer copy needs to wrap.
.willitblend
	dec bc			; ...to check for >, not >=
	ld h, d			; not ex hl, de because we need to preserve it
	ld l, e
	add hl, bc
	inc bc			; undo previous dec
	ld a, h
	cp 0x08			; Does copy go over 2k boundary?
	jp p, .wrappedcopy	; The circular buffer wraps.

.straightcopy
	ld hl, (v_sockptr)	; restore socket pointer
	call F_getbaseaddr
	ex de, hl		; for LDIR
	pop hl			; get stacked source address
	ldir

.completetx
	ld hl, 0x0100		; registers in W5100 phys. 0x0000
	call F_setpageA
	ld hl, (v_sockptr)	; get the socket pointer back
	ld l, Sn_TX_WR0 % 256	; transmit register
	ld d, (hl)		; get MSB of TX_WR0
	inc l
	ld e, (hl)		; get LSB of TX_WR0
	ex de, hl		; swap into hl
	ld bc, (v_copylen)	; get length that was copied into the buffer
	add hl, bc		; new value of TX_WR0
	ex de, hl		; move to de
	ld (hl), e		; copy into TX_WR0
	dec l
	ld (hl), d
	ld l, Sn_CR % 256	; (hl) = command register
	ld (hl), S_CR_SEND	; update command register
	ret

.wrappedcopy
	ld hl, 0x0800		; the highest offset you can have
	sbc hl, de		; hl = how many bytes before we hit the end
	ld (v_copied), hl	; save it
	ld hl, (v_sockptr)	; retrieve socket register ptr
	call F_getbaseaddr	; hl is now source address
	ex de, hl		; swap for LDIR
	pop hl			; get source address off stack
	ld bc, (v_copied)	; length of this chunk
	ldir			; transfer
	ld a, d			; roll de back
	sub 0x08		; 0x0800 bytes
	ld d, a
	push hl			; save current source buffer ptr
	ld bc, (v_copied)	; bytes copied so far
	ld hl, (v_copylen)	; total bytes to copy
	sbc hl, bc		; hl = remaining bytes
	ld b, h
	ld c, l
	pop hl			; retrieve source buffer ptr
	ldir			; transfer remainder
	jr .completetx		; done

;============================================================================
; F_getbaseaddr:
; This routine sets HL to the base address.
; On entry: 	de = offset
;		h  = high order of socket register address
; On exit:	hl = base address
F_getbaseaddr
	ld l, 0
	ld a, h
	sub Sn_BASE		; a = 0x10 for skt 0, 0x11 for skt 1, 0x12 etc. 
	and %00010001		; mask out all but bits 4 and 1

	; at this stage, a = 0x10 for skt 0, 0x11 for skt 1, 0x10 for skt 2
	; and 0x11 for skt 3. The entire W5100 receive buffer area for
	; all sockets is 8k, but we're only paging in 4k at at time at
	; 0x1000-0x1FFF, so the physical address should either end up
	; being 0x1000 (skt 0 and 2) or 0x1800 (skt 1 and 3)
	bit 0, a		; bit 0 set = odd numbered socket at 0x1800
	jr nz, .oddsock
	ld h, a
	add hl, de		; hl = physical address
	ret
.oddsock
	add 0x08		; odd sockets are 0x18xx addresses	
	ld h, a
	add hl, de
	ret

