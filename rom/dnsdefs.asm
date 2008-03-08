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

; Definitions for querying DNS
;
; Most of the fields for a standard DNS 'A' record lookup will not change
; so the fields are defined here so they get flashed into the ROM.
; See RFC 1035 for full descriptions of the fields.

query		defb 0x01,0x00	; 16 bit flags field - std. recursive query
qdcount		defb 0x00,0x01	; we only ever ask one question at a time
ancount		defw 0x0000	; No answers in a query
nscount		defw 0x0000	; No NS RRs in a query
arcount		defw 0x0000	; No additional records
queryend

; Definitions
dns_headerlen	equ 12		; 12 bytes long
dns_Arecord	equ 1		; A record indicator in query/answer
dns_port	equ 53		; port 53/udp

; Offsets to the fields of the DNS message header
dns_serial	equ 0		; Two byte serial number
dns_bitfield1	equ 2		; First 8 bits of the flags bitfield
dns_bitfield2	equ 3		; Last 8 bits of the flags bitfield
dns_qdcount	equ 4		; Number of questions (2 bytes, big endian)
dns_ancount	equ 6		; Number of resource records
dns_nscount	equ 8		; Number of NS records
dns_arcount	equ 10		; Number of additional records

