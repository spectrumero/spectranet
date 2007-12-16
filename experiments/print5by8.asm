; print 5x8 font on the Spectrum, because I so liked the VTX5000 teletext
; font :-) There is probably room for improvement in this routine.
; The character cells are actually 6x8 (5 pixels wide, plus a column of
; blank pixels)

putc_5by8
      push hl
      push bc
      push de
      cp '\n'     ; carriage return?
      jr z, .nextrow

      ; find the address of the character in the bitmap table
      sub 32      ; space = offset 0
      ld hl, 0
      ld l, a

      ; multiply by 8 to get the byte offset
      add hl, hl
      add hl, hl
      add hl, hl

      ; add the offset
      ld bc, char_space
      add hl, bc

      ; Now find the address in the frame buffer to be written.
      ex de, hl
      ld hl, col_lookup
      ld a, (v_column)
      ld b, a
      add a, l
      ld l, a        ; hl = pointer to byte in lookup table
      ld a, (hl)     ; a = lookup table value
      ld hl, (v_row) ; hl = framebuffer pointer for start of row
      add l
      ld l, a        ; hl = frame buffer address
      
; de contains the address of the char bitmap
; hl contains address in the frame buffer
.paintchar
      ld a, b           ; retrieve column
      and 3             ; find out how much we need to rotate
      jr z, .norotate   ; no need to rotate, character starts at MSB
      rla               ; multipy by 2
      ex af, af'        ; save A in shadow register 
      ld b, 8           ; byte copy count for outer loop
.fbwriterotated
      push bc           ; save outer loop count
      ex af, af'
      ld b, a           ; set up rotate loop count
      ex af, af'
      ld a, (de)        ; get character bitmap
      ld c, a           ; C contains rightmost fragment of bitmap
      xor a             ; set a=0 to accept lefmost fragment of bitmap
.rotloop
      rl c             
      rla               ; suck out leftmost bit from the carry flag 
      djnz .rotloop
.writerotated
      or (hl)           ; merge with existing character
      ld (hl), a
      ld a, c
      cp 0
      jr z, .writerotated.skip   ; nothing to do
      inc l             ; next char cell
      or (hl)
      ld (hl), a
      dec l             ; restore l
.writerotated.skip      
      inc h             ; next line
      inc de            ; next line of character bitmap
      pop bc            ; retrieve outer loop count
      djnz .fbwriterotated
.nextchar
      ld a, (v_column)
      inc a
      cp 42
      jr nz, .nextchar.done
.nextrow      
      ld a, (v_rowcount) ; check the row counter
      cp 23		; 24th line?
      jr nz, .noscroll
      call F_jumpscroll
      ld a, 16
      ld (v_rowcount), a
      ld hl, 0x5000     ; address of first row of bottom 1/3rd
      jr .nextchar.saverow ; save row addr and complete
.noscroll
      inc a
      ld (v_rowcount), a
      ld hl, (v_row)    ; advance framebuffer pointer to next character row
      ld a, l
      add 32
      jr c, .nextthird
      ld l, a
      jr .nextchar.saverow
.nextthird
      ld l, 0
      ld a, h
      add 8
      ld h, a
.nextchar.saverow
      ld (v_row), hl
      xor a             ; a = 0
.nextchar.done
      ld (v_column), a

      pop de
      pop bc
      pop hl
      ret

.norotate
      ld b, 8
.norotate.loop
      ld a, (de)        ; move bitmap into the frame buffer
      ld (hl), a
      inc de            ; next line of bitmap
      inc h             ; next line of frame buffer
      djnz .norotate.loop
      jr .nextchar

; a simple 'jump scroll' which scrolls the screen by 1/3rd. Simpler
; than scrolling one line.
F_jumpscroll
	push hl
	push de
	push bc
	ld hl, 0x4800	; start of 2nd 1/3rd of screen
	ld de, 0x4000	; first third
	ld bc, 0x1000	; copy 2/3rds of the screen up by 1/3rd
	ldir
	ld hl, 0x5000	; clear out last 2k
	ld de, 0x5001
	ld bc, 0x07FF
	ld (hl), 0
	ldir
	pop bc
	pop de
	pop hl	
	ret

