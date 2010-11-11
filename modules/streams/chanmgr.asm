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
.include	"spectranet.inc"
.include	"zxrom.inc"
.include	"zxsysvars.inc"
.include	"sysvars.inc"
.include	"defs.inc"
.include	"ctrlchars.inc"
.include	"streamvars.inc"
.text
; Channel manager - handles creation and deletion of channels

;------------------------------------------------------------------------
; F_connect_impl
; Implementation of the client connect routine.
; This routine is jumped into from the BASIC interpreter routine,
; arguments are stacked:
;	First entry: Stream number
;	Second: BASIC string for hostname
;	Third: Port number
; This function must restore the stack.
; It also initializes the stream's information structure. These are held
; in 0x1000-0x10FF. The format is:
;	byte 0:	write buffer number
;	byte 1: read buffer number
;	byte 2: write buffer pointer
;	byte 3: read buffer pointer
;	byte 4: file descriptor
;	byte 5: flags (bit 0 = socket or file)
.globl F_connect_impl
F_connect_impl:
	call F_fetchpage		; fetch our memory
	call c, F_allocpage
	jr c, .memerr1			; one already

	pop bc				; Get stream number
	ld (v_bcsave), bc		; save it

	pop de				; start addr of string
	pop bc				; length of string
	ld hl, INTERPWKSPC+5		; copy to workspace
	call F_basstrcpy

	ld hl, INTERPWKSPC+5		; Try to look up the supplied
	ld de, INTERPWKSPC		; hostname
	call GETHOSTBYNAME
	jr c, .sockerr31

	ld c, SOCK_STREAM		; Now try to connect to the host -
	call SOCKET			; open the socket...
	jr c, .sockerr31
	ld (INTERPWKSPC+4), a		; save the socket number

	pop bc				; get port number
	ld de, INTERPWKSPC		; address of IP address
	call CONNECT
	jr c, .sockerr41

	; All was well, so a channel can now be created and a stream
	; attached.
	ld a, (v_bcsave)		; Get channel number back
	call F_createchan		; Create/open channel and stream

	; initialize the output buffer
	ld a, (v_bcsave)
	rlca				; multiply by 8
	rlca
	rlca
	ld h, 0x10			; Address 0x10xx
	ld l, a

	call F_findfreebuf		; create a write buffer
	jr c, .nobufcleanup1
	ld (hl), a			; save the buffer number
	inc l
	call F_findfreebuf		; create a read buffer
	jr c, .nobufcleanup1
	ld (hl), a
	inc l

	ld (hl), 0			; Set write buffer pointer
	inc l
	ld (hl), 0			; Set read buffer pointer
	inc l				; Next address is the FD
	ld a, (INTERPWKSPC+4)
	ld (hl), a			; store the FD
	inc l
	ld (hl), 0			; clear flags bits

	call F_leave			; restore memory page A
	jp EXIT_SUCCESS

.memerr1:
	pop hl				; restore the stack
	pop hl
	pop hl
	pop hl
	ld hl, STR_nomem
	jp REPORTERR			; Report "Out of memory"

.sockerr1:				; TODO - better error routine
	pop hl
.sockerr11:
	pop hl
.sockerr21:
	pop hl
.sockerr31:
	pop hl
.sockerr41:
	call F_leave
	ld hl, STR_sockerr
	jp REPORTERR

.nobufcleanup1:
	ld a, (INTERPWKSPC+4)		; get the socket number back
.globl NOBUFCLEANUP
NOBUFCLEANUP:
	call CLOSE			; and close it
	ld a, (v_bcsave)		; clear down our data structure
	rlca
	rlca
	rlca
	ld h, 0x10
	ld l, a
	ld (hl), 0			; ensure any allocated bufs are freed
	inc l
	ld (hl), 0
	call F_leave
	ld hl, STR_nobuferr
	jp REPORTERR

;------------------------------------------------------------------------
; F_close_impl
; Implementation of the close routine.
; This routine is jumped into from the BASIC interpreter, argument is on
; the stack.
.globl F_close_impl
F_close_impl:
	call F_fetchpage
	pop hl				; Get channel number from stack.
	ld a, l
	ld (v_curchan), a		; store current channel value
	call F_close_main
	jr c, .closeerr2
	call F_leave
	call EXIT_SUCCESS

.closeerr2:
	call F_leave
	ld hl, STR_closeerr
	jp REPORTERR

