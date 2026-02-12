;The MIT License
;
;Copyright (c) 2011 Dylan Smith
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

; This puts on an initial configuration. It should be run after the
; ROM has been programmed, because it uses socket library functions.
.include "spectranet.inc"
.include "flashconf.inc"
.include "sysvars.inc"
.include "sysdefs.inc"
.include "ctrlchars.inc"
.include "sockdefs.inc"

.text
.globl F_config
F_config:
	ld hl, STR_keypress
	call F_print
	
	; wait for BREAK
.brk:
	ld bc, 0x7ffe
	in a, (c)
	cp 0xBE
	jr nz, .brk
	
	; initialize the sysvars
        ld hl, 0x3000           ; Clear down the fixed RAM page.
        ld de, 0x3001
        ld bc, 0xFFF
        ld (hl), l
        ldir

        ; Initialize some system variables that need it.

        ; Set all sockets to the closed state.
        ld hl, v_fd1hwsock      ; set all sockets to closed
        ld de, v_fd1hwsock+1
        ld bc, MAX_FDS
        ld (hl), 0x80           ; MSB set = closed socket
        ldir

        ; Set pollall() 'last file descriptor' to the first fd
        ld a, v_fd1hwsock % 256
        ld (v_lastpolled), a

        ld a, TNFSROM           ; ROM page where jumptable lives
        call F_setpageA         ; and page into paging area A.

	; copy the jump table which should be programmed by now
        ld hl, JUMPTABLE_COPYFROM
        ld de, 0x3E00           ; jump table start
        ld bc, JUMPTABLE_SIZE
        ldir

        ; Copy the page-in instructions (for the CALL trap)
        ld hl, UPPER_ENTRYPT
        ld de, 0x3FF8
        ld bc, UPPER_ENTRYPT_SIZE
        ldir

	; initialization is now complete.
	; We can now use Spectranet ROM functions to set up the
	; configuration.
        ; Set an initial local port number for connect()
        call RAND16
        set 6, h                ; make sure we start with a highish number
        ld (v_localport), hl    ; set initial local port address

	call CLEAR42
	ld hl, STR_configuring
	call PRINT42

	call F_iface_wait	; wait for the interface to be ready
	jp c, F_fail
	ld hl, TMP_HW_ADDRESS	; set the hardware address
	call INITHW		; and initialize the chip
	ld hl, TMP_IP_ADDRESS
	call IFCONFIG_INET	; set up IPv4 configuration
	ld hl, TMP_IP_SUBNET
	call IFCONFIG_NETMASK
	ld hl, TMP_IP_GATEWAY
	call IFCONFIG_GW
	ld hl, PRI_DNS
	ld de, v_nameserver1
	ld bc, 4
	ldir
	ld hl, v_ethflags
	set 0, (hl)

	; Now go and try to contact the config server.
	ld hl, STR_getcfg
	call PRINT42

	ld hl, STR_lookingup
	call PRINT42	
	ld hl, IP_cfgserv
	ld de, BUF_CONFIG
	call GETHOSTBYNAME
	jp c, F_fail

	ld hl, STR_connecting
	call PRINT42
	ld c, SOCK_STREAM
	call SOCKET
	jp c, F_fail
	ld (v_fd), a
	ld de, BUF_CONFIG
	ld bc, IP_cfgport
	call CONNECT
	jp c, F_fail

	ld hl, STR_receiving
	call PRINT42
	ld a, (v_fd)
	ld de, BUF_CONFIG
	ld bc, DATASZ
	call RECV
	jr c, F_fail

	ld a, (v_fd)
	call CLOSE

	; Clear out the configuration buffer first.
.configure:
	ld hl, BUF_makeconfig
	ld de, BUF_makeconfig+1
	ld bc, 0xFF
	xor a
	ld (hl), a
	ldir

	; Set DHCP on (A is already zero)
	ld (BUF_makeconfig+OFS_INITFLAGS), a

	; Copy hw address
	ld hl, BUF_CONFIG
	ld de, BUF_makeconfig+OFS_HW_ADDRESS
	ld bc, 6
	ldir

	; Copy hostname
	ld hl, BUF_CONFIG+6
	ld de, BUF_makeconfig+OFS_HOSTNAME
	ld bc, 16
	ldir
	
	; Erase the flash
	ld hl, STR_erasing
	call PRINT42
	ld a, CONFIG_PAGE&0xFC	; Beginning page of sector
	call F_FlashEraseSector
	jr c, F_fail

	ld hl, STR_writing
	call PRINT42
	ld a, CONFIG_PAGE	; Configuration flash page
	call SETPAGEB
	ld hl, BUF_makeconfig
	ld de, 0x2F00
	ld bc, 0xFF
	call F_FlashWriteBlock		; Write the configuration
	jr c, F_fail

	; Create the configuration variables
	xor a
	ld (BUF_makeconfig+1), a
	cpl
	ld (BUF_makeconfig+2), a	; end marker
	ld (BUF_makeconfig+3), a
	ld a, 2
	ld (BUF_makeconfig), a		; complete size, 0x0002 bytes
	ld hl, BUF_makeconfig
	ld de, 0x2000
	ld bc, 4
	call F_FlashWriteBlock
	jr c, F_fail

