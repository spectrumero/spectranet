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

; A 512 byte block is reserved for network messages that are used in the
; normal course of communicating with the world, for example, UDP packets
; sent to a DNS server or received from a DNS server.
		org 0x3B00
buf_message

; A general purpose block at 0x3D00 is reserved for network functions.
; It is used as a 256-byte buffer for functions such as DNS query strings.
		org 0x3D00
buf_workspace

; The system variables live in chip 4 page 0 which is permanently mapped
; to 0x3000-0x3FFF. Specifically, they live in the upper part of this memory,
; the lower part being available as general purpose workspace.

		org 0x3F00
v_column	defb 0		; Current column for 42 col print.
v_row		defw 0		; Current row address for print routine
v_rowcount	defb 0		; current row number
v_pr_wkspc	defb 0		; Print routine workspace
v_pga		defb 0		; Current memory page in area A
v_pgb		defb 0		; Current memory page in area B
v_trappage	defb 0		; Page to select on programmable trap
v_trapaddr	defw 0		; Address to call on programmable trap
v_trapcomefrom	defw 0		; Address on stack when trap is triggered
v_sockptr	defw 0		; Socket register address
v_copylen	defw 0		; Socket copied bytes
v_copied	defw 0		; Socket bytes copied so far

; Socket mappings. These map a file descriptor (see the BSD socket library)
; to a hardware socket. The reason that hardware sockets are not used
; directly is that it'll make it mean a lot of dependent code would need
; a total rewrite if the hardware got changed. W5100 sockets work differently
; to the standard BSD library, and in any case, we don't want to limit
; ourselves to that particular IP implementation in any case.
;
; Most significant bits are flag bits.
;
v_fd1hwsock	defb 0		; hardware socket number
v_fd2hwsock	defb 0
v_fd3hwsock	defb 0
v_fd4hwsock	defb 0
v_fd5hwsock	defb 0
v_fd6hwsock	defb 0		; reserved in case of a W5300 board
v_fd7hwsock	defb 0
v_fd8hwsock	defb 0
v_fd9hwsock	defb 0
MAX_FDS		equ 5		; maximum number of file descriptors (W5100)
MAX_FD_NUMBER	equ v_fd5hwsock % 256
v_lastpolled	defb 0		; fd to start polling from
v_virtualmr	defb 0		; virtualized socket mode register value
v_virtualport	defw 0		; port for virtualized socket

; General purpose small workspace reserved for ROM routines (for short strings,
; numbers etc.)
v_workspace	defb 0,0,0,0,0,0,0,0
v_bufptr	defw 0		; buffer pointer
v_stringptr	defw 0		; temp storage for a string pointer
v_stringlen	defw 0		; temp storage for string lengths

; DNS system variables
v_seed		defw 0		; 16 bit random number seed
v_dnsserial	defw 0		; Serial number of current DNS query
v_dnsfd		defb 0		; file descriptor of DNS socket
v_fieldptr	defw 0		; field pointer for DNS strings
v_ansprocessed	defb 0		; answers processed so far
v_nameserver1	defb 0,0,0,0	; nameserver 1
v_nameserver2	defb 0,0,0,0	; nameserver 2
v_nameserver3	defb 0,0,0,0	; nameserver 3
v_nsend
v_dnssockinfo	defb 0,0,0,0,0,0,0,0	; DNS socket info
v_cur_resolver	defw 0		; pointer to IP address of current resolver
v_queryresult	defw 0		; address of query result buffer
v_querylength	defw 0		; query length in bytes
v_dnsretries	defb 0		; remaining retries from this server

; DHCP system variables
v_dhcpfd	defb 0		; file descriptor of DHCP socket
v_dhcpsockinfo	defb 0,0,0,0,0,0,0,0	; DHCP socket info
v_dhcpxid	defb 0,0,0,0	; XID
v_dhcpserver	defb 0,0,0,0	; Server that replied
v_dhcpreqaddr	defb 0,0,0,0	; Our requested address
v_dhcplease	defb 0,0,0,0	; lease in seconds
v_nspointer	defw 0		; nameserver address pointer

; ZX state storage
v_bankm		defb 0		; saved state of BANKM
v_bank678	defb 0		; saved state of BANK678

; Temporary register storage
v_hlsave	defw 0
v_desave	defw 0
v_bcsave	defw 0
v_pagerws	defw 0 		; register storage for the pager

; Miscellaneous TCP variables
v_localport	defw 0		; Storage for current local port for connect
v_sockfd	defb 0		; Storage for a socket file descriptor
v_connfd	defb 0		; Storage for a socket file descriptor

; RST8 variables for interpreter extensions
v_rst8vector	defw 0		; points to a routine to call
v_interpflags	defb 0		; flags

; ROM table - list of ROM pages with a valid vector table (max 31)
vectors		defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; Reserve memory above 0x3FF8 for the jump table.
		block 0x3FF8-$,0xff