.globl F_close_main
F_close_main:
	call F_findmetadata_a
.globl F_close_ix
F_close_ix:
	ld a, (ix+STRM_FD)		; fetch the FD
	and a				; Valid FD?
	ret z				; Stream not open, do nothing.
	ld l, (ix+STRM_FLAGS)		; get the flags
	push ix	
	bit BIT_ISFILE, l		; is a file?
	jr nz, .isfile4
	bit BIT_ISDIR, l		; is a directory?
	jr nz, .isdir4
	bit BIT_ISCTRL, l		; control channel?
	jr nz, .closedone4		; nothing to do.
	call CLOSE			; close the socket
.closedone4:
	pop hl				; get chan metadata start address
	ld d, h
	ld e, l
	inc de
	ld bc, BUFDATASZ-1
	ld (hl), 0			; clear down buffer info
	ldir
	push af				; save flags in case of error
	ld a, (v_curchan)		; get channel number
	call F_freemem			; Mark memory as free
	pop af
	ret
.isfile4:
	call VCLOSE
	jr .closedone4
.isdir4:
	call CLOSEDIR
	jr .closedone4

;------------------------------------------------------------------------
; F_listen_impl
; Implementation of the listen command
; Arguments on the stack: port number, channel number
.globl F_listen_impl
F_listen_impl:
	call F_fetchpage		; fetch our memory
	call c, F_allocpage
	jr c, .memerr5			; one already

	pop bc				; Get stream number
	ld (v_bcsave), bc		; save it

	; create the socket and make it listen.
	ld c, SOCK_STREAM
	call SOCKET
	jr c, .sockerr5
	ld (INTERPWKSPC), a		; save the socket number
	pop de				; get the port number
	call BIND			; and bind to the socket
	jr c, .sockerr5
	ld a, (INTERPWKSPC)		; fd
	call LISTEN			; make it listen
	jr c, .sockerr5

	; a listening socket has been created - now create the BASIC
	; structures
	ld a, (v_bcsave)		; create the metadata and buffers
	rlca				; multiply by 8
	rlca
	rlca
	ld h, 0x10			; Address 0x10xx
	add a, 4			; A=LSB of fd storage
	ld l, a

	; a listen socket doesn't have buffers, just store the
	; fd in the first byte of this stream's area
	ld a, (INTERPWKSPC)		; get the socket descriptor
	ld (hl), a

	ld a, (v_bcsave)		; get the channel number
	call F_createchan		; Create/open channel and stream
	set 6, (ix+IORCHAN)		; set "control channel flag"
	set 6, (ix+IOWCHAN)
	call F_leave
	jp EXIT_SUCCESS
.sockerr5:
	pop bc				; fix the stack
	call F_leave
	ld hl, STR_sockerr
	jp REPORTERR
.memerr5:
	pop bc				; fix the stack
	pop bc
	ld hl, STR_nomem
	jp REPORTERR			; Report "Out of memory"

;------------------------------------------------------------------------
; F_ctrl_impl
; Set up a control channel. Desired stream in A.
.globl F_ctrl_impl
F_ctrl_impl:
	call F_fetchpage		; fetch our memory
	call c, F_allocpage
	jr c, .memerr6			; one already

	ex af, af'
	call F_findmetadata_a		; find the metadata area
	ex af, af'
	ld (ix+STRM_FLAGS), ISCTRL
	ld (ix+STRM_FD), 1		; set FD value so close works

	call F_createchan		; Create/open channel and stream
	set 5, (ix+IORCHAN)		; set the "is control" bit
	set 5, (ix+IOWCHAN)
	call F_leave
	jp EXIT_SUCCESS
.memerr6:
	ld hl, STR_nomem
	jp REPORTERR

