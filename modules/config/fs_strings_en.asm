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

; English strings for the configuration utility.
.include	"ctrlchars.inc"
.data
.globl STR_fsnum
STR_fsnum:	defb	"Filesystem: ",0
.globl STR_unset
STR_unset:	defb	"<unset>",NEWLINE,0
.globl STR_geturl
STR_geturl:	defb	NEWLINE,"Enter filesystem URL:",NEWLINE,"> ",0
.globl STR_invalidurl
STR_invalidurl:	defb	"Not a valid URL",NEWLINE,0
.globl STR_committed
STR_committed:	defb	"Committed OK.",NEWLINE,0
.globl STR_committing
STR_committing:	defb	"Writing...",NEWLINE,0
.globl STR_commitfail
STR_commitfail:	defb	"Commit failed.",NEWLINE,0
.globl STR_abandoned
STR_abandoned:	defb	"Changes abandoned.",NEWLINE,0
.globl STR_invalidfs
STR_invalidfs:	defb	"Not a valid URL",NEWLINE,0
.globl STR_unable
STR_unable:	defb	"Unable to set config item",NEWLINE,0
.globl STR_createfail
STR_createfail:	defb	"Unable to create section",NEWLINE,0
.globl STR_bootflag
STR_bootflag:	defb	NEWLINE,"Autoboot: ",0

; Menu items.
.globl STR_seturl
STR_seturl:	defb	"Set a filesystem",0
.globl STR_setboot
STR_setboot:	defb	"Set or unset autoboot",0
.globl STR_saveexit
STR_saveexit:	defb	"Save and exit",0
.globl STR_abandon
STR_abandon:	defb	"Abandon changes and exit",0
.globl STR_separator
STR_separator:	defb	NEWLINE,"========================================",NEWLINE,NEWLINE,0

; Others.
.globl STR_basicinit
STR_basicinit:	defb	"Config extensions OK",NEWLINE,0
.globl STR_basinsterr
STR_basinsterr:	defb	"Unable to initialize config extensions",NEWLINE,0
.globl STR_ident
STR_ident:	defb	"Configuration 1.0",0

