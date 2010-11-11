;The MIT License
;
;Copyright (c) 2008 Matt Westcott
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
; This file is a slightly modified version of the ZX key scanning routines
; from Matt Westcott's (gasman) Open ZX ROM.
.data
flags2:			equ 23658
key_table:
			; mapping from key codes (as returned in E by key_scan) to 'base characters'
			db "BHY65TGVNJU74RFC"
			db "MKI83EDX", 0x0e, "LO92WSZ"
			db " ", 0x0d, "P01QA"
			
;			block 0x8060-$,0
			; table of control codes produced by keys 0-9 in conjunction with caps shift
key_table_caps_digits:
			db 0x0c,0x07,0x06,0x04,0x05,0x08,0x0a,0x0b,0x09,0x0f
; 0x026a
			; table of symbols / tokens produced by keys A-Z in conjunction with symbol shift
key_table_sym_letters:
			db 0xe2, '*', '?', 0xcd, 0xc8, 0xcc, 0xcb, '^'
			db 0xac, '-', '+', '=', '.', ',', ';', '"'
			db 0xc7, '<', 0xc3, '>', 0xc5, '/', 0xc9, 0x60, 0xc6, ':'
.text
key_scan:
			; scan keyboard, returning key code(s) in DE.
			; Numbering rows B-Sp=0, H-En=1, Y-P=2, 6-0=3, 1-5=4, Q-T=5, A-G=6, Cs-V=7,
			; key code is rownum + ((5 - bit number) << 3).
			; The first key encountered, ordering by descending row and ascending bit
			; within row, is put in E. The second key is put in D.
			; If one of the keys is caps shift, this will be placed in D.
			; Otherwise, if one of the keys is symbol shift, this will be placed in D.
			; The zero flag is returned reset if >2 keys are pressed, or 2 keys are pressed
			; and neither is a shift.
			ld de,0xffff
			ld b,7							; scan each of 8 rows
			ld a,0xfe						; with each bit in turn held low
key_scan_row:
			push af
			in a,(0xfe)
			ld c,a							; pick apart result of IN in register C
			ld a,0x20						; count down bit number in A, premultiplied by 8
key_scan_bit:
			push af
			rr c
			jr c,key_scan_bit_done			; if bit is nonzero (-> carry set), key not pressed; move on
			add a,b							; assemble key code from bit number and row number
			inc e							; check if e register is vacant
			jr nz,key_scan_e_not_vacant
			ld e,a
			jr key_scan_bit_done
key_scan_e_not_vacant:
			dec e							; e is already occupied; restore value
			inc d							; check if d register is vacant
			jr z,key_scan_d_vacant
			pop hl							; if not, there are too many keys;
			pop hl							; restore stack and exit with Z reset
			ret
key_scan_d_vacant:
			ld d,a
key_scan_bit_done:
			pop af
			sub 8							; if counter in A does not roll over,
			jr nc,key_scan_bit				; there are bits remaining to check
			pop af							; go to next row once we've checked 5 bits
			dec b
			rlca							; keep scanning rows for as long as the zero bit
			jr c,key_scan_row				; doesn't fall off the end of A
			; keys collected; now handle shifts
			ld a,d
			inc a							; see if d is still 0xff (i.e0. only one key)
			ret z							; if so, exit with Z set
			ld a,e
			cp 0x27							; check E for caps shift
											; (it's the first key we check, so it'll always
											; be in E if at all)
			jr nz,key_scan_no_cs
			ld e,d							; if E is caps shift, switch D and E
			ld d,a							; and exit with Z set
			ret
key_scan_no_cs:
			cp 0x18							; check E for symbol shift
			jr nz,key_scan_no_ss
			ld e,d							; if E is sym shift, switch D and E
			ld d,a							; and exit with Z set
			ret
key_scan_no_ss:
			ld a,d							; only remaining valid condition is if D is
			cp 0x18							; symbol shift; check for this condition and
			ret								; return with Z flag indicating the result

