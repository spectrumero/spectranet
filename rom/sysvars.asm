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

NMISTACK	equ 0x38FE

; General purpose small workspace for ROM modules. Each ROM page gets 8 bytes
; of workspace here. Work out the ROM's workspace location by taking the
; page number and multiplying by 8 (page number left shifted 3 times).
		org 0x3900
buf_moduleworkspace

; A table of BASIC extensions starts here.
; Entries should be structured as:
;  byte 0   - ZX error code that's relevant
;  byte 1,2 - pointer to command string
;  byte 3   - ROM page (0 if none)
;  byte 4,5 - pointer to routine to call
; The entire table should be null terminated.
		org 0x3A00
TABLE_basext

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
v_pr_pga	defb 0		; page A value storage for print routine
v_pga		defb 0		; Current memory page in area A
v_pgb		defb 0		; Current memory page in area B
v_utf8		defb 0		; utf-8 character state
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
; These are also used for VFS file descriptors, the idea being a write() or
; read() (etc) with a file descriptor should automatically Do The Right Thing.
;
FDBASE
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
v_buf_pga	defb 0		; original page A value on call to gethwsock
v_buf_pgb	defb 0		; original page B storage for buffer copies

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

; TNFS/VFS system variables
v_vfs_curmount	defb 0		; mount point currently in use
v_vfs_dirhandle	defb 0		; current directory handle in use
v_vfs_curfd	defb 0		; current file handle in use
v_trapfd	defb 0		; current tape trap fd
v_trap_blklen	defw 0		; block length of next block
v_vfs_sockinfo	defw 0,0	; IP of last received packet
		defw 0		; source port
		defw 0		; dest port

; ZX state storage
v_bankm		defb 0		; saved state of BANKM
v_bank678	defb 0		; saved state of BANK678

; Temporary register storage
v_asave		defb 0
v_hlsave	defw 0
v_desave	defw 0
v_bcsave	defw 0
v_ixsave	defw 0
v_pagerws	defw 0 		; register storage for the pager

; Miscellaneous TCP variables
v_localport	defw 0		; Storage for current local port for connect
v_sockfd	defb 0		; Storage for a socket file descriptor
v_connfd	defb 0		; Storage for a socket file descriptor

; RST8 variables for interpreter extensions
v_rst8vector	defw 0		; points to a routine to call
v_interpflags	defb 0		; flags
v_tabletop	defw 0		; Current top of interpreter table
v_errnr_save	defb 0		; Error number storage
v_chaddsave	defw 0		; Storage for CH_ADD
v_origpageb	defb 0		; Original page in paging area B

; VFS vector table
VFSVECBASE
v_fs1page 	defb 0		; Page number where the code lives
v_fs2page	defb 0
v_fs3page	defb 0
v_fs4page	defb 0

; File descriptor vector table
FDVECBASE
v_fd1page	defb 0		; ROM number where the table lives
v_fd2page	defb 0
v_fd3page	defb 0
v_fd4page	defb 0
v_fd5page	defb 0
v_fd6page	defb 0
v_fd7page	defb 0
v_fd8page	defb 0
v_fd9page	defb 0
VECOFFS		equ (FDVECBASE-FDBASE)%256

DIRVECBASE
MAX_DIRHNDS	equ 9
v_dhnd1page	defb 0
v_dhnd2page	defb 0
v_dhnd3page	defb 0
v_dhnd4page	defb 0
v_dhnd5page	defb 0
v_dhnd6page	defb 0
v_dhnd7page	defb 0
v_dhnd8page	defb 0
v_dhnd9page	defb 0

; VFS workspace
v_mountnumber	defb 0		; Current selected mount point
v_vfspgb_vecsave defb 0		; page area B original page numbers
v_vfs_workspace	defw 0		; short temp workspace for VFS code
VFSJUMP		jp 0x2000	; yes, it's self modifying code!

; ROM table - list of ROM pages with a valid vector table (max 31)
vectors		defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
pagealloc	defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
ROMVECOFFS	equ (vectors-2)%256

; Page storage
v_util_pgb	defb 0

; Machine type
v_plusthree	defb 0

; EOF handling
v_eofaddr	defw 0
v_eofrom	defb 0

; Reserve memory above 0x3FF8 for the jump table.
		block 0x3FF8-$,0xff
