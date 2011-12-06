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
		

	; Assumptions: The W5100 is paged into paging area A (0x1000)
	; for register manipulation.
	; Register definitions for the W5100. Offset by 0x1000 bytes.

	; Common registers.
MR	equ	0x1000	; Mode register
GAR0	equ	0x1001	; Gateway addr first octet
GAR1	equ	0x1002
GAR2	equ	0x1003
GAR3	equ	0x1004
SUBR0	equ	0x1005	; Subnet mask, first octet
SUBR1	equ	0x1006
SUBR2	equ	0x1007
SUBR3	equ	0x1008
SHAR0	equ	0x1009	; Our ethernet address, first of 6
SHAR1	equ	0x100A
SHAR2	equ	0x100B
SHAR3	equ	0x100C
SHAR4	equ	0x100D
SHAR5	equ	0x100E
SIPR0	equ	0x100F	; First octet of our IP address
SIPR1	equ	0x1010
SIPR2	equ	0x1011
SIPR3	equ	0x1012
IR	equ	0x1015	; Interrupt register
IMR	equ	0x1016	; Interrupt mask
RTR0	equ	0x1017	; Retry time
RTR1	equ	0x1018
RCR	equ	0x1019	; Retry count register
RMSR	equ	0x101A	; RX memory size
TMSR	equ	0x101B	; TX memory size
PATR0	equ	0x101C	; PPPoE authentication type
PATR1	equ	0x101D
PTIMER	equ	0x1028	; PPPoE LCP request timer
PMAGIC	equ	0x1029	; PPPoE LCD magic number
UIPR0	equ	0x102A	; Unreachable IP address 1st octet
UIPR1	equ	0x102B
UIPR2	equ	0x102C
UIPR3	equ	0x102D
UPORT0	equ	0x102E	; Unreachable port (big endian)
UPORT1	equ	0x102F

	; Socket registers (base address - socket 0)
Sn_BASE	equ	0x04	; amount to subtract from addr. to
			; derive buffer base
Sn_MAX	equ	0x18	; high byte of highest socket reg.
Sn_MR	equ	0x1400	; Socket 0 mode
Sn_CR	equ	0x1401	; Socket 0 command
Sn_IR	equ	0x1402	; Socket 0 interrupt
Sn_SR	equ	0x1403	; Socket 0 status
Sn_PORT0 equ	0x1404	; Socket 0 port (big endian)
Sn_PORT1 equ	0x1405
Sn_DHAR0 equ	0x1406	; socket 0 destination ethernet addr.
Sn_DHAR1 equ	0x1407
Sn_DHAR2 equ	0x1408
Sn_DHAR3 equ	0x1409
Sn_DHAR4 equ	0x140A
Sn_DHAR5 equ	0x140B
Sn_DIPR0 equ	0x140C	; Socket 0 destination IP addr.
Sn_DIPR1 equ	0x140D
Sn_DIPR2 equ	0x140E
Sn_DIPR3 equ	0x140F
Sn_DPORT0 equ	0x1410	; Socket 0 dest port (big endian)
Sn_DPORT1 equ	0x1411
Sn_MSSR0 equ	0x1412	; Socket 0 max segment size
Sn_MSSR1 equ	0x1413
Sn_PROTO equ	0x1414	; Socket 0 proto in IP raw mode
Sn_TOS	equ	0x1415	; Type of service
Sn_TTL	equ	0x1416	; Socket 0 time-to-live
Sn_TX_FSR0 equ	0x1420 ; Socket 0 free size
Sn_TX_FSR1 equ	0x1421 ; (big endian)
Sn_TX_RD0 equ	0x1422	; TX read pointer
Sn_TX_RD1 equ	0x1423	; TX read pointer
Sn_TX_WR0 equ	0x1424 ; TX write pointer
Sn_TX_WR1 equ	0x1425 ;
Sn_RX_RSR0 equ	0x1426 ; Socket 0 received size
Sn_RX_RSR1 equ	0x1427
Sn_RX_RD0 equ	0x1428 ; Socket 0 RX read pointer
Sn_RX_RD1 equ	0x1429

	; Register bit values for ORing into bitfields
	; Mode register
MR_IND equ	1	; Set for indirect bus IF mode
MR_AI equ	2	; Set for address auto increment
MR_PPPoE equ	8	; Use PPPoE
MR_PB	equ	16	; Set ping block
MR_RST	equ	128	; Software reset

	; Interrupt register
