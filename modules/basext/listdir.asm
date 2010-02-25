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

; Routine that lists directories.
	include "../../rom/fs_statdefs.asm"
; Show the directory listing. HL = directory to open.
F_listdir
        call OPENDIR                    ; open the directory
        jp c, J_tbas_error
        ld (v_vfs_dirhandle), a         ; save the directory handle
        ld a, 2
        rst CALLBAS                     ; set channel to 2
        defw 0x1601
.catloop
        ld a, (v_vfs_dirhandle)         ; get the dir handle back
        ld de, INTERPWKSPC              ; location for result
        call READDIR                    ; read dir
        jr c, .readdone                 ; read is probably at EOF
	call F_statentry		; show some information about it
        ld hl, INTERPWKSPC
        call F_tbas_zxprint             ; print a C string to #2
        ld a, '\r'                      ; newline
        rst CALLBAS
        defw 0x10
        jr .catloop
.readdone
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
F_statentry
	ld hl, INTERPWKSPC
	ld de, INTERPWKSPC+256		; where to put the data
	call STAT
	jr c, .staterr
	ld ix, INTERPWKSPC+256
	ld a, (ix+(STAT_MODE+1))	; Check file mode MSB
	and S_IFDIR / 256		; check directory flag
	jr z, .isfile
	ld hl, STR_dir
	call F_tbas_zxprint
	jr .continue
.isfile
	call F_showsize
	ld a, ' '
	rst CALLBAS
	defw 0x0010
.continue
	ret

.staterr
	ld hl, STR_staterr
	jp F_tbas_zxprint		; print it and return.

STR_staterr	defb "  Err ",0
STR_dir		defb "  Dir ",0

;----------------------------------------------------------------------
; F_showsize
; Create a 4 digit decimal with the correct ending (b, k, M or G)
; TODO: This routine is particularly naive and hardly optimized 
; for space (or anything else). (Low priority TODO).
F_showsize
	ld a, (ix+(STAT_SIZE+3))	; MSB of size
	ld b, a
	and 0xC0			; >= 2^30
	jr nz, .gigs
	cpl				; check lower half 
	and b				; of 4th stat byte for megs
	jr nz, .megs
	ld a, (ix+(STAT_SIZE+2))
	ld b, a
	and 0xF0			; >= 2^20
	jr nz, .megs
	cpl				; check lower half of
	and b				; 3rd stat byte for kilos
	jr nz, .kilos
	ld a, (ix+(STAT_SIZE+1))
	and 0xFC			; >= 2^10
	jr nz, .kilos
	ld l, (ix+STAT_SIZE)		; less than 1K
	ld h, (ix+(STAT_SIZE+1))
	call F_decimal
	ld a, 'b'
	rst CALLBAS
	defw 0x0010
	ret
.kilos
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
.megs
	ld l, (ix+(STAT_SIZE+2))	; 1M to 1023M
	ld h, (ix+(STAT_SIZE+3))
	ld b, 4
.megloop
	srl h
	rr l
	djnz .megloop
	call F_decimal
	ld a, 'M'
	rst CALLBAS
	defw 0x0010
	ret
.gigs
	ld l, (ix+(STAT_SIZE+4))	; 1G to 4G
	ld h, 0
	ld b, 6
.gigloop
	srl l
	djnz .gigloop
	call F_decimal
	ld a, 'G'
	rst CALLBAS
	defw 0x0010
	ret

;----------------------------------------------------------------------
; F_decimal
; Modified version of http://baze.au.com/misc/z80bits.html#5.1
; by baze.
; HL = number to convert
F_decimal
	ld e, 0
	ld bc, -1000		; maximum value passed will be 9999
	call .num1
	ld bc, -100
	call .num1
	ld c, -10
	call .num1
	ld c, b
	ld e, 1			; print a zero if it's the last digit
.num1
	ld a, '0'-1
.num2
	inc a
	add hl, bc
	jr c, .num2
	sbc hl, bc

	bit 0, e
	jr nz, .zerocont
	cp '0'
	jr nz, .nonz
	ld a, ' '
	jr .zerocont
.nonz
	ld e, 1
.zerocont
	rst CALLBAS
	defw 0x0010
	ret
	
