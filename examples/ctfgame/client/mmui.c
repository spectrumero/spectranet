/* 
 * The MIT License
 *
 * Copyright (c) 2011 Dylan Smith
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */
#define UI_INK		INK_WHITE
#define UI_PAPER	PAPER_BLACK

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>

#include "matchmake.h"
#include "ctfmessage.h"

char player[9];
char server[16];
unsigned int teamChgLockout=LOCKOUTTIME;

void displayStatus(MessageMsg *msg) {
  ui_status(0, msg->message);
}

// Not strictly necessary, but it makes the code more maintainable.
char *getServer() {
  return server;
}

char *getPlayer() {
  return player;
}

void displayMatchmake(MatchmakeMsg *mmsg) {
	int hpos;
	int vpos;
	switch(mmsg->team) {
		case 0:		// blue team
			hpos=1;
			vpos=13+mmsg->playernum;
			break;
		case 1:		// red team
			hpos=20;
			vpos=13+mmsg->playernum;
			break;
		default:	// no team
			hpos=1;
			vpos=19+mmsg->playernum;
	}
	if(mmsg->flags & MM_READY)
		hpos--;

	setpos(vpos, hpos);
	if(mmsg->flags & MM_READY)
		printk("\x121*\x120");

	printk("%s", mmsg->playername);
}

void getMatchmakeInput() {
	char kb;

	// This is just a simple method to stop a flood of messages if
	// someone holds a key down.
	if(teamChgLockout)
		teamChgLockout--;
	       
 	if(keyReady()) 
		kb=getSingleKeypress();
	else
		return;

	if(!teamChgLockout)
	{
		switch(kb) {
			case '1':
				// Join the blue team
				sendJoinTeam(0);
				teamChgLockout=LOCKOUTTIME;
				break;
			case '2':
				// Join the red team
				sendJoinTeam(1);
				teamChgLockout=LOCKOUTTIME;
				break;
			case '0':
				// Signal that we are ready
				sendPlayerRdy();
				teamChgLockout=LOCKOUTTIME;
				break;
		}
	}
}

int getPlayerData()
{
  char *str;
  uchar key;
  int rc;

  setpos(10,0);
  printk("Leaving a field blank aborts\n\n");
  printk("\x10\x36Playername:\nServer:\n\n");
  putchar(' ');

  str=abortablekbinput(11, 12, sizeof(player)+1, 1, sizeof(player), 0);
  if(!str) return 0;
  strlcpy(player, str, sizeof(player));

  str=abortablekbinput(11, 13, sizeof(server)+1, 1, sizeof(server), 0);
  if(!str) return 0;
  strlcpy(server, str, sizeof(server));

  ui_status(0, "Connecting....");
}

void ui_status(int code, char *msg)
{
  setpos(20,0);
  setUIAttrs();
  printk("                               ");
  setpos(20,0);
  printk("\x10\x36\x11\x32");
  if(!msg)
  {
    printk("Code %d - failed!\n", code);
  }
  else
  {
    if(code == 0)
      printk("%s\n", msg);
    else
      printk("Code %d - %s\n", code, msg);
  }
  setUIAttrs();
}

char *abortablekbinput(int x, int y, int wid, int ht, int sz, char pw)
{
  char *str;
  char kb;

  while(1)
  {
    resetinput(x, y, wid, ht, sz);
    str=kbinput(pw);
    if(!*str)
    {
      setpos(22,0);
      setUIAttrs();
      printk("\x10\x36Sure you want to abort?\x10\x34 (Y/N)");
      while(1)
      {
        kb=getSingleKeypress();
        if(kb) break;
      }

      setpos(22, 0);
      printk("                                ");
      if(kb == 'y')
        return NULL;
    }
    else
      break;
  }
  return str;
}

void ia_cls()
{
  // 32 cols, BRIGHT 1
  printk("\x01\x20\x13\x01");
  setUIAttrs();
  zx_border(0);
  zx_colour(INK_WHITE|PAPER_BLACK);
}

void setUIAttrs()
{
  printk("\x10\x36\x11\x48");
}

void setpos(char y, char x)
{
  putchar(22);
  putchar(y+32);
  putchar((x*2)+32);
}

void drawMatchmakingScreen()
{
	clrlower();
	setpos(6, 1);
	printk("Press 0 when ready\n");
	printk("       1 to join BLUE\n");
	printk("       2 to join RED\n");
	setpos(11,1);
	printk("\x111BLUE TEAM");
	setpos(11,20);
	printk("\x112RED TEAM");
	setpos(17,1);
	printk("\x110Not on a team yet:");
}

void setStartable(uchar isStartable) {
	setpos(9,7);
	if(isStartable) {
		printk("S to start game");
	}
	else {
		printk("               ");
	}
}

// Very simple routine to wipe over the lower part of the screen with
// spaces to clear it.
void clrlower() 
{
	int i;
	setpos(7, 0);
	for(i=0; i<16; i++)
	{
		printk("                                 ");
	}
}

// Simple routine to put spaces over where the names were
void clearPlayerList() 
{
	uchar i;
	setpos(13,0);
	for(i=0; i<4; i++)
	{
		printk("                                ");
	}

	setpos(19,0);
	for(i=0; i<4; i++)
	{
		printk("                                ");
	}
}

