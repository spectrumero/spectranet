;The MIT License
;
;Copyright (c) 2009 Dylan Smith, except 32 bit divide routine by Baze
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

; Routines for the %info command.
.include	"defs.inc"
.include	"zxrom.inc"
.include	"spectranet.inc"
.include	"fcntl.inc"
.include	"sysvars.inc"
.text
;---------------------------------------------------------------------------
; F_showfileinfo
; Shows information on a file.
.globl F_showfileinfo
F_showfileinfo:
	ld hl, INTERPWKSPC
	call F_basstrcpy	; prepare BASIC string for use
	
	ld hl, INTERPWKSPC
	ld de, INTERPWKSPC+256	; where to return the data
	call STAT	
	ret c			; return on error

	ld a, (INTERPWKSPC+256+1) ; get file type flags
	bit 7, a		; test for regular file
	jr nz, .rfinfo1
	
	bit 6, a		; test for directory
	jp nz, .dirinfo1

	ld a, 0x26		; Unknown file type - TODO - errno.asm1
	scf
	ret

.rfinfo1:
	ld a, 2
	rst CALLBAS
	defw 0x1601		; set channel

	ld hl, STR_size
	call F_tbas_zxprint	; print the file size
	
	ld de, (INTERPWKSPC+256+8)	; MSW of file size
	ld hl, (INTERPWKSPC+256+6)	; LSW of file size
	call F_print32

	ld hl, STR_bytes
	call F_tbas_zxprint

	call F_lf

	; Now see if it's a TAP file, in which case more information
	; can be given. This means opening and reading the file.
	ld hl, INTERPWKSPC	; filename
	ld d, 0x00		; flags
	ld e, O_RDONLY		; read only
	call OPEN
	ret c			; failed top open the file!
	ld (v_vfs_curfd), a	; save the FD

.gethdrinfo1:
	ld de, INTERPWKSPC	; we no longer need the filename
	call F_tbas_getheader
	jr c, .nottap1		; Not a TAP file (or an error)
	call .hdrinfo1

	; At this point we list any remaining blocks, some of which may
	; lack normal headers, so we have to do it in a new block of code.
	; Seek forward past the data block and try to analyze the rest
	; of the TAP file.
.getblocks1:
	ld de, INTERPWKSPC
	ld bc, 2		; read the length value
	ld a, (v_vfs_curfd)
	call READ
	jr c, .cleanuperr1	; shouldn't die here.

	ld hl, (INTERPWKSPC)	; get the length of the block
.seeknextblock1:
	ld de, 0		; and make dehl = 32 bit version of it
	ld a, (v_vfs_curfd)
	ld c, SEEK_CUR		; and seek forwards that many bytes
	call LSEEK
	jr c, .cleanuperr1

	ld de, INTERPWKSPC	; see if we've got another header
	call F_tbas_getheader
	jr nc, .disphdr1
	cp TBADLENGTH
	jr z, .dispnonhdr1	; suspected headerless block
	cp TBADTYPE
	jr z, .dispnonhdr1
	cp EOF			; reached end of file?
	jr z, .done1
.disphdr1:
	call .hdrinfo1		; show the header information
	jr .getblocks1

.dispnonhdr1:
	ld hl, STR_headerless	; print "Headerless block"
	call F_tbas_zxprint
	ld de, 0		; most significant word is always 0
	ld hl, (INTERPWKSPC)
	dec hl			; Remove the 2 byte block type and check
	dec hl			; byte from the length to display
	call F_print32
	ld hl, STR_bytes
	call F_tbas_zxprint
	call F_lf
	ld hl, (INTERPWKSPC)
	ld de, TNFS_HDR_LEN-2	; already read this much, subtract from
	sbc hl, de		; the block size. TODO: block sizes
	jr .seeknextblock1	; smaller than a standard header!

.done1:
	ld a, (v_vfs_curfd)
	call VCLOSE	
	ret
.nottap1:
	cp TBADLENGTH
	jr z, .data1
	cp TBADTYPE
	jr z, .data1
.cleanuperr1:
	push af			; store original error
	ld a, (v_vfs_curfd)
	call CLOSE
	pop af
	ret
.data1:
	ld hl, STR_data
	call F_tbas_zxprint
	call F_lf
	jr .done1

.dirinfo1:
	ld a, 2
	rst CALLBAS
	defw 0x1601		; set channel

	ld hl, STR_directory
	call F_tbas_zxprint	; print the word "Directory"
	
	ld de, (INTERPWKSPC+256+8)	; MSW of file size
	ld hl, (INTERPWKSPC+256+6)	; LSW of file size
	call F_print32

	ld hl, STR_bytes
	call F_tbas_zxprint

	call F_lf
	ret

	; A should be the block type as returned by getheader
.hdrinfo1:
	and a
	jr z, .program1
	cp 1
	jr z, .numarray1
	cp 2
	jr z, .strarray1
	cp 3
	jr z, .code1
	ld hl, STR_unknown
	call F_tbas_zxprint
.continue1:
	ld hl, INTERPWKSPC+4	; Filename in the TAP block
	ld b, 10
.fnloop1:				; Print the filename of this TAP block
	ld a, (hl)
	rst CALLBAS
	defw 16
	inc hl
	djnz .fnloop1
	call F_lf

	ld hl, STR_blksize
	call F_tbas_zxprint
	ld de, 0
	ld hl, (INTERPWKSPC+14)
	call F_print32		; Display the size
	call F_lf

	ld hl, STR_param1
	call F_tbas_zxprint
	ld de, 0
	ld hl, (INTERPWKSPC+16)
	call F_print32		; Display parameter 1 value
	call F_lf

	ld hl, STR_param2
	call F_tbas_zxprint
	ld de, 0
	ld hl, (INTERPWKSPC+18)
	call F_print32		; Display parameter 2 value
	call F_lf
	ret	

.program1:
	ld hl, STR_basic
	jr .pr1
.numarray1:
	ld hl, STR_numarray
	jr .pr1
.strarray1:
	ld hl, STR_strarray
	jr .pr1
.code1:
	ld hl, STR_code
.pr1:
	call F_tbas_zxprint
	jr .continue1
	

; F_lf: Print an "enter"
.globl F_lf
F_lf:
	ld a, 0x0d
	rst CALLBAS
	defw 16
	ret

;---------------------------------------------------------------------------
; F_print32
; Converts the 32 bit value in DEHL to ASCII and displays it on the
; current ZX channel.
.globl F_print32
F_print32:
        ld ix, INTERPWKSPC+512
        ld (ix), 0
.divloop3:
        inc ix
        ld c, 10
        call F_div32
        add a, '0'              ; convert to ascii
        ld (ix), a              ; save it
        ld a, h
        or l                    ; has DEHL reached 0?
        or d
        or e
        jr nz, .divloop3
.loop3:
        ld a, (ix)
        and a
        ret z
        rst CALLBAS
	defw 16
        dec ix
        jr .loop3
        
; Modified version of baze's 32 bit divide routine
.globl F_div32
F_div32:
        xor a
        ld b, 32
.loop4:
        add hl,hl           
        rl e              
        rl d             
        rla                  
        cp c           
        jr c,$+4      
        sub c         
        inc l        
        djnz .loop4
        ret

