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
uchar printpos;
uchar flagindbg;

#define MSGLINE 20704

void setupStatusAreas(uchar teamcolours) {
	int i;
	MessageMsg welcome;
	uchar *ln32 = (unsigned char *) (LN32ATTRS);

	flagindbg=teamcolours;
	drawFlagIndicator();
	quietenFlagIndicator();

	for(i=0; i<32; i++) {
		*ln32 = PAPER_BLUE|INK_YELLOW;
		ln32++;
	}
#ifdef LANG_ES
	strcpy(welcome.message, "Bienvenido a Spectank.");
#else
	strcpy(welcome.message, "Welcome to Spectank.");
#endif
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
	ld hl, 16576
	ld (PRROW), hl
	ld a, 38
	ld (PRCOL), a
	ld hl, _player_score
	call PRINT42
	ld hl, 20480
	ld (PRROW), hl
	ld a, 38
	ld (PRCOL), a
	ld hl, _flag_str
	call PRINT42

	ld hl, 0x4820
	ld (PRROW), hl
	ld a, 38
	ld (PRCOL), a
	ld hl, _blue_score
	call PRINT42
	ld hl, 0x4880
	ld (PRROW), hl
	ld a, 38
	ld (PRCOL), a
	ld hl, _red_score
	call PRINT42

#endasm
}

void updateScoreboard(NumberMsg *msg) {
	switch(msg->numtype) {
		case AMMOQTY:
			displayAmmo(msg->message);
			break;
		case HITPOINTQTY:
			displayEnergy(msg->message);
			break;
		case REDSCORE:
			displayRedScore(msg->message);
			break;
		case BLUESCORE:
			displayBlueScore(msg->message);
			break;
		case PLYRSCORE:
			displayPlayerScore(msg->message);
	}
}

void __FASTCALL__ displayEnergy(char *msg) {
#asm
	push hl
	ld hl, 0x403c
	ld b, 8
._clr_nrg
	ld (hl), 0
	inc l
	ld (hl), 0
	inc l
	ld (hl), 0
	inc l
	ld (hl), 0
	inc h
	ld l, 0x3c
	djnz _clr_nrg
	pop hl

	ld de, 16416
	ld (PRROW), de
	ld a, 38
	ld (PRCOL), a
	call PRINT42
#endasm
}

void __FASTCALL__ displayAmmo(char *msg) {
#asm
	push hl
	
	ld hl, 0x409c
	ld b, 8
._clr_ammo
	ld (hl), 0
	inc l
	ld (hl), 0
	inc l
	ld (hl), 0
	inc l
	ld (hl), 0
	inc h
	ld l, 0x9c
	djnz _clr_ammo	

	pop hl
	ld de, 16512
	ld (PRROW), de
	ld a, 38
	ld (PRCOL), a
	call PRINT42
#endasm
}

void __FASTCALL__ displayPlayerScore(char *msg) {
#asm
	push hl

	ld hl, 0x40fc
	ld b, 8
._clr_pscr
	ld (hl), 0
	inc l
	ld (hl), 0
	inc l
	ld (hl), 0
	inc l
	ld (hl), 0
	inc h
	ld l, 0xfc
	djnz _clr_pscr

	pop hl
	ld de, 0x40e0
	ld (PRROW), de
	ld a, 38
	ld (PRCOL), a
	call PRINT42
#endasm
}

void __FASTCALL__ displayBlueScore(char *msg) {
#asm
	push hl
	
	ld hl, 0x485c
	ld b, 8
._clr_blue
	ld (hl), 0
	inc l
	ld (hl), 0
	inc l
	ld (hl), 0
	inc l
	ld (hl), 0
	inc h
	ld l, 0x5c
	djnz _clr_blue

	pop hl
	ld de, 0x4840
	ld (PRROW), de
	ld a, 38
	ld (PRCOL), a
	call PRINT42
#endasm
}

void __FASTCALL__ displayRedScore(char *msg) {
#asm
	push hl
	
	ld hl, 0x48bc
	ld b, 8
._clr_red
	ld (hl), 0
	inc l
	ld (hl), 0
	inc l
	ld (hl), 0
	inc l
	ld (hl), 0
	inc h
	ld l, 0xbc
	djnz _clr_red

	pop hl
	ld de, 0x48a0
	ld (PRROW), de
	ld a, 38
	ld (PRCOL), a
	call PRINT42
#endasm
}

void __FASTCALL__ setMsgArea(MessageMsg *msg) {
	strlcpy(gamemsg, msg->message, MAXSTATUSMSG);
	msgpos=0;
	printpos=0;
	msglen=msg->msgsz;
	clearStatusLine();
}

void clearStatusLine() {
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
	uchar ch;
	if(msgpos == msglen)
		return;
	ch=*(gamemsg+msgpos);
	putmsgchar(ch);

	// don't advance the print position in case of characters
	// that might be part of a UTF8 sequence. We only care about
	// 0xC3/0xC2 sequences.
	if(ch != 0xC3 && ch != 0xC2) {
		printpos++;
	}
	msgpos++;
}

void __FASTCALL__ putmsgchar(char ch) {
#asm
	ld a, (_printpos)
	ld (PRCOL), a
	ld de, 20704
	ld (PRROW), de
	ld a, l
	call PUTCHAR42		
#endasm
}

void __FASTCALL__ putEntireMessage(char *msg) {
#asm
	push hl
#endasm
	clearStatusLine();
#asm
	xor a
	ld (PRCOL), a
	ld de, 20704
	ld (PRROW), de
	pop hl
	call PRINT42
#endasm
}

void __FASTCALL__ flagAlert(uchar msg) {
	quietenFlagIndicator();
	if(msg != 0xFF) 
		flashFlagIndicator(msg);
}

void __FASTCALL__ flashFlagIndicator(uchar sector) {
#asm
	ld d, 0x5a
	ld a, l
	and 0x70		; top 4 bits indicate row
	jr z, _top
	cp 0x10
	jr z, _mid
	ld e, 0x9d
	jr _place

._mid
	ld e, 0x7d
	jr _place

._top
	ld e, 0x5d
._place
	ld a, l
	and 0x07		; bottom 4 bits indicate column
	add a, e
	ld e, a
	ld a, (_flagindbg)
	or 0x80			; set flash bit
	ld (de), a
#endasm
}

void quietenFlagIndicator() {
#asm
	ld a, (_flagindbg)
	ld hl, 0x5a5d
	ld (hl), a
	inc l
	ld (hl), a
	inc l
	ld (hl), a
	ld l, 0x7d
	ld (hl), a
	inc l
	ld (hl), a
	inc l
	ld (hl), a
	ld l, 0x9d
	ld (hl), a
	inc l
	ld (hl), a
	inc l
	ld (hl), a
#endasm
}
#ifdef LANG_ES
#asm
	._nrg_str	
	defb 'E','n','e','r',0
	._ammo_str
	defb 'M','i','s','l',0
	._flag_str
	defb 'F','l','a','g',0
	._player_score
	defb 'P','t','s',0
	._red_score
	defb 'R','o','j','o',0
	._blue_score
	defb 'A','z','u','l',0
#endasm
#else
#asm
	._nrg_str	
	defb 'E','n','e','r',0
	._ammo_str
	defb 'A','m','m','o',0
	._flag_str
	defb 'F','l','a','g',0
	._player_score
	defb 'P','t','s',0
	._red_score
	defb 'R','e','d',0
	._blue_score
	defb 'B','l','u','e',0
#endasm
#endif
