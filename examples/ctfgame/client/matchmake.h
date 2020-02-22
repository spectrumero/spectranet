#ifndef _MATCHMAKE_H
#define _MATCHMAKE_H
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

#include "ctfmessage.h"

#define TXERROR -3
#define RXERROR -4
#define NACK -5
#define TIMEOUT -6
#define LOCKOUTTIME 512

// Functions for the match maker
extern int getPlayerData();
extern void ui_status(int code, char *msg);
extern char *abortablekbinput(int x, int y, int wid, int ht, int sz, char pw);
extern void ia_cls();
extern void setUIAttrs();
extern void setpos(char y, char x);
extern void replaceSpaces(char *str);

// IM2 input routines
extern void resetinput(char sx, char sy, char wid, char hgt, int len);
extern void clearArea(char ink, char paper);
extern void colourArea(char ink, char paper);
extern void moveToCurrent();
extern void handleKey(uchar key);
extern char *checkKey();
extern char *kbinput(char ispw);
extern char getSingleKeypress();
extern char keyReady();
extern void inputinit();
extern void inputexit();

// Main UI stuff
extern void displayStatus(MessageMsg *msg);
extern void displayMatchmake(MatchmakeMsg *mmsg);
extern void getMatchmakeInput();
extern char *getServer();
extern char *getPlayer();
extern void drawMatchmakingScreen();
extern void clearPlayerList();
extern void clrlower();
extern void setStartable(uchar isStartable);
extern void __FASTCALL__ getDefaultServer(char *buf);
extern void fadeOut();

// Communications
extern int initConnection(char *host, char *player);
extern int sendSyncMsg(int txbytes);
extern int sendMsg(int txbytes);
extern int messageloop();

extern int readyToMatchmake();
extern int sendJoinTeam(int team);
extern int sendPlayerRdy();
extern int sendMatchmakeStop();

#endif