;------------------------------------------------------------------------
; F_accept_impl
; Accepts an incoming connection
.globl F_accept_impl
F_accept_impl:
	call F_fetchpage

	pop bc				; Get stream number
	ld (v_bcsave), bc		; save it

	pop bc				; get the stream to accept
	ld a, c
	rlca				; get a pointer to the
	rlca				; listening stream's metadata
	rlca
	add a, 4			; point at the listening fd
	ld h, 0x10
	ld l, a				; form the pointer in HL
	ld a, (hl)			; get the fd and try to accept
	call ACCEPT
	jr c, .sockerr7
	ld (INTERPWKSPC), a		; save the fd

	; Now create the metadata for this socket - like with connect,
	; we need a BASIC channel and a read and write buffer
	ld a, (v_bcsave)		; get the channel number
	call F_createchan		; Create/open channel and stream

	ld a, (v_bcsave)		; get the stream for the accepted skt
	rlca				; multiply by 8
	rlca
	rlca
	ld h, 0x10			; Address 0x10xx
	ld l, a

	call F_findfreebuf		; create a write buffer
	jr c, .nobufcleanup7
	ld (hl), a			; save the buffer number
	inc l
	call F_findfreebuf		; create a read buffer
	jr c, .nobufcleanup7
	ld (hl), a
	inc l

	ld (hl), 0			; Set write buffer pointer
	inc l
	ld (hl), 0			; Set read buffer pointer
	inc l				; Next address is the FD
	ld a, (INTERPWKSPC)
	ld (hl), a			; store the FD

	call F_leave			; restore memory page A
	jp EXIT_SUCCESS
.sockerr7:
	ld hl, STR_sockerr
	jp REPORTERR
.memerr7:
	ld hl, STR_nomem
	jp REPORTERR
.nobufcleanup7:
	ld a, (INTERPWKSPC)		; clean up the socket
	jp NOBUFCLEANUP

;------------------------------------------------------------------------
; F_createchan
; Creates the channel in BASIC and connects it to a stream
.globl F_createchan
F_createchan:
	ld (v_asave), a			; Save the argument
	call F_allocmem			; Allocate memory in ZX RAM
	push hl				; save the returned address
	ld de, 5			; calculate routine start addr
	add hl, de
	ex de, hl
	pop hl
	ld (hl), e			; set LSB
	inc hl
	push hl				; Save the address
	ld (hl), d			; set MSB
	inc hl
	push hl
	ld de, IOWROUTINE_LEN+3
	add hl, de			; calculate the rx routine start
	ex de, hl
	pop hl
	ld (hl), e			; set LSB
	inc hl
	ld (hl), d			; set MSB
	inc hl
	ld (hl), 'U'			; TODO: dynamically set this
	inc hl
	push hl				; save the address
	ex de, hl			; address to copy the IO routine from
	ld hl, IOROUTINE
	ld bc, IOROUTINE_LEN
	ldir				; copy the stub
	pop ix				; get start addr into IX
	ld a, (v_asave)			; get the stream number
	ld (ix+IOWCHAN), a		; Set write ID
	set 7, a			; set MSB
	ld (IX+IORCHAN), a		; Set read ID
	pop hl				; retrieve the 2nd byte address
	ld de, (ZX_CHANS)		; get CHANS sysvar
	and a				; and calculate the offset
	sbc hl, de
	ex de, hl
	ld hl, ZX_STRMS
	ld a, (v_asave)			; Get the stream number
	and 0x0F			; mask out the flag bits
	add a, 0x03			; Calculate the offset
	add a, a			; and put it into HL
	ld b, 0
	ld c, a
	add hl, bc
	ld (hl), e			; LSB of 2nd byte of channel data
	inc hl
	ld (hl), d			; MSB of 2nd byte of channel data
	ret

;---------------------------------------------------------------------------
; F_allocmem
; Allocates memory for the new stream.
; Stream number should be in v_asave.
; Returns the address of the memory block in HL
.globl F_allocmem
F_allocmem:
	call F_has_zxprog_fallen	; check local vars are valid
	ld hl, (stream_memptr)		; look for a free memory slot
	ld a, h
	or l
	jr z, .makeroom9			; Make a new one
	dec l				; Point at the top most entry
	dec l				; on the list of free blocks.
	ld e, (hl)			; We have a slot, get its
	inc l				; address into DE
	ld d, (hl)
	dec l				; rewind HL to point at current entry
	ld a, memptr_bottom % 256	; have we hit the bottom?
	cp l
	jr nz, .updatememptr9
	ld hl, 0			; no free blocks - clear the pointer
.updatememptr9:
	ld (stream_memptr), hl		; zero it, since there's no slots
	ex de, hl
	jr .setusedblock9

.makeroom9:
	ld hl, (ZX_PROG)		; get the start of the program area
	ld bc, (original_zx_prog)
	ld a, b
	or c
	jr nz, .makeroom19
	ld (original_zx_prog), hl	; save the original PROG variable
