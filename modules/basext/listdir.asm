;The MIT License
;
;Copyright (c) 2010 Dylan Smith
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
.include	"stat.inc"
.include	"fcntl.inc"
.include	"spectranet.inc"
.include	"defs.inc"
.include	"zxrom.inc"
.include	"ctrlchars.inc"
.include	"sysvars.inc"
.text

; Show the directory listing. HL = directory to open.
.globl F_listdir
F_listdir:
        call OPENDIR                    ; open the directory
        jp c, J_tbas_error
        ld (v_vfs_dirhandle), a         ; save the directory handle
        ld a, 2
        rst CALLBAS                     ; set channel to 2
        defw 0x1601
.catloop1:
        ld a, (v_vfs_dirhandle)         ; get the dir handle back
        ld de, INTERPWKSPC              ; location for result
        call READDIR                    ; read dir
        jr c, .readdone1                 ; read is probably at EOF
	call F_statentry		; show some information about it
        ld hl, INTERPWKSPC
        call F_tbas_zxprint             ; print a C string to #2
        ld a, ZXNEWLINE                 ; newline
        rst CALLBAS
        defw 0x10
        jr .catloop1
.readdone1:
        push af                         ; save error code while
        ld a, (v_vfs_dirhandle)         ; we close the dir handle
        call CLOSEDIR
        pop hl                          ; pop into hl to not disturb flags
        jp c, J_tbas_error              ; report any error
        ld a, h                         ; get original error code
        cp EOF                          ; EOF is good
        jp nz, J_tbas_error             ; everything else is bad, report it
        jp EXIT_SUCCESS

; Expects the filename to be in INTERPWKSPC
.globl F_statentry
F_statentry:
	ld hl, INTERPWKSPC
	ld de, INTERPWKSPC+256		; where to put the data
	call STAT
	jr c, .staterr2
	ld ix, INTERPWKSPC+256
	ld a, (ix+(STAT_MODE+1))	; Check file mode MSB
	and S_IFDIR / 256		; check directory flag
	jr z, .isfile2
	ld hl, STR_dir
	call F_tbas_zxprint
	jr .continue2
.isfile2:
	call F_showsize
	ld a, ' '
	rst CALLBAS
	defw 0x0010
.continue2:
	ret

.staterr2:
	ld hl, STR_staterr
	jp F_tbas_zxprint		; print it and return.

STR_staterr:	defb "  Err ",0
STR_dir:		defb "  Dir ",0

;----------------------------------------------------------------------
; F_showsize
; Create a 4 digit decimal with the correct ending (b, k, M or G)
; TODO: This routine is particularly naive and hardly optimized 
; for space (or anything else). (Low priority TODO).
.globl F_showsize
F_showsize:
	ld a, (ix+(STAT_SIZE+3))	; MSB of size
	ld b, a
	and 0xC0			; >= 2^30
	jr nz, .gigs3
	cpl				; check lower half 
	and b				; of 4th stat byte for megs
	jr nz, .megs3
	ld a, (ix+(STAT_SIZE+2))
	ld b, a
	and 0xF0			; >= 2^20
	jr nz, .megs3
	cpl				; check lower half of
	and b				; 3rd stat byte for kilos
	jr nz, .kilos3
	ld a, (ix+(STAT_SIZE+1))
	and 0xFC			; >= 2^10
	jr nz, .kilos3
	ld l, (ix+STAT_SIZE)		; less than 1K
	ld h, (ix+(STAT_SIZE+1))
	call F_decimal
	ld a, 'b'
	rst CALLBAS
	defw 0x0010
	ret
.kilos3:
	ld l, (ix+(STAT_SIZE+1))	; 1K to 1023K
	ld h, (ix+(STAT_SIZE+2))
	srl h
	rr l
	srl h
	rr l
	call F_decimal
	ld a, 'k'
	rst CALLBAS
	defw 0x0010
	ret
.megs3:
	ld l, (ix+(STAT_SIZE+2))	; 1M to 1023M
	ld h, (ix+(STAT_SIZE+3))
	ld b, 4
.megloop3:
	srl h
	rr l
	djnz .megloop3
	call F_decimal
	ld a, 'M'
	rst CALLBAS
	defw 0x0010
	ret
.gigs3:
	ld l, (ix+(STAT_SIZE+4))	; 1G to 4G
	ld h, 0
	ld b, 6
.gigloop3:
	srl l
	djnz .gigloop3
	call F_decimal
	ld a, 'G'
	rst CALLBAS
	defw 0x0010
	ret

;----------------------------------------------------------------------
; F_decimal
; Modified version of http://baze.au3.com3/misc/z80bits.html3#5.13
; by baze.
; HL = number to convert
.globl F_decimal
F_decimal:
	ld e, 0
	ld bc, -1000		; maximum value passed will be 9999
	call .num14
	ld bc, -100
	call .num14
	ld c, -10
	call .num14
	ld c, b
	ld e, 1			; print a zero if it's the last digit
.num14:
	ld a, '0'-1
.num24:
	inc a
	add hl, bc
	jr c, .num24
	sbc hl, bc

	bit 0, e
	jr nz, .zerocont4
	cp '0'
	jr nz, .nonz4
	ld a, ' '
	jr .zerocont4
.nonz4:
	ld e, 1
.zerocont4:
	rst CALLBAS
	defw 0x0010
	ret
	
