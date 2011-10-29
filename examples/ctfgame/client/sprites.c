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
#include <string.h>
#include <stdio.h>

#include "ctf.h"
#include "ctfmessage.h"

uchar fondo[] = {0x80,0x00,0x04,0x00,0x40,0x00,0x02,0x00};
uchar box[] =   {0xFF,0x81,0x81,0x81,0x81,0x81,0x81,0xFF};
uchar spawn[] = {0x00,0x42,0x24,0x00,0x00,0x24,0x42,0x00};
int clr;

// Development: the gr_window sprite graphic
extern uchar tank[];
extern uchar foton[];
extern uchar xplode[];
//extern uchar fuel[];
//extern uchar ammo[];

uchar fotonFrame=0;
uchar *fotonPtr;
uchar fotonAnimDir=0;
uchar fcount=0;
uchar xplodeFrame=0;

// Sprite lookup table
uchar *spritelist[] = {tank, foton, xplode}; //, fuel, ammo};
int tankdir[]={0, 96, 192, 288,
             384, 480, 576, 672,
             768, 864, 960, 1056,
             1152, 1248, 1344, 1440};

// Main game viewport
struct sp1_Rect cr = {0, 0, VPXTILES, VPYTILES}; 

// Sprite table
struct sprentry {
	struct sp1_ss	*s;
	uchar		x;
	uchar		y;
};

struct sp1_ss *sprtbl[MAXOBJS];

void initSpriteLib() {
	memset(sprtbl, 0, sizeof(sprtbl));
	clr=0;

   zx_border(BLACK);
   sp1_Initialize(SP1_IFLAG_MAKE_ROTTBL | SP1_IFLAG_OVERWRITE_TILES | SP1_IFLAG_OVERWRITE_DFILE, INK_WHITE | PAPER_BLACK, ' ');
   sp1_TileEntry(' ', fondo);   // redefine graphic associated with space character
	 sp1_TileEntry('B', box);
	 sp1_TileEntry('s', spawn);

   sp1_Invalidate(&cr);        // invalidate entire screen so that it is all initially drawn
   sp1_UpdateNow();            // draw screen area managed by sp1 now
	fotonPtr=foton;
}

// The msgbuf pointer should be at the count parameter of
// the buffer (the third byte in a complete message)
void drawMap(uchar *msgbuf) {
  uint16_t i;
	uchar colour;
  MaptileMsg *mtm;
  uint16_t *nummsgs=(uint16_t)msgbuf;
  msgbuf+=2;

  sp1_ClearRect(&cr, INK_WHITE|PAPER_BLACK, ' ', SP1_RFLAG_TILE|SP1_RFLAG_COLOUR);

	for(i=0; i != *nummsgs; i++) {
		mtm=(MaptileMsg *)msgbuf;
		switch(mtm->tile) {
			case 's':
				colour=INK_YELLOW|PAPER_BLACK;
				break;
			default:
				colour=INK_BLUE|PAPER_BLACK;
		}				
		sp1_PrintAt(mtm->y, mtm->x, colour, mtm->tile);
		msgbuf+=sizeof(MaptileMsg);
	}
	sp1_Invalidate(&cr);
  sp1_UpdateNow();
}

// Decide whether to move or create a sprite.
void manageSprite(SpriteMsg *msg) {
	if(sprtbl[msg->objid]) {
		moveSprite(msg);
	} else {
		putSprite(msg);
	}
}

// Put a sprite on the screen.
void putSprite(SpriteMsg *msg) {
	struct sp1_ss *s;
	uchar snum=msg->objid;

	s = sp1_CreateSpr(SP1_DRAW_MASK2LB, SP1_TYPE_2BYTE, 3, 0, snum);
  sp1_AddColSpr(s, SP1_DRAW_MASK2, 0, 48, snum);
  sp1_AddColSpr(s, SP1_DRAW_MASK2RB, 0, 0, snum);
  sp1_MoveSprPix(s, &cr, spritelist[msg->id], msg->x, msg->y);
	sprtbl[snum]=s;
}

