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
;
; English language messages for configuring the Spectranet.
;
.include	"ctrlchars.inc"
.data
.globl STR_choose
.globl STR_dhcp
.globl STR_ipaddr
.globl STR_netmask
.globl STR_gateway
.globl STR_hostname
.globl STR_pridns
.globl STR_secdns
.globl STR_hwaddr
.globl STR_save
.globl STR_cancel
STR_choose: defb NEWLINE,NEWLINE,"Choose a configuration option:",NEWLINE,0
STR_dhcp: defb "Enable/disable DHCP",0
STR_ipaddr: defb "Change IP address",0
STR_netmask: defb "Change netmask", 0
STR_gateway: defb "Change default gateway", 0
STR_hostname: defb "Change hostname", 0
STR_pridns: defb "Change primary DNS",0
STR_secdns: defb "Change secondary DNS",0
STR_hwaddr: defb "Change hardware address", 0
STR_save: defb "Save changes and exit",0
STR_cancel: defb "Cancel changes and exit",0

.globl STR_currset
.globl STR_usedhcp
.globl STR_currip
.globl STR_currmask
.globl STR_currgw
.globl STR_currhwaddr
.globl STR_currhost
.globl STR_currpridns
.globl STR_currsecdns
.globl STR_no
.globl STR_yes
.globl STR_bydhcp
.globl STR_vunset
STR_currset: defb "Current configuration",NEWLINE,"=====================",NEWLINE,0
STR_usedhcp: defb "Use DHCP         : ",0
STR_currip: defb "IP address       : ",0
STR_currmask: defb "Netmask          : ",0
STR_currgw: defb "Default gateway  : ",0
STR_currhwaddr: defb "Hardware address : ",0
STR_currhost: defb "Hostname         : ",0
STR_currpridns: defb "Primary DNS      : ",0
STR_currsecdns: defb "Secondary DNS    : ",0
STR_no: 	defb "No",NEWLINE,0
STR_yes: 	defb "Yes",NEWLINE,0
STR_bydhcp: defb "Set by DHCP",0
STR_vunset: defb "[unset]",0

.globl STR_abort
.globl STR_invalidip
.globl STR_dhcpquestion
.globl STR_askip
.globl STR_asknetmask
.globl STR_askgw
.globl STR_askhw
.globl STR_askhostname
.globl STR_askpridns
.globl STR_asksecdns
STR_abort: defb "Enter on a blank line aborts",NEWLINE,0
STR_invalidip: defb NEWLINE,"Sorry, that wasn't a valid address.",NEWLINE,0
STR_dhcpquestion: defb NEWLINE,"Use DHCP? (Y/N): ",0
STR_askip: defb NEWLINE,"IP address: ",0
STR_asknetmask: defb NEWLINE,"Netmask: ",0
STR_askgw: defb NEWLINE,"Gateway: ",0
STR_askhw: defb NEWLINE,"Hardware address: ",0
STR_askhostname: defb NEWLINE,"Hostname: ",0
STR_askpridns: defb NEWLINE,"Primary DNS: ",0
STR_asksecdns: defb NEWLINE,"Secondary DNS: ",0

.globl STR_saving
.globl STR_done
STR_saving: defb NEWLINE,"Saving configuration...",0
STR_done: defb "Done",NEWLINE,0

