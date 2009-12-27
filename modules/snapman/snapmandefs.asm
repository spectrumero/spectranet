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

; Definitions.
MAXDIRSTR		equ	22	; Width of max. displayable dir
BOXSTARTADDR		equ	0x4060	; start address of sel box
BOXDIMENSIONS		equ	0x1014	; Height and end column
FNAMESZ			equ	16	; Max filename size
NORMAL_ATTR		equ	0x04	; Background attr
SELECTED_ATTR		equ	0x32	; Selected item attr
ATTR_BASE		equ	22528	; Where the attrs start
STACK_AFALT             equ 	NMISTACK-14
STACK_AF                equ 	NMISTACK-12
STACK_BC                equ 	NMISTACK-10
STACK_DE                equ 	NMISTACK-8
STACK_HL                equ 	NMISTACK-6


v_strbuf		equ	0x1000	; Address of string buffer
v_curfilename		equ	0x1010	; Current file name

v_movebytes		equ	0x1030	; Bytes to move per line
v_clearbytes		equ	0x1032	; Bytes to clear per line
v_barstart		equ	0x1033	; Bar start addr
v_baraddr		equ	0x1036
v_barlen		equ	0x1038	; Bar length
v_barpos		equ	0x1039	; Position within box
v_selstart		equ	0x103A	; Selection start address
v_selend		equ	0x103C	; Selection end
v_maxcolumn		equ	0x103E	; Max column of bar
v_sellines		equ	0x103F	; Selection lines
v_startcolumn		equ	0x1040	; Start column of box
v_42colsperln		equ	0x1041	; Number of columns per line
v_selrow		equ	0x1042	; Selection row
v_curtopstring		equ	0x1043	; Current top string ptr
v_curbotstring		equ	0x1045	; Current bottom string ptr
v_selecteditem		equ	0x1047	; Selected item
v_lastitemidx		equ	0x1048	; Last item's index
v_stringtable		equ	0x1049	; Pointer to the string table
v_viewflags		equ 	0x104B	; Current box view flags
v_inputflags		equ	0x104C	; Input routine flags

v_dhnd			equ	0x104D	; Current directory handle
v_dirnextentry		equ	0x104E	; Next dir entry
v_snanextentry		equ	0x1050	; Next sna file entry
v_numdirs		equ	0x1052	; Number of directories
v_numsnas		equ	0x1053	; Number of snapshots
v_dirptr		equ	0x1054	; Directory pointer
v_snaptr		equ	0x1056	; Snapshot pointer

v_dirwkspc		equ	0x3000	; Directory entry buffer
v_statinfo		equ	0x3080	; Information returned by STAT
WORKSPACE		equ	0x3000	; Scratchpad

v_dirtable		equ	0x1100
v_snatable		equ	0x1200
v_dirstrings		equ	0x1300
v_snastrings		equ	0x1900

; Temporary storage
v_snapfd                equ 0x32FF      ; Snapshot FD
v_stacksave             equ 0x32FD      ; Save the stack pointer
v_snapstack             equ 0x32FB      ; Start of snapshot stack