key_test:
			; Test that a successful (zero flag set) response from key_scan is indeed
			; a real key (i.e0. not just a shift key on its own). As described by Toni Baker
			; (Mastering Machine Code on your ZX Spectrum, ch11):
			;   i) B will be made to contain the value formerly held by D
			;  ii) D will be made to contain zero
			; iii) if DE started off as FFFF, FF27 or FF18, return with low byte in A and carry reset
			;  iv) otherwise, translate the key code into its base character (capitalised ASCII code)
			;      and return that in A, with carry set
			ld b,d
			ld d,0
			ld a,b				; is high byte 0xff?
			inc a
			ld a,e				; load A with low byte either way
			jr nz,key_test_not_ff	; if not, key scan result is ok
			cp 0x27				; is low byte >= 0x27 (which can only be 0x27 or 0xff)?
			ret nc				; return with carry reset if so
			cp 0x18				; is low byte 0x18?
			ret z					; return with carry reset if so
key_test_not_ff:
			ld hl,key_table
			add hl,de
			ld a,(hl)
			scf
			ret
; 0x0333
key_code:
			; Convert base character to ASCII code, respecting shifts and current key mode.
			; entry: E = base character
			; B = shift code (FF, 27 or 18)
			; C = editor mode (0 = K/L/C, 1 = E, 2 = G)
			; bit 3 of D = 0 for K mode, 1 for L/C mode
			; bit 3 of FLAGS2 = 0 for L mode, 1 for C mode
			; return: A = ASCII code
			; NB: for now, we'll only consider C and L modes because the others aren't much use
			; until we have a Basic editor.
			ld a,b
			cp 0x18				; test shift code for symbol shift
			jr z,key_code_sshift	; jump ahead if symbol shift active
			cp 0x27				; test shift code for caps shift
			jr z,key_code_cshift	; jump ahead if caps shift active
			ld a,(flags2)	; get caps lock state from flags2 system variable
			and 0x08			; - test bit 3
			ld a,e				; pick up base character code
			ret nz				; return it unchanged if caps lock is set
			cp 'A'				; also return character code unchanged if caps lock is off
			ret c					; but character is not a letter (= code < 'A')
			add a,0x20		; otherwise, translate to lower case by adding 0x20
			ret
			
key_code_sshift:
			ld a,e
			cp '0'
			ret c					; return keycode unchanged if <'0' (= space or enter)
			cp 'A'				; if it's a letter (code >= 'A'), jump ahead and look up in table
			jr nc,key_code_sshift_letter
			; otherwise, deal with numbers
			cp '0'				; 0 and 2 are special cases.
			jr z,key_code_underline	; These take so many bytes to handle that we would have been
			cp '2'				; far better off with a 10-byte lookup table. But no, we had
			jr z,key_code_at				; to make it overly complicated...
			sub 0x10			; for all others, just subtract 0x10 to get the resulting ASCII symbol
			ret
key_code_underline:
			ld a,'_'
			ret
key_code_at:
			ld a,'@'
			ret
			
key_code_sshift_letter:
			ld d,0				; look up letter in the table key_table_sym_letters
			ld hl,key_table_sym_letters - 'A' ; fiddle base address of table to count from ASCII 'A'
			add hl,de
			ld a,(hl)
			ret
			
key_code_cshift:
			ld a,e
			cp '0'				; return keycode unchanged if <'0' (space, enter or symbol shift);
			ret c				; NB key code for symbol shift is 0x0E = extend mode, which is correct here
			cp 'A'				; also return keycode unchanged if it's a letter (code >= 'A')
			ret nc
			ld d,0				; otherwise, look it up in the table key_table_caps_digits
			ld hl,key_table_caps_digits - '0'	; fiddle base address of table to start counting from ASCII '0'
			add hl,de
			ld a,(hl)
			ret
			
