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
;
; Functions for querying DNS.
; 

;========================================================================
; F_dnsAquery
; Queries a DNS server for an A record, using the servers enumerated
; in system variables v_nameserver1 and v_nameserver2
;
; Parameters: HL = pointer to null-terminated string containing address
;                  to query
;             DE = pointer to a 4 byte buffer in which to return result
; Returns   : A  = Status (carry is set on error)
;
F_dnsAquery
	ld (v_queryresult), de	; save the query result pointer

	; set up the query string to resolve in the workspace area
	ld de, buf_workspace+12	; write it after the header
	call F_dnsstring	; string to convert in hl

	xor a
	ld b, 1			; query type A and IN is both 0x01
	ld (hl), a		; MSB of query type (A)
	inc hl
	ld (hl), b		; LSB of query type (A)
	inc hl
	ld (hl), a		; MSB of class (IN)
	inc hl
	ld (hl), b		; LSB of class (IN)
	ld de, buf_workspace-1	; find out the length
	sbc hl, de		; of the query block
	ld (v_querylength), hl	; and save it in sysvars
	
	ld hl, v_nameserver1	; set up the first resolver
	ld (v_cur_resolver), hl	; and save it in sysvars area

	call F_rand16		; generate the DNS query ID
	ld (buf_workspace), hl	; store it at the start of the workspace

	ld hl, query		; start address of standard query data
	ld de, buf_workspace+2	; destination
	ld bc, queryend-query	; bytes to copy
	ldir			; build the query header

	ld hl, dns_port		; set query UDP port
	ld (v_dnssockinfo+4), hl ; to port 53
	ld hl, 0
	ld (v_dnssockinfo+6), hl ; make sure source port is unset

.resolveloop
	ld c, SOCK_DGRAM	; Open a UDP socket
	call F_socket
	ret c			; bale out on error
	ld (v_dnsfd), a		; save the file descriptor

	ld hl, (v_cur_resolver)	; get pointer to current resolver address
	ld de, v_dnssockinfo	; point de at sockinfo structure
	ldi			; copy the resolver's ip address
	ldi
	ldi
	ldi

	ld hl, v_dnssockinfo	; reset hl to the sockinfo structure
	ld de, buf_workspace	; point de at the workspace
	ld bc, (v_querylength)	; bc = length of query
	call F_sendto		; send the block of data
	jr c, .errorcleanup	; recover if there's an error

	; TODO: only wait for a specific time for the response to come back
	ld a, (v_dnsfd)
	ld hl, v_dnssockinfo	; reset hl to the socket info structure
	ld de, buf_message	; set de to the message buffer
	ld bc, 512		; maximum message size
	call F_recvfrom
	jr c, .errorcleanup

	ld a, (v_dnsfd)
	call F_sockclose

	ld hl, buf_workspace	; compare the serial number of
	ld de, buf_message	; the sent query and received
	ld a, (de)		; answer to check that
	cpi			; they are the same. If they
	jr nz, .badmsg		; are different this indicates something
	inc e			; is seriously borked.
	ld a, (de)
	cpi
	jr nz, .badmsg

	ld a, (buf_message+dns_bitfield2)
	and 0x0F		; Did we successfully resolve something?
	jr z, .result		; yes, so process the answer.

	; TODO: query remaining resolvers
	ld a, HOST_NOT_FOUND
	scf
	ret

.errorcleanup
	push af
	ld a, (v_dnsfd)		; free up the socket we've opened
	call F_sockclose
	pop af
	ret

.result
	call F_getdnsarec	; retrieve the A record from the answer
	jr c, .noaddr
	ld de, (v_queryresult)	; retrieve pointer to result buffer
	ldi			; copy the IP address
	ldi
	ldi
	ldi
	xor a			; clear return status
	ret

.badmsg
	ld a, NO_RECOVERY
	scf
	ret
.noaddr
	ld a, NO_ADDRESS	; carry is already set
	ret

