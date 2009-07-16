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

;---------------------------------------------------------------------------
; F_showfileinfo
; Shows information on a file.
F_showfileinfo
	ld hl, INTERPWKSPC
	call F_basstrcpy	; prepare BASIC string for use
	
	ld hl, INTERPWKSPC
	ld de, INTERPWKSPC+256	; where to return the data
	call STAT	
	ret c			; return on error

	ld a, (INTERPWKSPC+256+1) ; get file type flags
	bit 7, a		; test for regular file
	jr nz, .rfinfo
	
	bit 6, a		; test for directory
	jp nz, .dirinfo

	ld a, 0x26		; Unknown file type - TODO - errno.asm
	scf
	ret

.rfinfo
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
	ld a, (v_vfs_curmount)
	ld hl, INTERPWKSPC	; filename
	ld d, 0x00		; flags
	ld e, O_RDONLY		; read only
	call OPEN
	ret c			; failed top open the file!
	ld (v_tnfs_curfd), a	; save the FD

.gethdrinfo
	ld de, INTERPWKSPC	; we no longer need the filename
	call F_tbas_getheader
	jr c, .nottap		; Not a TAP file (or an error)
	call .hdrinfo

	; At this point we list any remaining blocks, some of which may
	; lack normal headers, so we have to do it in a new block of code.
	; Seek forward past the data block and try to analyze the rest
	; of the TAP file.
.getblocks
	ld de, INTERPWKSPC
	ld bc, 2		; read the length value
	ld a, (v_tnfs_curfd)
	call READ
	jr c, .cleanuperr	; shouldn't die here.

	ld hl, (INTERPWKSPC)	; get the length of the block
.seeknextblock
	ld de, 0		; and make dehl = 32 bit version of it
	ld a, (v_tnfs_curfd)
	ld c, SEEK_CUR		; and seek forwards that many bytes
	call LSEEK
	jr c, .cleanuperr

	ld de, INTERPWKSPC	; see if we've got another header
	call F_tbas_getheader
	jr nc, .disphdr
	cp TBADLENGTH
	jr z, .dispnonhdr	; suspected headerless block
	cp TBADTYPE
	jr z, .dispnonhdr
	cp EOF			; reached end of file?
	jr z, .done
.disphdr
	call .hdrinfo		; show the header information
	jr .getblocks

.dispnonhdr
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
	jr .seeknextblock	; smaller than a standard header!

.done
	ld a, (v_tnfs_curfd)
	call CLOSE	
	ret
.nottap
	cp TBADLENGTH
	jr z, .data
	cp TBADTYPE
	jr z, .data
.cleanuperr
	push af			; store original error
	ld a, (v_tnfs_curfd)
	call CLOSE
	pop af
	ret
.data
	ld hl, STR_data
	call F_tbas_zxprint
	call F_lf
	jr .done

.dirinfo
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
.hdrinfo
	and a
	jr z, .program
	cp 1
	jr z, .numarray
	cp 2
	jr z, .strarray
	cp 3
	jr z, .code
	ld hl, STR_unknown
	call F_tbas_zxprint
.continue
	ld hl, INTERPWKSPC+4	; Filename in the TAP block
	ld b, 10
.fnloop				; Print the filename of this TAP block
	ld a, (hl)
	rst CALLBAS
	defw 16
	inc hl
	djnz .fnloop
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

.program
	ld hl, STR_basic
	jr .pr
.numarray
	ld hl, STR_numarray
	jr .pr
.strarray
	ld hl, STR_strarray
	jr .pr
.code
	ld hl, STR_code
.pr
	call F_tbas_zxprint
	jr .continue
	

; F_lf: Print an "enter"
F_lf
	ld a, 0x0d
	rst CALLBAS
	defw 16
	ret

;---------------------------------------------------------------------------
; F_print32
; Converts the 32 bit value in DEHL to ASCII and displays it on the
; current ZX channel.
F_print32
        ld ix, INTERPWKSPC+512
        ld (ix), 0
.divloop
        inc ix
        ld c, 10
        call F_div32
        add a, '0'              ; convert to ascii
        ld (ix), a              ; save it
        ld a, h
        or l                    ; has DEHL reached 0?
        or d
        or e
        jr nz, .divloop
.loop
        ld a, (ix)
        and a
        ret z
        rst CALLBAS
	defw 16
        dec ix
        jr .loop
        
; Modified version of baze's 32 bit divide routine
F_div32
        xor a
        ld b, 32
.loop
        add hl,hl           
        rl e              
        rl d             
        rla                  
        cp c           
        jr c,$+4      
        sub c         
        inc l        
        djnz .loop
        ret