.done:
	ld hl, STR_done
	call PRINT42
	ei
	ret

F_fail:
	ld hl, STR_configfailed
	call PRINT42
	ei
	ret

;------------------------------------------------------------------------
; F_iface_wait
; Wait for the interface to come up. Work around the W5100 hardware bug
; by resetting the chip if we don't get a stable link.
; Check that the CPLD is a version that can detect link state.
F_iface_wait:
        ei                      ; HALT will be used for timing
        halt                    ; ensure read occurs when ULA is not reading
                                ; screen memory (prototype CPLD does not
                                ; have this port and returns 0xFF)
        ld bc, CPLDINFO         ; CPLD information port
        in a, (c)
        cp 0xFF                 ; 0xFF = prototype CPLD which does not have
        jr z, .prototype
        ld hl, STR_wait
        call PRINT42
        ei                      ; HALT used for timing
        call .reset             ; ensure chip is reset

        ld b, 5                 ; how many times to try
.linkloop:
        push bc
        ld d, 200               ; wait for 200 frames (4 seconds) maximum
.waitloop:
        ld bc, CTRLREG
        in a, (c)
        bit 6, a                ; if the light's on this goes to zero
        jr z, .testlinked
        halt                    ; wait 20ms
        dec d
        jr nz, .waitloop        ; check register again
.reenter:
        call .reset             ; try again
        pop bc
        djnz .linkloop

        di
        ld hl, STR_fail
        call PRINT42
        scf                     ; interface didn't come up
        ret
.linked:
        di
        pop bc                  ; restore stack
        ld hl, STR_linkup
        call PRINT42
        or a                    ; ensure carry is cleared
        ret
        ; check the link is stable - the link light must remain on for
        ; 50% of the time for 1 second.
.testlinked:
        ld a, '>'
        call PUTCHAR42
        ld h, 50                ; frames to wait
        ld e, 0                 ; count of LED lit
.linktestloop:
        in a, (c)               ; get status register
        bit 6, a                ; test LINK value
        jr nz, .continue        ; not lit - do not increment counter
        inc e
.continue:
        halt
        dec h                   ; decrement loop count
        jr nz, .linktestloop
        ld a, 25                ; link light must be on >= this amount
        cp e
        jr c, .linked           ; exit the routine
        jr .reenter             ; re-enter wait-for-link loop

.reset:
        ld a, '.'
        call PUTCHAR42          ; print a dot
        ld bc, CTRLREG
        in a, (c)               ; get current control register
        res 7, a                ; reset RESET bit
        out (c), a              ; ensure RESET bit is low
        halt                    ; wait at least 20ms
        halt
        set 7, a                ; release RESET bit
        out (c), a
        ret

        ; The prototype CPLD flips the toggle flip flop for programmable
        ; traps every time the trap port is touched; it is not mixed with
        ; the !WR signal. So we have to read it one more time to set it
        ; back to its proper start position.
.prototype:
        in a, (c)               ; note: BC will already be set
        di
        ret

.data
TMP_HW_ADDRESS:	defb 00,0xAA,01,02,03,04
TMP_IP_ADDRESS:	defb 172,16,0,101
TMP_IP_GATEWAY:	defb 172,16,0,1
TMP_IP_SUBNET:	defb 255,255,255,0

STR_getcfg:	defb "Getting configuration...",NEWLINE,0
STR_fail:	defb "Failed!",NEWLINE,0
STR_linkup:	defb "OK",NEWLINE,0
STR_wait:	defb "Link",0
STR_configfailed:	defb "Configuration failed",NEWLINE,0
STR_lookingup:	defb "Looking up config server...",NEWLINE,0
STR_connecting:	defb "Connecting",NEWLINE,0
STR_receiving:	defb "Receiving data",NEWLINE,0
STR_done:	defb "Configuration done",NEWLINE,0
STR_configuring: defb "Initial configuration tool started",NEWLINE,0
STR_erasing:	defb "Erasing config area",NEWLINE,0
STR_writing:	defb "Writing config",NEWLINE,0
STR_keypress:	defb "Press BREAK to start config",NEWLINE,0

IP_cfgserv:	defb "172.16.0.3",0

; Definitions
SET_INITFLAGS	equ	0x00	; DHCP enabled
IP_cfgport	equ	2001
DATASZ		equ	24	; configuration data size

JUMPTABLE_COPYFROM:     equ 0x1F00
JUMPTABLE_SIZE:         equ 0xF8
UPPER_ENTRYPT:          equ 0x1FF8
UPPER_ENTRYPT_SIZE:     equ 0x08

; space reserved to receive config data
.bss
v_fd:		defb 0		; space for the socket handle
BUF_CONFIG:	defw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
BUF_makeconfig:

