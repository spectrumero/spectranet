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

#include "ctf.h"

#define LN32ATTRS	23264
#define PUTCHAR42 0x3e2a
#define PRINT42 0x3e2d
#define PRCOL	0x3F00
#define PRROW 0x3F01

// Messages printed at the bottom of the screen.
char gamemsg[43];
uchar msglen;
uchar msgpos;
#define MSGLINE 20704

void setupStatusAreas() {
	int i;
	MessageMsg welcome;
	uchar *ln32 = (unsigned char *) (LN32ATTRS);

	for(i=0; i<32; i++) {
		*ln32 = PAPER_BLUE|INK_YELLOW;
		ln32++;
	}

	strcpy(welcome.message, "Welcome to Spectank.");
	welcome.msgsz = strlen(welcome.message);
	setMsgArea(&welcome);

#asm
	ld hl, 16384
	ld (PRROW), hl
	ld a, 38
	ld (PRCOL), a
	ld hl, _nrg_str
	call PRINT42
	ld hl, 16480
	ld (PRROW), hl
	ld a, 38
	ld (PRCOL), a
	ld hl, _ammo_str
	call PRINT42
	ld hl, 20480
	ld (PRROW), hl
	ld a, 38
	ld (PRCOL), a
	ld hl, _flag_str
	call PRINT42

#endasm
}

void __FASTCALL__ displayEnergy(char *msg) {
#asm
	ld de, 16416
	ld (PRROW), de
	ld a, 38
	ld (PRCOL), a
	call PRINT42
#endasm
}

void __FASTCALL__ displayAmmo(char *msg) {
#asm
	ld de, 16512
	ld (PRROW), de
	ld a, 38
	ld (PRCOL), a
	call PRINT42
#endasm
}

void __FASTCALL__ setMsgArea(MessageMsg *msg) {
	strlcpy(gamemsg, msg->message, MAXSTATUSMSG);
	msgpos=0;
	msglen=msg->msgsz;
#asm
	ld hl, 0x50e0
	ld de, 0x50e1
	ld bc, 31
	xor a
	ld (hl), a
	ldir
	ld hl, 0x51e0
	ld de, 0x51e1
	ld bc, 31
	ld (hl), a
	ldir
	ld hl, 0x52e0
	ld de, 0x52e1
	ld bc, 31
	ld (hl), a
	ldir
	ld hl, 0x53e0
	ld de, 0x53e1
	ld bc, 31
	ld (hl), a
	ldir
	ld hl, 0x54e0
	ld de, 0x54e1
	ld bc, 31
	ld (hl), a
	ldir
	ld hl, 0x55e0
	ld de, 0x55e1
	ld bc, 31
	ld (hl), a
	ldir
	ld hl, 0x56e0
	ld de, 0x56e1
	ld bc, 31
	ld (hl), a
	ldir
	ld hl, 0x57e0
	ld de, 0x57e1
	ld bc, 31
	ld (hl), a
	ldir
#endasm
}

// Writes the next char to the message area
void updateMsgArea() {
	if(msgpos == msglen)
		return;
	putmsgchar(*(gamemsg+msgpos));
	msgpos++;
}

void __FASTCALL__ putmsgchar(char ch) {
#asm
	ld a, (_msgpos)
	ld (PRCOL), a
	ld de, 20704
	ld (PRROW), de
	ld a, l
	call PUTCHAR42		
#endasm
}

#asm
	._nrg_str	
	defb 'E','n','e','r',0
	._ammo_str
	defb 'A','m','m','o',0
	._flag_str
	defb 'F','l','a','g',0
#endasm
