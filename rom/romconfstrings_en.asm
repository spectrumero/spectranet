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

STR_installed	defb "Current configuration\n=====================\n\n",0
STR_datarom	defb "-- data --\n",0

STR_menutitle	defb "\n\nROM configuration menu\n======================\n\n",0
STR_addmodule	defb "Add a new ROM module",0
STR_repmodule	defb "Replace an existing module",0
STR_remmodule	defb "Remove a ROM module",0
STR_exit	defb "Exit",0

STR_send	defb "Listening on ",0
STR_port	defb " port 2000\n",0
STR_xtoexit	defb "\nPress 'x' to exit.\n",0
STR_borked	defb "\nOperation failed with rc=",0
STR_est		defb "Connection established\n",0
STR_len		defb "Length: ",0
STR_noroom	defb "No space left in flash.\n",0
STR_writingmod	defb "\nWriting module to flash page ",0

STR_entermod	defb "Enter hex number of ROM to replace: ",0
STR_delrom	defb "Enter hex number of ROM to delete:",0
STR_notvalid	defb "\nNot a valid ROM number.\nPlese re-enter: ",0
STR_erasebork	defb "Erase failed\n",0
STR_writebork	defb "Write failed\n",0
STR_defragment	defb "Defragmenting...\n",0
STR_erasing	defb "\nErasing...\n",0
STR_eraseok	defb "Erase complete\n",0
	