// Move a sprite. The message itself contains absolute values
// because if a message gets dropped, the client would be forever
// out of sync with the server. So the relative movement needs
// to be calculated.
void moveSprite(SpriteMsg *msg) {
	struct sp1_ss *s=sprtbl[msg->objid];
	uchar *frameptr;
	switch(msg->id) {
		case XPLODE:
			frameptr=xplode;
			if(xplodeFrame) {
				frameptr+=96;
			}
			xplodeFrame = !xplodeFrame;
			break;
		case FOTON:
			if(fotonAnimDir) {
				fotonFrame--;
				fotonPtr-=96;
				if(fotonFrame == 0)
					fotonAnimDir=0;
			} else {
				fotonFrame++;
				fotonPtr+=96;
				if(fotonFrame == 3)
					fotonAnimDir=1;	
			}
			frameptr=fotonPtr;
			break;
		case PLAYER:
			frameptr=tank + tankdir[msg->rotation];
			break;
		default:
			frameptr=spritelist[msg->id];
	}	

	sp1_MoveSprPix(s, &cr, frameptr, msg->x, msg->y);
}

void removeAllSprites() {
	int i;
	struct sp1_ss *s;
	
	for(i=0; i<MAXOBJS; i++) {
		s=sprtbl[i];
		if(s) {
  		sp1_MoveSprAbs(s, &cr, tank, 33, 25, 0, 0);
			sp1_DeleteSpr(s);
			sprtbl[i]=NULL;
		}
	}
	sp1_Invalidate(&cr);
	sp1_UpdateNow();
}

