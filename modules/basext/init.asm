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

;------------------------------------------------------------------------
; F_init: Initializes the interpreter
F_init
        ld hl, PARSETABLE
        ld b, NUMCMDS
.loop
        push bc
        call ADDBASICEXT
        pop bc
        jr c, .installerror
        djnz .loop
        ld hl, STR_basicinit
        call PRINT42
        ret
.installerror
        ld hl, STR_basinsterr
        call PRINT42
        ret
STR_basicinit   defb    "BASIC extensions installed\n",0
STR_basinsterr  defb    "Failed to install BASIC extensions\n",0

NUMCMDS         equ     10
PARSETABLE      
P_mount         defb    0x0b
                defw    CMD_MOUNT
                defb    TNFS_PAGE
                defw    F_tbas_mount    ; Mount routine
P_umount        defb    0x0b
                defw    CMD_UMOUNT
                defb    TNFS_PAGE
                defw    F_tbas_umount   ; Umount routine
P_chdir         defb    0x0b
                defw    CMD_CHDIR
                defb    TNFS_PAGE
                defw    F_tbas_chdir    ; Chdir routine
P_cat           defb    0x0b
                defw    CMD_LS		; Display a directory
                defb    TNFS_PAGE
                defw    F_tbas_ls
P_aload         defb    0x0b
                defw    CMD_ALOAD       ; Arbitrary load
                defb    TNFS_PAGE
                defw    F_tbas_aload
P_load          defb    0x0b
                defw    CMD_LOAD        ; Standard LOAD command
                defb    TNFS_PAGE
                defw    F_tbas_load
P_save          defb    0x0b
                defw    CMD_SAVE	; Standard SAVE command
                defb    TNFS_PAGE
                defw    F_tbas_save
P_tapein	defb	0x0b
		defw	CMD_TAPEIN	; Set up a tape trap for a TAP file
		defb	TNFS_PAGE
		defw	F_tbas_tapein
F_info		defb	0x0b
		defw	CMD_INFO	; Give information on a file
		defb	TNFS_PAGE
		defw	F_tbas_info
F_fs		defb	0x0b
		defw	CMD_FS
		defb	TNFS_PAGE
		defw	F_tbas_fs

CMD_MOUNT       defb    "%mount",0
CMD_UMOUNT      defb    "%umount",0
CMD_CHDIR       defb    "%cd",0
CMD_LS          defb    "%cat",0
CMD_ALOAD       defb    "%aload",0
CMD_LOAD        defb    "%load",0
CMD_SAVE        defb    "%save",0
CMD_TAPEIN	defb	"%tapein",0
CMD_INFO	defb	"%info",0
CMD_FS		defb	"%fs",0

