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

; DHCP client definitions.

; Initial header structure
dhcp_msglen	equ 548

; Offsets for DHCP structure
dhcp_op		equ 0
dhcp_htype	equ 1
dhcp_hlen	equ 2
dhcp_hops	equ 3
dhcp_xid	equ 4
dhcp_secs	equ 8
dhcp_flags	equ 10
dhcp_ciaddr	equ 12
dhcp_yiaddr	equ 16
dhcp_siaddr	equ 20
dhcp_giaddr	equ 24
dhcp_chaddr	equ 28
dhcp_sname	equ 44
dhcp_file	equ 108
dhcp_options	equ 236

; Certain hardcoded values that we'll always use
dhcp_opval	equ 1	; BOOTREQUEST
dhcp_htypeval	equ 1	; Hardware type = 1 (ethernet)
dhcp_hlenval	equ 6	; hardware address is 6 bytes long
dhcp_request	equ 3	; DHCP request option value
dhcp_msg_ack	equ 5	; DHCPACK

; Option identifiers that we need to use.
dhcp_opt_server	equ 0x36	; Server address
dhcp_opt_reqaddr equ 0x32	; Our requested address
dhcp_opt_lease	equ 0x33	; Lease, in seconds
dhcp_opt_gateway equ 0x03	; Default gateway 
dhcp_opt_netmask equ 0x01	; Netmask
dhcp_opt_dns	equ 0x06	; DNS server address
dhcp_opt_msg	equ 0x35	; Message type

dhcp_polltime	equ 50000	; how many times to poll when waiting

; Error return codes - DHCP
DHCP_NAK        equ 0xCF
DHCP_OPTNOTFOUND equ 0xCE
DHCP_TIMEOUT    equ 0xCD
DHCP_BAD_XID    equ 0xCC
DHCP_INTERRUPTED equ 0xCB