void removeSprite(RemoveSpriteMsg *msg) {
	struct sp1_ss *s;
	s=sprtbl[msg->objid];
	if(s) {
		sp1_MoveSprAbs(s, &cr, tank, 33, 25, 0, 0);
		sp1_DeleteSpr(s);
		sprtbl[msg->objid]=NULL;
	}
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

._tank	
  DEFB    0,  0,  0,  7,  0,  8,  0,  9
  DEFB    0, 17,  0, 49,  0, 17,  0, 49
  DEFB    0, 17,  0, 51,  0, 20,  0, 52
  DEFB    0, 20,  0, 51,  0, 31,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,224,  0, 16,  0,144
  DEFB    0,136,  0,140,  0,136,  0,140
  DEFB    0,136,  0,204,  0, 40,  0, 44
  DEFB    0, 40,  0,204,  0,248,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  0,  0, 11,  0,  4
  DEFB    0, 20,  0,  8,  0, 40,  0, 17
  DEFB    0, 87,  0, 37,  0,168,  0, 88
  DEFB    0, 52,  0, 15,  0,  3,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,192,  0, 48,  0, 72
  DEFB    0,100,  0,228,  0,196,  0,134
  DEFB    0,136,  0,140,  0, 80,  0, 88
  DEFB    0,160,  0,176,  0, 64,  0,224
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  2,  0,  1,  0, 10
  DEFB    0,  4,  0, 40,  0, 16,  0,173
  DEFB    0, 83,  0,161,  0, 80,  0, 56
  DEFB    0, 31,  0, 14,  0,  5,  0,  2
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0, 96,  0,144,  0,  8
  DEFB    0, 52,  0,114,  0,226,  0,196
  DEFB    0,132,  0, 10,  0,144,  0,168
  DEFB    0, 64,  0,160,  0,  0,  0,128
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  1,  0,  4,  0, 19
  DEFB    0, 76,  0, 48,  0,196,  0, 91
  DEFB    0,113,  0, 48,  0, 56,  0, 25
  DEFB    0, 22,  0, 11,  0, 12,  0,  2
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0, 64,  0,248,  0,  8
  DEFB    0,  4,  0, 54,  0,242,  0,194
  DEFB    0,130,  0,132,  0,140,  0, 50
  DEFB    0,200,  0, 32,  0,128,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  0,  0, 42,  0,127
  DEFB    0, 64,  0, 92,  0, 98,  0, 99
  DEFB    0, 99,  0, 98,  0, 92,  0, 64
  DEFB    0,127,  0, 42,  0,  0,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  0,  0,160,  0,240
  DEFB    0, 12,  0,  2,  0,  2,  0,250
  DEFB    0,250,  0,  2,  0,  2,  0, 12
  DEFB    0,240,  0,160,  0,  0,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  4,  0,  9,  0, 22,  0, 25
  DEFB    0, 44,  0, 51,  0, 97,  0, 99
  DEFB    0,179,  0,204,  0,176,  0, 44
  DEFB    0, 11,  0,  2,  0,  0,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  0,  0, 64,  0,144
  DEFB    0,100,  0, 24,  0,  4,  0,132
  DEFB    0,226,  0,122,  0, 52,  0,  4
  DEFB    0,  8,  0,240,  0,128,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  2,  0,  5,  0, 10,  0, 29
  DEFB    0, 56,  0,112,  0,177,  0, 83
  DEFB    0,173,  0, 16,  0, 40,  0,  4
  DEFB    0, 10,  0,  1,  0,  2,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,128,  0,  0,  0,160,  0, 64
  DEFB    0,168,  0,144,  0, 10,  0,132
  DEFB    0,196,  0,226,  0,114,  0, 52
  DEFB    0,  8,  0,144,  0, 96,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  1,  0,  7,  0, 31
  DEFB    0,108,  0, 80,  0,176,  0, 41
  DEFB    0, 87,  0, 16,  0, 40,  0,  8
  DEFB    0, 20,  0,  6,  0,  9,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0, 64,  0,208,  0, 32,  0,168
  DEFB    0,144,  0, 84,  0,136,  0,138
  DEFB    0,196,  0,198,  0,100,  0,100
  DEFB    0, 12,  0, 48,  0,224,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0, 31,  0, 51,  0, 20
  DEFB    0, 52,  0, 20,  0, 51,  0, 17
  DEFB    0, 49,  0, 17,  0, 49,  0, 17
  DEFB    0,  9,  0,  8,  0,  7,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,248,  0,204,  0, 40
  DEFB    0, 44,  0, 40,  0,204,  0,136
  DEFB    0,140,  0,136,  0,140,  0,136
  DEFB    0,144,  0, 16,  0,224,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  7,  0,  2,  0, 13,  0,  5
  DEFB    0, 26,  0, 10,  0, 49,  0, 17
  DEFB    0, 97,  0, 35,  0, 39,  0, 38
  DEFB    0, 18,  0, 12,  0,  3,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,192,  0,240,  0, 44
  DEFB    0, 26,  0, 21,  0,164,  0,234
  DEFB    0,136,  0, 20,  0, 16,  0, 40
  DEFB    0, 32,  0,208,  0,  0,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  1,  0,  0,  0,  5,  0,  2
  DEFB    0, 21,  0,  9,  0, 80,  0, 33
  DEFB    0, 35,  0, 71,  0, 78,  0, 44
  DEFB    0, 16,  0,  9,  0,  6,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0, 64,  0,160,  0,112,  0,248
  DEFB    0, 28,  0, 10,  0,133,  0,202
  DEFB    0,181,  0,  8,  0, 20,  0, 32
  DEFB    0, 80,  0,128,  0, 64,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  1,  0,  4,  0, 19
  DEFB    0, 76,  0, 49,  0, 33,  0, 65
  DEFB    0, 67,  0, 79,  0,108,  0, 32
  DEFB    0, 16,  0, 31,  0,  2,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0, 64,  0, 48,  0,208,  0,104
  DEFB    0,152,  0, 28,  0, 12,  0,142
  DEFB    0,218,  0, 35,  0, 12,  0, 50
  DEFB    0,200,  0, 32,  0,128,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  0,  0,  5,  0, 15
  DEFB    0, 48,  0, 64,  0, 64,  0, 95
  DEFB    0, 95,  0, 64,  0, 64,  0, 48
  DEFB    0, 15,  0,  5,  0,  0,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  0,  0, 84,  0,254
  DEFB    0,  2,  0, 58,  0, 70,  0,198
  DEFB    0,198,  0, 70,  0, 58,  0,  2
  DEFB    0,254,  0, 84,  0,  0,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  1,  0, 15,  0, 16
  DEFB    0, 32,  0, 44,  0, 94,  0, 71
  DEFB    0, 33,  0, 32,  0, 24,  0, 38
  DEFB    0,  9,  0,  2,  0,  0,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  0,  0, 64,  0,208
  DEFB    0, 52,  0, 13,  0, 51,  0,205
  DEFB    0,198,  0,134,  0,204,  0, 52
  DEFB    0,152,  0,104,  0,144,  0, 32
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  6,  0,  9,  0, 16
  DEFB    0, 44,  0, 78,  0, 71,  0, 35
  DEFB    0, 33,  0, 80,  0,  9,  0, 21
  DEFB    0,  2,  0,  5,  0,  0,  0,  1
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0, 64,  0,128,  0, 80
  DEFB    0, 32,  0, 20,  0,  8,  0,181
  DEFB    0,202,  0,141,  0, 14,  0, 28
  DEFB    0,184,  0, 80,  0,160,  0, 64
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  7,  0, 12,  0, 48
  DEFB    0, 38,  0, 38,  0, 99,  0, 35
  DEFB    0, 81,  0, 17,  0, 42,  0,  9
  DEFB    0, 21,  0,  4,  0, 11,  0,  2
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,144,  0, 96,  0, 40
  DEFB    0, 16,  0, 20,  0,  8,  0,234
  DEFB    0,148,  0, 13,  0, 10,  0, 54
  DEFB    0,248,  0,224,  0,128,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

._foton	
  DEFB    0,  0,  0,  0,  0,  0,  0,  0
  DEFB    0,  0,  0,  1,  0,  2,  0,  4
  DEFB    0,  5,  0,  2,  0,  1,  0,  0
  DEFB    0,  0,  0,  0,  0,  0,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  0,  0,  0,  0,  0
  DEFB    0,  0,  0,128,  0, 64,  0,160
  DEFB    0, 32,  0, 64,  0,128,  0,  0
  DEFB    0,  0,  0,  0,  0,  0,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  0,  0,  0,  0, 16
  DEFB    0,  8,  0,  5,  0,  2,  0,  5
  DEFB    0,  4,  0,  2,  0,  5,  0,  8
  DEFB    0, 16,  0,  0,  0,  0,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  0,  0,  0,  0,  8
  DEFB    0, 16,  0,160,  0, 64,  0, 32
  DEFB    0,160,  0, 64,  0,160,  0, 16
  DEFB    0,  8,  0,  0,  0,  0,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0, 80,  0, 34,  0, 84
  DEFB    0,  8,  0, 21,  0, 34,  0,  4
  DEFB    0,  5,  0, 34,  0, 21,  0,  8
  DEFB    0, 84,  0, 34,  0, 80,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0, 10,  0, 68,  0, 42
  DEFB    0, 16,  0,168,  0, 68,  0,160
  DEFB    0, 32,  0, 68,  0,168,  0, 16
  DEFB    0, 42,  0, 68,  0, 10,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  1,  0,  3,  0, 65,  0,  7
  DEFB    0, 17,  0,  1,  0, 18,  0, 84
  DEFB    0,252,  0, 82,  0, 17,  0,  0
  DEFB    0, 11,  0,  0,  0, 33,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,132,  0,  0,  0,208
  DEFB    0,  0,  0,136,  0, 74,  0, 63
  DEFB    0, 42,  0, 72,  0,128,  0,136
  DEFB    0,224,  0,130,  0,192,  0,128
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

._xplode
  DEFB    0,  0,  0,  4,  0,  6,  0,  5
  DEFB    0,124,  0, 32,  0, 17,  0, 10
  DEFB    0, 10,  0, 16,  0, 32,  0, 71
  DEFB    0,240,  0, 12,  0,  3,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  3,  0, 14,  0, 52
  DEFB    0,200,  0, 28,  0,130,  0, 31
  DEFB    0, 24,  0,132,  0,180,  0, 10
  DEFB    0, 98,  0, 89,  0, 71,  0,193
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0, 64,  0, 98,  0, 51,  0, 42
  DEFB    0, 22,  0, 17,  0, 10,  0, 10
  DEFB    0,  4,  0,252,  0, 67,  0, 32
  DEFB    0, 30,  0,  2,  0,  5,  0,  6
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  0,  0,  1,  0,131
  DEFB    0, 69,  0,170,  0, 18,  0,  4
  DEFB    0,136,  0,159,  0,  1,  0, 98
  DEFB    0,140,  0, 48,  0,192,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
#endasm

/*
._ammo
  DEFB    0,  0,  0,  0,  0,248,  0,255
  DEFB    0,192,  0,195,  0,252,  0, 64
  DEFB    0,221,  0, 80,  0, 92,  0, 80
  DEFB    0, 80,  0,127,  0,  0,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,  0,  0,  0,  0,  0,  0,255
  DEFB    0, 61,  0,193,  0,  1,  0,  1
  DEFB    0,211,  0,155,  0,151,  0,147
  DEFB    0,147,  0,255,  0,  0,  0,  0
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

._fuel
  DEFB    0, 31,  0, 16,  0, 51,  0, 82
  DEFB    0, 83,  0,114,  0, 50,  0, 63
  DEFB    0, 36,  0, 39,  0, 28,  0,  7
  DEFB    0,  4,  0,  7,  0,  4,  0,127
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

  DEFB    0,248,  0,  8,  0,200,  0,  8
  DEFB    0,200,  0,  8,  0,  8,  0,248
  DEFB    0, 32,  0,160,  0, 32,  0,160
  DEFB    0, 32,  0,160,  0, 32,  0,254
  DEFB    255,  0,255,  0,255,  0,255,  0
  DEFB    255,  0,255,  0,255,  0,255,  0

#endasm */