;========================================================================
; F_dnsstring
; Convert a string (such as 'spectrum.alioth.net') into the format
; used in DNS queries and responses. The string is null terminated.
;
; The format adds an 8 bit byte count in front of every part of the
; complete host/domain, replacing the dots, so 'spectrum.alioth.net'
; would become [0x08]spectrum[0x06]alioth[0x03]net - the values in
; square brackets being a single byte (8 bit integer).
;
; Parameters: HL - pointer to string to convert
;             DE - destination address of finished string
; On exit   : HL - points at next byte after converted data
;	      DE is preserved.
F_dnsstring
	ld (v_fieldptr), de	; Set current field byte count pointer
	inc e			; Intial destination address.
.findsep
	ld c, 0xFF		; byte counter, decremented by LDI
.loop
	ld a, (hl)		; What are we looking at?
	cp '.'			; DNS string field separator?
	jr z, .dot
	and a			; Null terminator?
	jr z, .done
	ldi			; copy (hl) to (de), incrementing both
	jr .loop
.dot
	push de			; save current destination address
	ld a, c			; low order of byte counter (255 - bytes)
	cpl			; turn it into the byte count
	ld de, (v_fieldptr)	; retrieve field pointer
	ld (de), a		; store byte counter
	pop de			; get current destination address back
	ld (v_fieldptr), de	; save it
	inc e			; and update pointer to new address
	inc hl			; address pointer at next character
	jr .findsep		; and get next bit
.done
	push de			; save current destination address
	xor a			; put a NULL on the end of the result
	ld (de), a
	ld a, c			; low order of byte count (255 - bytes)
	cpl			; turn it into a byte count
	ld de, (v_fieldptr)	; retrieve field pointer
	ld (de), a		; save byte count
	pop hl			; get current address pointer
	inc hl			; add 1 - hl points at next byte after end
	ret			; finished.

;==========================================================================
; F_getdnsarec
; Gets a DNS 'A' record from an answer. The assumption is that the DNS
; answer is in buf_message (0x3C00).
;
; Returns: HL = pointer to IP address
; Carry flag is set if no A records were in the answer.
F_getdnsarec
	xor a
	ld (v_ansprocessed), a	; set answers processed = 0
	ld hl, buf_message + dns_headerlen
.questionloop
	ld a, (hl)		; advance to the end of the question record
	and a			; null terminator?
	inc hl
	jr nz, .questionloop	; not null, check the next character
	inc hl			; go past QTYPE
	inc hl
	inc hl			; go past QCLASS
	inc hl
.decodeanswer
	ld a, (hl)		; Test for a pointer or a label
	and 0xC0		; First two bits are 1 for a pointer
	jr z, .skiplabel	; otherwise it's a label so skip it
	inc hl
	inc hl
.recordtype
	inc hl			; skip MSB
	ld a, (hl)		; what kind of record?
	cp dns_Arecord		; is it an A record?
	jr nz, .skiprecord	; if not, advance HL to next answer
.getipaddr
	ld bc, 9		; The IP address is the 9th byte
	add hl, bc		; further on in an A record response
	ret			; so return this.
.skiplabel
	ld a, (hl)
	and a			; is it null?
	jr z, .recordtype	; yes - process the record type
	inc hl
	jr .skiplabel
.skiprecord
	ld a, (buf_message+dns_ancount+1)
	ld b, a			; number of RR answers in B
	ld a, (v_ansprocessed)	; how many have we processed already?
	inc a			; pre-increment processed counter
	cp b			; compare answers processed with total
	jr z, .baleout		; no A records found
	ld (v_ansprocessed), a
	ld bc, 7		; skip forward
	add hl, bc		; 7 bytes - now pointing at data length
	ld b, (hl)		; big-endian length MSB
	inc hl
	ld c, (hl)		; LSB
	inc hl
	add hl, bc		; advance hl to the end of the data
	jr .decodeanswer	; decode the next answer
.baleout
	scf			; set carry flag to indicate error
	ret

