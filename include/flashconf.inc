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
; These values are all offsets from the bottom of the paged in page.

CONFIGPAGE	equ 0x001F	; chip 0 page 0x1F (the last page)
CONF_RAM	equ 0x1F00	; config area, when copied to RAM
FS_CONF_RAM	equ 0x1D00	; config area for FS in RAM

; Default filesystems - up to 4 can be mounted
DEF_FS_MOUNT0	equ 0x0D00
DEF_FS_MOUNTPT0	equ 0x0D00	; mount point (0-3)
DEF_FS_PROTO0	equ 0x0D01	; Protocol (null terminated, max 6)
DEF_FS_HOST0	equ 0x0D07	; Hostname (max 41)
DEF_FS_SRCPTH0	equ 0x0D30	; Source path (max 48)
DEF_FS_USER0	equ 0x0D60	; Username (max 16)
DEF_FS_PASSWD0	equ 0x0D70	; Passord (max 16)

DEF_FS_MOUNT1	equ 0x0D80
DEF_FS_MOUNTPT1	equ 0x0D80	; mount point (0-3)
DEF_FS_PROTO1	equ 0x0D81	; Protocol (null terminated, max 6)
DEF_FS_HOST1	equ 0x0D87	; Hostname (max 41)
DEF_FS_SRCPTH1	equ 0x0DB0	; Source path (max 48)
DEF_FS_USER1	equ 0x0DE0	; Username (max 16)
DEF_FS_PASSWD1	equ 0x0DF0	; Passord (max 16)

DEF_FS_MOUNT2	equ 0x0E00
DEF_FS_MOUNTPT2	equ 0x0E00	; mount point (0-3)
DEF_FS_PROTO2	equ 0x0E01	; Protocol (null terminated, max 6)
DEF_FS_HOST2	equ 0x0E07	; Hostname (max 41)
DEF_FS_SRCPTH2	equ 0x0E30	; Source path (max 48)
DEF_FS_USER2	equ 0x0E60	; Username (max 16)
DEF_FS_PASSWD2	equ 0x0E70	; Passord (max 16)

DEF_FS_MOUNT3	equ 0x0E80
DEF_FS_MOUNTPT3	equ 0x0E80	; mount point (0-3)
DEF_FS_PROTO3	equ 0x0E81	; Protocol (null terminated, max 6)
DEF_FS_HOST3	equ 0x0E87	; Hostname (max 41)
DEF_FS_SRCPTH3	equ 0x0EB0	; Source path (max 48)
DEF_FS_USER3	equ 0x0EE0	; Username (max 16)
DEF_FS_PASSWD3	equ 0x0EF0	; Passord (max 16)

; TCP/IP settings. These are in the same order as the W5100's hardware
; registers so they can just be LDIR'd in.
IP_GATEWAY	equ 0x0F00	; Gateway address (4 bytes)
IP_SUBNET	equ 0x0F04	; Subnet mask (4 bytes)
HW_ADDRESS	equ 0x0F08	; Hardware address (MAC address: 6 bytes)
IP_ADDRESS	equ 0x0F0E	; IP address

; A bit field of initialization flags, and the definition.
INITFLAGS	equ 0x0F12
INIT_STATICIP	equ 1		; Static IP address configured
INIT_DISBLTRAP	equ 2		; Disable RST 8 traps on startup

; Hostname - a null terminated string, maximum 15 characters (16 bytes).
HOSTNAME	equ 0x0F13

; DNS servers, primary and secondary.
PRI_DNS		equ 0x0F24	; IP address of primary DNS server
SEC_DNS		equ 0x0F28	; IP address of secondary DNS server

; 16 bit cyclic redundancy check, in case a botched flash write (say,
; power loss during flashing, or an uninitialized chip) so the user
; can get notification if all is not well.
CONFIGCRC	equ 0x0FFE

