;The MIT License
;
;Copyright (c) 2008 Dylan Smith
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


; A collection of utility functions:
; F_rand16 - Generate a 16-bit random number
;

;========================================================================
; F_rand16
; Generate a 16 bit pseudorandom number. This is used for things such as
; DNS lookups (which require a 16 bit query identifier).
; This was adapted from http://map.tni.nl/sources/external/z80bits.html#3.2
; which in turn was adapted from a game (not named).
;
; Pseudorandom number is returned in hl.
F_rand16
	push de
	push af
	ld de, (v_seed)
	ld a,d
	ld h,e
	ld l,253
	or a
	sbc hl,de
	sbc a,0
	sbc hl,de
	ld d,0
	sbc a,d
	ld e,a
	sbc hl,de
	jr nc, .rand
	inc hl
.rand	ld (v_seed),hl
	pop af
	pop de
	ret

;-----------------------------------------------------------------------
; F_ipstring2long
; Converts a string containing an IP address to a big-endian 32 bit
; long word. Carry set if the string isn't an IP address.
; HL = pointer to string
; DE = pointer to 4 byte buffer for return value
F_ipstring2long
	ld b, 4		; number of octets to convert
.loop
	push bc
	push de
	call F_atoi8	; convert an octet
	ld a, c		; move result to A
	pop de
	pop bc
	ret c		; not an 8 bit integer
	ld (de), a	; save the value in the buffer supplied
	inc de
	ld hl, (v_stringptr)
	inc hl		; advance past the '.'
	djnz .loop
	dec hl		; unwind last increment
	ld a, (hl)
	and a		; if it's not a null terminator, it's not an IP!
	jr nz, .setcarry ; not an IP - there's more to this string.
	ret
.setcarry
	scf
	ret

;-----------------------------------------------------------------------
; F_long2ipstring
; Converts a 4 byte big-endian long word into a null terminated IP string.
; hl = pointer to 4 byte buffer containing the IP address
; de = pointer to a buffer where the IP address string will be returned
F_long2ipstring
	ex de, hl
	ld b, 3		; 3 octets separated by '.' (last has a null)
.loop
	ld a, (de)
	push bc
	call F_itoa8	; convert byte to string (not null terminated)
	pop bc
	ld a, '.'
	ld (hl), a	; insert point
	inc hl
	inc de
	djnz .loop
	ld a, (de)
	call F_itoa8
	ld (hl), 0	; null terminator
	ret

;-----------------------------------------------------------------------
; F_mac2string
; Converts the MAC address pointed to by hl to a string
; Parameters: hl - address of MAC address
;             de - pointer to string buffer
F_mac2string
	ex de, hl
	ld b, 5		; MAC is 6 bytes long, handle first 5
.loop
	ld a, (de)
	call F_itoh8
	ld (hl), ':'	; replace NULL with :
	inc hl
	inc de
	djnz .loop
	ld a, (de)
	call F_itoh8	; last byte, so we have a NULL rather than :
	ret

;-----------------------------------------------------------------------
; F_string2mac
; Converts an ASCII string to a 6 byte MAC address.
; Carry flag is set if the string isn't a MAC address.
; Parameters: hl - address of MAC string
;             de - address of 6 byte MAC address buffer
F_string2mac
	ld b, 6
.loop
	call F_htoi8
	ret c		; non hex digit encounter
	ld (de), a
	inc de
	inc hl
	inc hl		; go past the separator
	djnz .loop
	ret

;-----------------------------------------------------------------------
; F_atoi8: Simple ascii-to-int 8 bit. hl=ptr to string. Positive values!
; Carry flag set on error. Returns value in c. Either a '.' or a null
; terminates the string. (The . being a delimiter in an IP address)
; This routine undoubtedly leaves some room for improvement...
F_atoi8
	; go to end of string
	ld b, 0
.endloop
	ld a, (hl)
	and a
	jr z, .endstring
	cp '.'
	jr z, .endstring
	inc hl
	inc b
	jr .endloop
