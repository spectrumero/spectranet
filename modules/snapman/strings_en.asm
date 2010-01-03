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

UI_STRINGS      defb    0,5,"- SPECTRANET SNAPSHOT MANAGER -",0
                defb    1,0,"Use arrow keys to move, Enter to select",0
                defb    3,28,"[D] Directory/",0
                defb    4,32,"file view",0
                defb    6,28,"[C] Save as...",0
                defb    8,28,"[S] Save",0
                defb    10,28,"[R] Rename",0
                defb    12,28,"[E] Erase",0
                defb    18,28,"[Q] Quit",0
                defb    20,0,"Dir: ",0
                defb    0xFF,0xFF
INPUTTABLE      defb    "qd",0x0d,"csre",0
INPUTADDRS      defw    F_exit
                defw    F_switchdirview
                defw    F_enterpressed
                defw    F_saveas
                defw    F_save
		defw	F_rename
		defw	F_erase

CHAR_YES        equ     'y'
STR_filename    defb    "Filename: ",0
STR_cfoverwrite defb    "Overwrite selected file? (y/n): ",0
STR_loading	defb	"Loading...",0
STR_saving	defb	"Saving...",0
STR_cwd		defb	".",0
STR_ident	defb	"Snapshot manager 1.0",0
STR_initialized	defb	"Snapshot manager initialized\n",0
STR_failed	defb	"Snapmgr. failed to alloc memory\n",0
STR_nomempage	defb	"No page was allocated!\n",0
STR_curfile	defb	"Current: ",0
STR_nofile	defb	"(none)",0
STR_newname	defb	"New name> ",0
STR_cferase	defb	"Erase the selected file? (y/n): ",0
