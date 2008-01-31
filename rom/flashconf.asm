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

; This file simply contains some EQU values of some configuration
; information that may be stored in the last page of flash (i.e. nonvolatile)
; - things like our MAC address, IP address/netmask/gateway if statically
; set, whether to DHCP on boot.
;
; Note that at the hardware level, when modifying these values, the entire
; 16k flash sector must be copied to RAM, since the flash erase operation
; erases a minimum of one 16k sector. The modified image can then be
; copied back in. However, this does keep the chip count (and therefore
; PCB size down) if we don't need to battery back RAM or have an EEPROM.
;
; It is assumed that the configuration area will get put in paging area B.

CONFIGPAGE	equ 0x0020	; chip 0 page 0x20

; TCP/IP settings. These are in the same order as the W5100's hardware
; registers so they can just be LDIR'd in.
IP_GATEWAY	equ 0x2F00	; Gateway address (4 bytes)
IP_SUBNET	equ 0x2F04	; Subnet mask (4 bytes)
HW_ADDRESS	equ 0x2F08	; Hardware address (MAC address: 6 bytes)
IP_ADDRESS	equ 0x2F0E	; IP address

; A bit field of initialization flags, and the definition.
INITFLAGS	equ 0x2F0F
INIT_STATICIP	equ 1		; Static IP address configured
INIT_DISBLTRAP	equ 2		; Disable RST 8 traps on startup

