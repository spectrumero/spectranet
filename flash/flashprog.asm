; Simple flash programmer for programming the Spectranet flash over
; the network. Values are hard coded at present; this is just a development
; tool to allow me to reprogram the flash ROM without needing to dig it out
; and put it in the flash programmer.
;
; It just dumbly programs 16K worth of data that gets sent over the network.
; It can either be left in one of the pages of the flash chip itself, and
; LDIR'd to its proper location, or stored on a DivIDE or other device and
; loaded when needed.
;
; It must run independently of the flash chip since we're going to erase and
; rewrite it! The easiest method is just run from RAM.
;
; Data is loaded just after the program's last used address.
;
	include "../experiments/w5100defines.asm"

	org 0xF000		; start with RAND USR 61440
	di
	call F_clear		; clear screen, setup print routine
	call F_w5100init	; initialize ethernet
	ld hl, STR_send
	call F_print
	
	; Ethernet setup is just hardcoded here; this is a simple single
	; purpose program. If you're looking at this for an example
	; of how to program for the Spectranet, this is a terrible example.
	; Don't follow it! It's done like this to be able to bootstrap
	; the board with a new flash program with very little other
	; support. Real programs should use the socket library.
.open	
	ld hl, 0x0100		; W5100 register page
	call F_setpageA	
	ld a, S_MR_TCP|S_MR_NDMC ; Create a TCP socket, no delayed ACK
	ld (Sn_MR), a		; as socket 0
	ld a, 23		; port 23
	ld (Sn_PORT1), a	; lsb of port address
	xor a
	ld (Sn_PORT0), a	; msb of port address
	ld a, S_CR_OPEN		; open the socket
	ld (Sn_CR), a
	ld a, (Sn_SR)		; check status
	cp S_SR_SOCK_INIT	; Open successfully?
	jr z, .listen		; if so listen for a new connection
	ld a, S_CR_CLOSE	; else give up
	ld (Sn_CR), a
	jp J_giveup
.listen
	ld hl, STR_open		; tell the user that we're ready
	call F_print
	ld a, S_CR_LISTEN
	ld (Sn_CR), a		; listen
	ld a, (Sn_SR)		; status register check
	cp S_SR_SOCK_LISTEN	
	jr z, .listening	; Status changed successfully
	ld a, S_CR_CLOSE	; if not give up
	ld (Sn_CR), a
	jp J_giveup
.listening
	ld a, (Sn_SR)		; Read status register
	cp S_SR_SOCK_ESTABLISHED ; and wait until something connects
	jr nz, .listening
.rxdata
	call F_pollsocket	; poll socket for incoming data
.recvaddrs
	ld de, v_reqaddr	; fill the address/size params
	ld bc, 4		; 4 bytes of data
	call F_copyrxbuf	; fill receive buffer
	ld hl, STR_dest
	call F_print
	ld hl, (v_reqaddr)
	call F_printhex
	ld hl, STR_len
	call F_print
	ld hl, (v_reqsize)
	call F_printhex
	ld hl, v_reqaddr	; duplicate requested addr/length params
	ld de, v_calladdr
	ldi
	ldi
	ldi
	ldi
.recvdata
	call F_pollsocket	; on exit h = msb of register pointer
	ld de, (v_reqaddr)	; address to copy to
	ld bc, 1024		; up to 1k at a time (it can be less)
	call F_copyrxbuf	; get data, bc=length actually copied
	ld hl, (v_reqaddr)
	add hl, bc
	ld (v_reqaddr), hl	; update memory pointer
	ld hl, (v_reqsize)
	sbc hl, bc		; deduct bytes copied
	ld a, h			; zero bytes left?
	or l
	jr z, .recvdone
	ld (v_reqsize), hl	; save bytes remaining
	jr .recvdata
.recvdone
	ld hl, Sn_CR		; command register
	ld (hl), S_CR_CLOSE	; close the socket
	ld a, (v_calladdr+1)	; check to see if this is a SCREEN$
	cp 0x40			; MSB is 0x40 for SCREEN$
	jp z, .open		; get another
	ld hl, STR_recvdone
	call F_print

	; calling 0x007C forces a pageout through the normal return
	; mechanism, or has no effect if not paged in.
	call 0x007C

	; now we can just use the ROM keyscan routine. Poll until we
	; find something of interest.
.getkeyloop
	call F_pollkeys
	cp 'j'			; jump to routine
	jr z, .jump
	cp 'f'
	jr z, .flash
	jr .getkeyloop

	; Jump to the start address of the block of data we just got.
.jump
	ld hl, (v_calladdr)
	jp (hl)

.flash	di
	ld a, 1			; page in our memory
	out (PAGERPORT), a
	ld hl, STR_erasing
	call F_print

	; Erase sector 0 of the flash chip.
	call F_FlashEraseSectorZero
	jr c, .erasefailed

	; Now map in page 1 and 2 of ROM, so the first three pages
	; are in a contiguous block.
	ld hl, 1	; chip 0 page 1
	call F_setpageA
	ld hl, 2	; chip 0 page 2
	call F_setpageB
	ld hl, STR_writing
	call F_print

	; now write a 16k block from the start address on up.
	ld hl, (v_calladdr)	; get the start address
	ld de, 0		; start from the bottom
	ld bc, 0x3000		; 12k of data to write in this first chunk
.writeloop
	ld a, (hl)
	call F_FlashWriteByte
	jr c, .writefailed
	inc hl
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .writeloop
	push hl			; now map in the remaining page
	ld hl, 3
	call F_setpageB
	pop hl			; hl will be pointing at the right byte
	ld de, 0x2000		; start of page B
	ld bc, 0x1000		; 4k of data left to go
