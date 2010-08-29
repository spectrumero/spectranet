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

; Filesystem Configuration Utility module
	org 0x2000
	include "vectors.asm"			; Vector table
	include "init.asm"			; Initialization routines
	include "gen_copycfg.asm"		; Config copier
	include "fs_strings_en.asm"		; English strings
	include "fs_config_ui.asm"		; User interface
	include	"if_configmain.asm"		; Interface configuration
	include "if_config_ui.asm"		; Interface cf. UI
	include "if_strings_en.asm"		; English strings
	include "if_saveconfig.asm"
	include "../../rom/spectranet.asm"	; spectranet lib defs
	include "../../rom/sysvars.sym"		; system vars defs
	include "../../rom/flashconf.asm"	; flash config defs
	include "if_defs.asm"			; defines
	include "flashwrite.asm"		; must be the last included