.makeroom19:
	dec hl				; pointer to where to make space
	ld bc, CHAN_LEN			; request this many bytes
	rst CALLBAS
	defw ZX_MAKE_ROOM		; allocate memory
	ld de, (ZX_PROG)
	ld (current_zx_prog), de	; save current PROG address
	inc hl				; point at 1st byte of channel area

.setusedblock9:
	ld a, (v_asave)			; get stream number
	rlca				; multiply by 2
	add a, chmemptr_bottom % 256	; and add the bottom offset
	ex de, hl			; move block address to DE
	ld h, chmemptr_bottom / 256	; get address to save the block
	ld l, a				; address into HL
	ld (hl), e			; save it
	inc l
	ld (hl), d
	ex de, hl

	ret

;--------------------------------------------------------------------------
; F_freemem
; Puts the block associated with this stream in the free block list.
.globl F_freemem
F_freemem:
	rlca				; multiply by 2 the stream number
	add a, chmemptr_bottom % 256	; add the offset
	ld h, chmemptr_bottom / 256
	ld l, a				; HL = address
	ld e, (hl)
	inc l
	ld d, (hl)			; DE = address of block now free
	
	ld hl, (stream_memptr)
	ld a, h
	or l
	jr nz, .saveblockaddr10
	ld hl, memptr_bottom		; First entry
.saveblockaddr10:
	ld (hl), e			; save the address of the free
	inc l				; block.
	ld (hl), d
	inc l
	ld (stream_memptr), hl		; save the free block pointer
	ret

;------------------------------------------------------------------------
; F_reclaim_strmem
; Gets the ZX ROM to reclaim all the memory we used for channel stubs.
.globl F_reclaim_strmem
F_reclaim_strmem:
	ld de, (original_zx_prog)	; First byte to reclaim
	ld hl, (current_zx_prog)	; First byte to leave untouched
	rst CALLBAS
	defw ZX_RECLAIM_1		; move the BASIC program back
J_resetvars:
	ld hl, 0
	ld (current_zx_prog), hl	; clear down the variables
	ld (original_zx_prog), hl
	ld (stream_memptr), hl
	ret

;-----------------------------------------------------------------------
; F_has_zxprog_fallen
; If ZX_PROG is smaller than current_zx_prog it is likely the user
; has done NEW. At this point we should reset everything.
.globl F_has_zxprog_fallen
F_has_zxprog_fallen:
	or a				; make sure carry is cleared
	ld hl, (ZX_PROG)
	ld de, (current_zx_prog)
	sbc hl, de
	ret nc				; ZX_PROG has not fallen - OK.
	
	; ZX_PROG has fallen so something (NEW, likely) has just
	; killed all of our streams.
	ld a, 1
.closeall12:
	ld (v_curchan), a
	call F_findmetadata_a
	ld a, (ix+STRM_FD)		; open stream?
	and a				; nonzero = open
	call nz, F_close_ix		; close the stream...
	ld a, (v_curchan)
	inc a
	cp 0x10				; last possible stream is 0x0F
	jr nz, .closeall12
	jr J_resetvars			; reset our sysvars

; debugging
.globl F_debugA
F_debugA:
	push af
	push hl
	push de
	push bc
	ld hl, 0x3600
	call ITOH8
	ld hl, 0x3600
	call PRINT42
	ld a, NEWLINE
	call PUTCHAR42
	pop bc
	pop de
	pop hl
	pop af
	ret

;--------------

IOROUTINE:
	ld h, STREAM_ROM_ID		; our ROM ID
IOWCHAN:	equ ($+1)-IOROUTINE		; the byte to modify
	ld l, 0				; will be modified to provide channel
	call MODULECALL
	ret
IOWROUTINE_LEN	equ $-IOROUTINE

IORROUTINE:
	ld h, STREAM_ROM_ID
IORCHAN: equ ($+1)-IOROUTINE
	ld l, 0
	call MODULECALL
	bit 0, l			; need to do stack munging?
	jr z, .munge13
	ret
.munge13:
	ld sp, (ZX_ERR_SP)		; Clear machine stack
	pop de				; Remove ED-ERROR
	pop de				; Old value of SP is restored
	ld (ZX_ERR_SP), de
	ret

IOROUTINE_LEN 	equ $-IOROUTINE
CHAN_LEN	equ IOROUTINE_LEN + IOROUTINE_LEN + 5
IORROUTINE_LEN	equ $-IORROUTINE

