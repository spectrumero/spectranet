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

#include <sprites/sp1.h>
#include <spectrum.h>
#include "ctf.h"
#include "message.h"

uchar fondo[] = {0x80,0x00,0x04,0x00,0x40,0x00,0x02,0x00}; 

// Development: the gr_window sprite graphic
extern uchar gr_window[];
 
// Definimos el area total en tiles (32x24 tiles) para
// poder inicializar toda la pantalla
struct sp1_Rect cr = {0, 0, 32, 24}; 

// Sprite table
struct sprentry {
	struct sp1_ss	*s;
	uchar		x;
	uchar		y;
};

struct sprentry sprtbl[10];

void initSpriteLib() {
	// test
	MakeSpriteMsg msg;
	MoveSpriteMsg move;
	int i, j, k;
	k=2;

	zx_border(BLACK);
	sp1_Initialize
		(SP1_IFLAG_MAKE_ROTTBL | 
		SP1_IFLAG_OVERWRITE_TILES | 
		SP1_IFLAG_OVERWRITE_DFILE, INK_BLUE | PAPER_CYAN, ' '); 
	sp1_TileEntry(' ',fondo);
	sp1_Invalidate(&cr);
   	sp1_UpdateNow();   

	// test
	msg.objid=1;
	msg.x=30;
	msg.y=30;;
	msg.rotation=0;
	msg.id=0;
	putSprite(&msg);

	move.objid=1;
	move.x=100;
	move.y=30;
	move.rotation=0;

	for(j=0; j<10; j++) {
		k=-k;
		for(i=0; i<50; i++) {
			move.x+=k;
			move.y++;	
			moveSprite(&move);
		}	
	}
}

// Put a sprite on the screen.
void putSprite(MakeSpriteMsg *msg) {
	struct sprentry *se;
	struct sp1_ss *s;
	uchar snum=msg->objid;

	se=&sprtbl[snum];
	se->x=msg->x;
	se->y=msg->y;

	s=sprtbl[snum].s=
		sp1_CreateSpr(SP1_DRAW_MASK2LB, SP1_TYPE_2BYTE, 3, 0, snum);
 	sp1_AddColSpr(s, SP1_DRAW_MASK2, 0, 48, snum);
 	sp1_AddColSpr(s, SP1_DRAW_MASK2RB, 0, 0, snum);
 	sp1_MoveSprAbs(s, &cr, gr_window, 0, 0, msg->y, msg->x);
	sp1_UpdateNow();
}

// Move a sprite. The message itself contains absolute values
// because if a message gets dropped, the client would be forever
// out of sync with the server. So the relative movement needs
// to be calculated.
void moveSprite(MoveSpriteMsg *msg) {
	struct sprentry *se;
	uchar snum=msg->objid;
	char dx;
	char dy;
	
	se=&sprtbl[snum];
	dx=msg->x-se->x;
	dy=msg->y-se->y;

	se->x=msg->x;
	se->y=msg->y;

	sp1_MoveSprRel(se->s, &cr, 0, 0, 0, dy, dx);
	sp1_UpdateNow();
}
#asm

   defb @11111111, @00000000
   defb @11111111, @00000000
   defb @11111111, @00000000
   defb @11111111, @00000000
   defb @11111111, @00000000
   defb @11111111, @00000000
   defb @11111111, @00000000

; ASM source file created by SevenuP v1.20
; SevenuP (C) Copyright 2002-2006 by Jaime Tejedor Gomez, aka Metalbrain

;GRAPHIC DATA:
;Pixel Size:      ( 16,  24)
;Char Size:       (  2,   3)
;Sort Priorities: Mask, Char line, Y char, X char
;Data Outputted:  Gfx
;Interleave:      Sprite
;Mask:            Yes, before graphic

._gr_window

;        DEFB    128,127,  0,192,  0,191, 30,161
;        DEFB     30,161, 30,161, 30,161,  0,191
;        DEFB      0,191, 30,161, 30,161, 30,161
;        DEFB     30,161,  0,191,  0,192,128,127
;        DEFB    255,  0,255,  0,255,  0,255,  0
;        DEFB    255,  0,255,  0,255,  0,255,  0

;        DEFB      1,254,  0,  3,  0,253,120,133
;        DEFB    120,133,120,133,120,133,  0,253
;        DEFB      0,253,120,133,120,133,120,133
;        DEFB    120,133,  0,253,  0,  3,  1,254
;        DEFB    255,  0,255,  0,255,  0,255,  0
;        DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  0,  0, 31,  0, 53
  DEFB    0, 95,  0, 78,  0, 82,  0,226
  DEFB    0,226,  0, 82,  0, 78,  0, 95
  DEFB    0, 53,  0, 31,  0,  0,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  0,  0,255,  0, 85
  DEFB    0,255,  0,  2,  0,  5,  0,125
  DEFB    0,125,  0,  5,  0,  2,  0,255
  DEFB    0, 85,  0,255,  0,  0,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0


#endasm