IR_S0_INT equ	1	; Socket 0 interrupt enable
IR_S1_INT equ	2	; Socket 1 EI
IR_S2_INT equ	4	
IR_S3_INT equ	8
IR_PPPoE equ	32	; PPPoE interrupts
IR_UNREACH equ	64	; Dest unreachable interrupt
IR_CONFLICT equ	128	; IP conflict interrupt

	; Interrupt mask register - as interrupt register.
IM_S0_INT equ	1
IM_S1_INT equ	2
IM_S2_INT equ	4
IM_S3_INT equ	8
IM_PPPoE equ	32
IM_UNREACH equ	64
IM_CONFLICT equ	128

	; Socket modes
S_MR_CLOSED equ		0
S_MR_TCP equ		1
S_MR_UDP equ		2
S_MR_IPRAW equ		3
S_MR_MACRAW equ		4
S_MR_PPPoE equ		5
S_MR_NDMC equ		32	; Use no delayed ACK
S_MR_MULTI equ		128	; enable multicasting

	; Socket commands
S_CR_OPEN equ	1
S_CR_LISTEN equ	2
S_CR_CONNECT equ	4
S_CR_DISCON equ	8
S_CR_CLOSE equ	0x10
S_CR_SEND equ	0x20
S_CR_SEND_MAC equ	0x21
S_CR_SEND_KEEP	equ	0x22
S_CR_RECV equ		0x40

	; Interrupt register
S_IR_CON equ		1	; Connected
S_IR_DISCON equ	2	; Disconnected
S_IR_RECV equ	4	; Data received
S_IR_TIMEOUT equ	8	; Timeout occurred
S_IR_SEND_OK equ	16	; Send completed
	
	; poll(2) definitions (see above)
POLLIN	equ	5	/* S_IR_RECV | S_IR_CON */
POLLHUP	equ	2	/* S_IR_DISCON - output only */

	; Bit version of the above
BIT_IR_CON equ		0	
BIT_IR_DISCON equ	1
BIT_IR_RECV equ		2
BIT_IR_TIMEOUT equ	3
BIT_IR_SEND_OK equ	4

	; Status register - values, not bits
S_SR_SOCK_CLOSED equ	0x00	; Socket is closed	
S_SR_SOCK_INIT equ	0x13	; Socket is initialized
S_SR_SOCK_LISTEN equ	0x14	; Listen state
S_SR_SOCK_ESTABLISHED equ	 0x17 ; Connection establised
S_SR_SOCK_CLOSE_WAIT equ	0x1C ; CLOSE_WAIT state
S_SR_SOCK_UDP equ	0x22	; UDP socket
S_SR_SOCK_IPRAW	equ	0x32	; Raw socket
S_SR_SOCK_MACRAW equ	0x42	; Raw ethernet
S_SR_SOCK_PPPOE	equ	0x5F	; PPPoE socket
S_SR_SOCK_SYNSENT equ	0x15	; SYN_SENT state
S_SR_SOCK_SYNRECV equ	 0x16	; SYN_RECV
S_SR_SOCK_FIN_WAIT equ	0x18	; FIN_WAIT
S_SR_SOCK_CLOSING equ	0x1A	; Closing the socket
S_SR_SOCK_TIME_WAIT equ	0x1B ; TIME_WAIT
S_SR_SOCK_LAST_ACK equ	0x1D
S_SR_SOCK_ARP1 equ	0x11
S_SR_SOCK_ARP2 equ	0x21
S_SR_SOCK_ARP3 equ	0x31

REGISTER_PAGE equ	0x80	; external mem page 0
BUFFER_PAGE equ		0x81	; external mem page 1
MEMMGMT	equ		0xE0	; memory manager port

INVALID_SOCKNUM	equ	4	; >=4 is not valid.

	; Buffer memory should be paged into area A.
gSn_RX_BASE equ	0x1000
gSn_RX_MASK equ	0x07FF
gSn_TX_BASE equ	0x1000
gSn_TX_MASK equ	0x07FF

; Definitions not of the W5100 chip, rather just concerining it.
; Hardware pages
RX_LWRDATAPAGE	equ 0x46
RX_UPRDATAPAGE	equ 0x47
TX_LWRDATAPAGE	equ 0x44
TX_UPRDATAPAGE	equ 0x45
REGPAGE		equ 0x40

