;The MIT License
;
;Copyright (c) 2010 Dylan Smith
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
.include	"dhcpdefs.inc"
.include	"sysvars.inc"
.data
.globl DHCPDISCOVER_BLOCK
DHCPDISCOVER_BLOCK:
; The following is a block that can be LDIR'd into the options offset
; for a DHCPDISCOVER message.
.globl dhcp_cookie
dhcp_cookie:    defb 0x63,0x82,0x53,0x63

; DHCP discover message options
.globl dhcp_discover
dhcp_discover:  defb 0x35,0x01,0x01 ; option 0x35, 1 byte long, value=1

; Parameter request list - ask for the subnet, router and domain
; name server
.globl dhcp_params
dhcp_params:    defb 0x37, 0x03, 0x01, 0x03, 0x06

; Specify the maximum message size - 768 bytes (buffer+workspace)
.globl dhcp_maxsize
dhcp_maxsize:   defb 0x39, 0x02, 0x03, 0x00

; Lease time request - 90 days
.globl dhcp_lease
dhcp_lease:     defb 0x33, 0x04, 0x00, 0x76, 0xa7, 0x00
.globl DHCPLEASE_OFFSET
DHCPLEASE_OFFSET	equ buf_message+dhcp_options+(dhcp_lease-DHCPDISCOVER_BLOCK)+2

; Identifier - our MAC address and hardware type
.globl dhcp_mac
dhcp_mac:       defb 0x3d, 0x07, 0x01   ; remaining 6 bytes must be filled

DHCPDISCOVER_BLOCKEND:
.globl DHCPBLOCKSZ
DHCPBLOCKSZ	equ DHCPDISCOVER_BLOCKEND-DHCPDISCOVER_BLOCK

