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
.include	"ctrlchars.inc"

; English NMI menu strings
.data
.globl STR_config
STR_config:	defb "Configure network settings",0
.globl STR_rom
STR_rom:	defb "Add and remove ROM modules",0
.globl STR_loader
STR_loader:	defb "Load arbitrary data to RAM",0
.globl STR_snapshot
STR_snapshot:	defb "Snapshot manager",0
.globl STR_exit
STR_exit:	defb "Exit",0
.globl STR_nmimenu
STR_nmimenu:	defb "Spectranet NMI menu",NEWLINE,NEWLINE,0
.globl STR_send
STR_send:	defb "Listening on ",0
.globl STR_port
STR_port:	defb " port 2000",NEWLINE,0
.globl STR_start
STR_start:	defb " Start: ",0
.globl STR_len
STR_len:	defb "Length: ",0
.globl STR_xtoexit
STR_xtoexit:	defb NEWLINE,"Press 'x' to exit.",NEWLINE,0
.globl STR_borked
STR_borked:	defb NEWLINE,"Operation failed with rc=",0
.globl STR_est
STR_est:	defb "Connection established",NEWLINE,0
.globl STR_ident
STR_ident:	defb "Spectranet utility ROM",0


