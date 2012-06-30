// The MIT License
// 
// Copyright (c) 2011 Dylan Smith
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// Print things using the Spectranet 42 col routine. The routine is used
// so as to not include the z88dk print routines which take quite a bit of
// memory

/*#include <spectrum.h>
#include <string.h>

#include "ctf.h"*/

#define PUTCHAR42 0x3e2a
#define PRINT42 0x3e2d
#define PRCOL 0x3F00
#define PRROW 0x3F01

#define GOWIN	0x4800
#define OFFSET	8
#define	LEN		14
#define LINES	6
#define ATTRS 0x5900
#define ATTRVAL 0x29

#define PAGEIN 0x3FF9
#define PAGEOUT 0x007C

void main();
void setupGameOver();
void __FASTCALL__ setBlueScore();
void __FASTCALL__ setRedScore();
void victory();
void defeat();

void main() {
#asm
	call PAGEIN
#endasm
	setupGameOver();
	setBlueScore("5");
	setRedScore("4");
	defeat();
#asm
	call PAGEOUT
#endasm
}

void setupGameOver() {
#asm
	xor a
	ld b, LINES
	ld hl, GOWIN+OFFSET
.clr_loop
	push bc
	call clear_line
	ld bc, 32
	add hl, bc
	pop bc
	djnz clr_loop

.set_attr
	ld hl, ATTRS+OFFSET
	ld a, ATTRVAL
	ld b, LINES
.set_attr_loop
	push bc
	push hl
	call set_line
	pop hl
	ld bc, 32
	add hl, bc
	pop bc
	djnz set_attr_loop
	ld a, 1
	out (254), a

.put_text
	ld hl, GOWIN
	ld (PRROW), hl
	ld a, 11
	ld (PRCOL), a
	ld hl, _gostring
	call PRINT42

	ld hl, GOWIN+128
	ld (PRROW), hl
	ld a, 11
	ld (PRCOL), a
	ld hl, _score
	call PRINT42

	ld hl, GOWIN+160
	ld (PRROW), hl
	ld a, 11
	ld (PRCOL), a
	ld hl, _blue
	call PRINT42

	ld a, 20
	ld (PRCOL), a
	ld hl, _red
	call PRINT42

	jp end

.clear_line
	ld b, 8
	push hl
.clear_line_loop
	push hl
	push bc
	call set_line
	pop bc
	pop hl
	inc h
	djnz clear_line_loop
	pop hl
	ret

.set_line
	ld d, h
	ld e, l
	inc e
	ld bc, LEN
	ld (hl), a
	ldir
	ret
.end
#endasm
}

void __FASTCALL__ setBlueScore(char *score) {
#asm
	ld de, GOWIN+160
	ld (PRROW), de
	ld a, 17
	ld (PRCOL), a
	call PRINT42
#endasm
}

void __FASTCALL__ setRedScore(char *score) {
#asm
	ld de, GOWIN+160
	ld (PRROW), de
	ld a, 26
	ld (PRCOL), a
	call PRINT42
#endasm
}

void setoutcomepos() {
#asm
	ld hl, GOWIN+64
  ld (PRROW), hl
	ld a, 17
	ld (PRCOL), a
#endasm
}

void victory() {
	setoutcomepos();
#asm
	ld hl, _victorystr
	call PRINT42
#endasm
}

void defeat() {
	setoutcomepos();
#asm
	ld hl, _defeatstr
	call PRINT42
#endasm
}

#asm
._gostring
	defb	'*','*','*','*',' ','G','A','M','E',' ','O','V','E','R',' ','*','*','*','*',0
._score
	defb '-','-','-','-','-','-',' ','S','C','O','R','E',' ','-','-','-','-','-','-',0
._blue
	defb 'B','L','U','E',':',' ',0
._red
	defb 'R','E','D',' ',':',' ',0
._defeatstr
	defb 'D','e','f','e','a','t','!',0
._victorystr
	defb 'V','i','c','t','o','r','y','!',0
#endasm

