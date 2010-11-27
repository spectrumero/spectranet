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

; File that builds the TNFS ROM library.

; TNFS sysvars. These live in the page of RAM that we claim on initialization.
; The page of RAM is paged at area A (0x1000-0x1FFF)

v_tnfs_retriesleft	equ 0x1000	; Retries remaining before giving up
v_curmountpt		equ 0x1001	; Current mount point
v_tnfs_sid0		equ 0x1002	; Session identifiers
v_tnfs_sid1		equ 0x1004
v_tnfs_sid2		equ 0x1006
v_tnfs_sid3		equ 0x1008
v_read_destination	equ 0x100A	; address for read to return data
v_curfd			equ 0x100C	; current file descriptor in use
v_bytesread		equ 0x100D	; byte read counter for current op
v_byteswritten		equ 0x100F	; byte write counter

v_tnfs_seqno0		equ 0x101A	; Sequence number storage
v_tnfs_seqno1		equ 0x101B
v_tnfs_seqno2		equ 0x101C
v_tnfs_seqno3		equ 0x101D

v_tnfs_sock		equ 0x101E

v_tnfs_sockinfo0	equ 0x1020
v_tnfs_sockinfo1	equ 0x1028
v_tnfs_sockinfo2	equ 0x1030
v_tnfs_sockinfo3	equ 0x1038

; TODO: each mount point should have its own poll time parameters
v_tnfs_polltime		equ 0x1040	; current poll time in 50ths/sec
v_tnfs_backoff		equ 0x1041	; have we backed off yet?
v_tnfs_tx_de		equ 0x1042	; DE for transmit
v_tnfs_tx_bc		equ 0x1044	; BC for transmit
v_tnfs_tx_hl		equ 0x1046	; HL for transmit
v_tnfs_initpolltime	equ 0x1048	; poll time to use on first poll
v_tnfs_lastpolladj	equ 0x1049	; how many packets since last adjust.

HANDLESPACE		equ 0x1100	; Handle information storage space
HMETASPACE		equ 0x1200	; Handle metadata storage space

v_cwd0			equ 0x1800	; current working directory
v_cwd1			equ 0x1900	; for mount points 0 to 4
v_cwd2			equ 0x1A00
v_cwd3			equ 0x1B00

tnfs_recv_buffer	equ 0x3500	; up to 512 bytes + header
buf_tnfs_wkspc		equ 0x3B00	; up to 512 bytes + header
