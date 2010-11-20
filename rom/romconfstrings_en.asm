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
; ROM configuration utility - strings
.include	"ctrlchars.inc"
.data
.globl STR_installed
.globl STR_datarom
STR_installed:	defb "Current configuration",NEWLINE,"=====================",NEWLINE,NEWLINE,0
STR_datarom:	defb "-- data --",NEWLINE,0

.globl STR_menutitle
.globl STR_addmodule
.globl STR_remmodule
.globl STR_repmodule
.globl STR_exit
STR_menutitle:	defb NEWLINE,NEWLINE,"ROM configuration menu",NEWLINE,"======================",NEWLINE,NEWLINE,0
STR_addmodule:	defb "Add a new ROM module",0
STR_repmodule:	defb "Replace an existing module",0
STR_remmodule:	defb "Remove a ROM module",0
STR_exit:	defb "Exit",0

.globl STR_send
.globl STR_port
.globl STR_xtoexit
.globl STR_borked
.globl STR_est
.globl STR_len
.globl STR_noroom
.globl STR_writingmod
STR_send:	defb "Listening on ",0
STR_port:	defb " port 2000",NEWLINE,0
STR_xtoexit:	defb NEWLINE,"Press 'x' to exit.",NEWLINE,0
STR_borked:	defb NEWLINE,"Operation failed with rc=",0
STR_est:		defb "Connection established",NEWLINE,0
STR_len:		defb "Length: ",0
STR_noroom:	defb "No space left in flash.",NEWLINE,0
STR_writingmod:	defb NEWLINE,"Writing module to flash page ",0

.globl STR_entermod
.globl STR_delrom
.globl STR_notvalid
.globl STR_erasebork
.globl STR_writebork
.globl STR_defragment
.globl STR_erasing
.globl STR_eraseok
STR_entermod:	defb "Enter hex number of ROM to replace: ",0
STR_delrom:	defb "Enter hex number of ROM to delete:",0
STR_notvalid:	defb NEWLINE,"Not a valid ROM number.",NEWLINE,"Plese re-enter: ",0
STR_erasebork:	defb "Erase failed",NEWLINE,0
STR_writebork:	defb "Write failed",NEWLINE,0
STR_defragment:	defb "Defragmenting...",NEWLINE,0
STR_erasing:	defb NEWLINE,"Erasing...",NEWLINE,0
STR_eraseok:	defb "Erase complete",NEWLINE,0
	