.writeloop2
	ld a, (hl)
	call F_FlashWriteByte
	jr c, .writefailed
	inc hl
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .writeloop2

	ld hl, STR_donewriting
	call F_print
	halt

.erasefailed
	ld hl, STR_erasedied
	call F_print
	halt
.writefailed
	push hl
	ld hl, STR_writedied
	call F_print
	pop hl
	call F_printhex
	halt
	
J_giveup
	ld hl, STR_givenup
	call F_print
	halt

F_pollsocket
	ld a, (Sn_RX_RSR0)	; MSB of received bytes register
	ld hl, Sn_RX_RSR1	; LSB of received bytes register
	or (hl)			; OR together to see if zero
	jr z, F_pollsocket	; keep polling while zero
	ret

F_print
	ld a, (hl)
	and a
	ret z
	call putc_5by8
	inc hl
	jr F_print

; a modified version of baze's 16 bit integer hex conversion, which prints
; the result when done. Number to display is in hl.
F_printhex
	ld de, STR_hex
Num2Hex	ld a,h
	call Num1
	ld a,h
	call Num2
	ld a,l
	call Num1
	ld a,l
	call Num2
	ld hl, STR_hex
	call F_print
	ret

Num1	rra
	rra
	rra
	rra
Num2	or 0xF0
	daa
	add a,0xA0
	adc a,0x40

	ld (de),a
	inc de
	ret 

; Simple cls routine
F_clear
	ld hl, 16384
	ld de, 16385
	ld bc, 6144
	ld (hl), 0
	ldir
	ld (hl), 56	; attribute for white
	ld bc, 767
	ldir
	xor a
	ld (v_column), a
	ld (v_rowcount), a
	ld hl, 16384
	ld (v_row), hl
	ret

; Set paging area A. Page in HL (chip in H, page in L)
F_setpageA
	ld a, (v_chipsel)
	and 0xFC	; zero lower two bits
	or h		; insert chip select value
	ld (v_chipsel), a
	out (CHIPSEL), a
	ld a, l
	ld (v_pga), a	; store new page number
	out (PAGEA), a	; page it in
	ret

; Set paging area B. As for area A.
F_setpageB
	ld a, (v_chipsel)
	and 0xF3	; zero upper 2 bits of nibble
	rl h		; move chip select value into correct bits
	rl h		
	or h		; insert chip select value
	ld (v_chipsel), a
	out (CHIPSEL), a	
	ld a, l
	ld (v_pgb), a
	out (PAGEB), a	; page it in
	ret

; Use the Speccy rom plus a lookup table to turn a keypress (0-z)
; into an option.
F_pollkeys
.poll      
	call 0x28E      ; Spectrum ROM key poll routine
	ld a, e		; result is in E, move to A to test
	cp 0xFF		; No key pressed
	jr z, .poll
	push de		; save for later
.pollkeyup
	call 0x28E
	ld a, e
	cp 0xFF
	jr nz, .pollkeyup
	pop de
	ld hl, LK_keys ; Look up the key that was pressed
	ld d, 0
	add hl, de
	ld a, (hl)
	ret      

; asm modules - TODO: Eventually, these should be the same versions as
; the ROM versions, but for now, the experimental ones are the ones we
; have.
	include "../experiments/print5by8.asm"
	include "w5100config.asm"
	include "flashwrite.asm"
	include "../experiments/w5100buffer.asm"
	include "../experiments/charset.asm"
	block 0xF800-$,0xFF
	include "../experiments/rclookup.asm"

STR_send 	defb "Opening socket...",0
STR_open	defb "Done\n",0
STR_dest	defb "Receiving data:\n     destination = ",0
STR_len		defb "\n     length      = ",0
STR_givenup	defb "\nFailed (giving up)",0
STR_recvdone	defb "\nTransfer complete\nPress J to jump, F to flash\n",0
STR_erasing	defb "Erasing flash sector 0\n",0
STR_writing	defb "Writing data...\n",0
STR_donewriting defb "Complete.\n",0
STR_erasedied	defb "Erase failed\n",0
STR_writedied	defb "Write failed: src addr = ",0

v_pr_wkspc	defw 0
v_column	defb 0
v_rowcount	defb 0
v_row		defw 0
v_pga		defb 0
v_pgb		defb 0
v_chipsel	defb 0
v_sockptr	defw 0
v_copylen	defw 0
v_copied	defw 0
v_reqaddr	defw 0		; sent over the net
v_reqsize	defw 0		; sent over the net
v_calladdr	defw 0		; address to call on completion
v_length	defw 0		; length of data sent to us
STR_hex		defb 0,0,0,0,0	; 5 bytes to include the NUL

; various definitions
CHIPSEL		equ 0xED
PAGEA		equ 0xE9
PAGEB		equ 0xEB
PAGERPORT	equ 0xEF

 ; Simple key value lookup table.
LK_keys	defb 'b', 'h', 'y', '6', '5', 't', 'g', 'v'    ; 0-7
	defb 'n', 'j', 'u', '7', '4', 'r', 'f', 'c'    ; 8-15
	defb 'm', 'k', 'i', '8', '3', 'e', 'd', 'x'    ; 16-23
	defb 255, 'l', 'o', '9', '2', 'w', 's', 'z'   ; 24-31
	defb 255, 255, 'p', '0', '1', 'q', 'a'      ; 32-38
	block $+32-$, #ff


END	defb 0