.endstring
	ld (v_stringptr), hl		; save pointer to string end
	ld a, b
	cp 4
	jp p, .error

	; empty string - return with carry set 
	and a
	jr z, .error

	; units
	dec hl		; point at last char of string
	dec b
	ld a, (hl)	; a = ascii byte
	sub '0'		; set it
	ld c, a		; store it	
	ld a, b		; check which digit
	and a		; zero?
	ret z		; done

	; tens
	dec hl		; as before
	dec b
	ld a, (hl)
	sub '0'
	ld d, a		; save it
	rla		; times 2
	rla		; times 4
	rla		; times 8
	add a, c	; add units
	ld c, a		; store result
	ld a, d		; get original value
	rla		; times 2
	add a, c	; add it to result so far
	ld c, a		; store result
	ld a, b
	and a		; done?
	ret z		

	; hundreds
	dec hl		; as before
	ld a, (hl)
	sub '0'
	cp 3
	jp p, .error	; hundreds >=3 won't fit in a byte
	ld b, a
	xor a
.hundred
	add a, 100
	djnz .hundred
	add a, c	; add to result so far
	ld c, a
	ret		

.error
	scf
	ret

;------------------------------------------------------------------------
; F_itoa8:
; Convert an 8 bit number to a string.
; a = number to convert
; hl = pointer to string buffer. On exit, hl points to string's end.
; No null terminator is added!
F_itoa8
	ld b, -100
	call .conv1
	ld b, -10
	call .conv1
	ld b, -1

.conv1
	ld c, '0'-1
.conv2
	inc c
	add a, b
	jr c, .conv2
	sbc a, b
	ld (hl), c
	inc hl
	ret

;-------------------------------------------------------------------------
; F_itoh8
; Converts an 8 bit number in A to a hex string.
; Parameters: HL - buffer to fill
; This routine is a minor modification of the one at 
; http://map.tni.nl/sources/external/z80bits.html
F_itoh8
	push af
	push bc
	ld b, a
	call .Num1
	ld a, b
	call .Num2
	xor a
	ld (hl), a	; add null
	pop bc
	pop af
	ret

.Num1	rra
	rra
	rra
	rra
.Num2	or 0xF0
	daa
	add a,0xA0
	adc a,0x40

	ld (hl),a
	inc hl
	ret

;---------------------------------------------------------------------------
; F_htoi8
; Converts the ascii at (hl) and (hl+1) to an int, returned in A.
; carry flag set on error
; Modifies hl, c and a.
F_htoi8
	ld a, (hl)
	sub '0'
	cp 0x0A		; greater than digit 9?
	jr c, .next
	sub 'A'-'0'-10	; A-F part
	cp 0x10		; out of range?
	jr nc, .err
.next
	or a		; clear carry
	rla		; shift into upper nibble
	rla
	rla
	rla
	ld c, a		; save.
	inc hl
	ld a, (hl)	; next digit
	sub '0'
	cp 0x0A
	jr c, .next1
	sub 'A'-'0'-10	; A-F
	cp 0x10
	jr nc, .err
.next1
	or c		; merge in high nibble
	ret
.err
	ccf		; carry flag = error
	ret
	

;-------------------------------------------------------------------------
; F_crc16:
; Calculate a 16 bit CRC on an arbitrary region of memory.
; This was adapted from http://map.tni.nl/sources/external/z80bits.html
; Parameters: DE = start address for CRC calculation
;             BC = end number of bytes to check 
; 16 bit CRC is returned in HL.
; Note: byte counter is modified compared to orginal code.
F_crc16
	ld hl, 0xFFFF
.read
	push bc		; save byte counter
   	ld a,(de)
	inc de
	xor h
	ld h,a
	ld b,8
.crcbyte
   	add hl,hl
	jr nc, .next
	ld a,h
	xor 0x10
	ld h,a
	ld a,l
	xor 0x21
	ld l,a
.next
   	djnz .crcbyte
	pop bc		; get back the byte counter
	dec bc
	ld a, b		; and see if it's got to zero
	or c
	jr nz, .read
	ret

;--------------------------------------------------------------------------
; F_checkromsig
; Checks a ROM page signature for a valid vector table. Returns with the
; Z flag set if the signature is valid, NZ if not.
; Parameters: HL = page to test
F_checkromsig
	call F_setpageB
	ld hl, 0x2000
	ld a, (0x2001)
	xor (hl)
	cp 0xFF
	ret

