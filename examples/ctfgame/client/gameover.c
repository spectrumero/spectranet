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

#include <spectrum.h>
#include <string.h>
#include <input.h>

#include "ctf.h"
#include "ctfmessage.h"

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

void __FASTCALL__ gameOver(GameEnd *msg) {
	char buf[4];
	uchar key;
	setupGameOver();

  switch(msg->reason) {
    case TEAMWON:
      showResultPanel(msg->winner);
      break;

		case OUTOFLIVES:
			outOfLives();
			break;
	}

	setBlueScore(msg->bluecapture);
	setRedScore(msg->redcapture);	

	/* we are no longer in the game loop, so dump the entire message
	 * out at once */
#ifdef LANG_ES
	putEntireMessage("Pulsa ENTER para salir");
#else
	putEntireMessage("Press ENTER to finish");
#endif

	// wait for ENTER
	while(in_Inkey() != 13);

	fadeOut();
}

void __FASTCALL__ showResultPanel(uchar winner) {
  switch(winner) {
    case 0:
      defeat();
      break;
    case 1:
      victory();
      break;
    default:
      scoredraw();
  }
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
#ifdef LANG_ES
	ld a, 15
#else
	ld a, 17
#endif
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

void scoredraw() {
  setoutcomepos();
#asm
  ld hl, _drawstr
  call PRINT42
#endasm
}

void outOfLives() {
	setoutcomepos();
#asm
	ld hl, _outoflivesstr
	call PRINT42
#endasm
}

#ifdef LANG_ES
#asm
._gostring
	defb	'P','A','R','T','I','D','A',' ',' ','F','I','N','A','L','I','Z','A','D','A',0
._score
	defb '-','-','-','P','U','N','T','U','A','C','I','O','N','E','S','-','-','-','-',0
._blue
	defb 'A','Z','U','L',':',' ',0
._red
	defb 'R','O','J','O',':',' ',0
._defeatstr
	defb ' ',0xC2,0xA1,'D','e','r','r','o','t','a','!',0
._victorystr
	defb 0xC2,0xA1,'V','i','c','t','o','r','i','a','!',0
._drawstr
        defb ' ',' ',0xC2,0xA1,'E','m','p','a','t','e','!',0
._outoflivesstr
	defb 0xC2,0xA1,'H','a','s',' ','m','u','e','r','t','o','!',0
#endasm
#else
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
._drawstr
        defb ' ',' ','D','r','a','w','!',0
._outoflivesstr
	defb 'N','o',' ','l','i','v','e','s','!',0
#endasm
#endif
