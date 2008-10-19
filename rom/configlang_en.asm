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
STR_choose	defb "\n\nChoose a configuration option:\n",0
STR_dhcp	defb "Enable/disable DHCP",0
STR_ipaddr	defb "Change IP address",0
STR_netmask	defb "Change netmask", 0
STR_gateway	defb "Change default gateway", 0
STR_hostname	defb "Change hostname", 0
STR_pridns	defb "Change primary DNS",0
STR_secdns	defb "Change secondary DNS",0
STR_hwaddr	defb "Change hardware address", 0
STR_save	defb "Save changes and exit",0
STR_cancel	defb "Cancel changes and exit",0

STR_currset	defb "Current configuration\n=====================\n",0
STR_usedhcp	defb "Use DHCP         : ",0
STR_currip	defb "IP address       : ",0
STR_currmask	defb "Netmask          : ",0
STR_currgw	defb "Default gateway  : ",0
STR_currhwaddr	defb "Hardware address : ",0
STR_currhost	defb "Hostname         : ",0
STR_currpridns	defb "Primary DNS      : ",0
STR_currsecdns	defb "Secondary DNS    : ",0
STR_no		defb "No\n",0
STR_yes		defb "Yes\n",0
STR_bydhcp	defb "Set by DHCP",0
STR_unset	defb "[unset]",0

STR_abort	defb "Enter on a blank line aborts\n",0
STR_invalidip	defb "\nSorry, that wasn't a valid address.\n",0
STR_dhcpquestion defb "\nUse DHCP? (Y/N): ",0
STR_askip	defb "\nIP address: ",0
STR_asknetmask	defb "\nNetmask: ",0
STR_askgw	defb "\nGateway: ",0
STR_askhw	defb "\nHardware address: ",0
STR_askhostname	defb "\nHostname: ",0
STR_askpridns	defb "\nPrimary DNS: ",0
STR_asksecdns	defb "\nSecondary DNS: ",0

STR_saving	defb "\nSaving configuration...",0
STR_done	defb "Done\n",0
STR_erasebork	defb "Erase failed\n",0
STR_writebork	defb "Write failed\n",0

