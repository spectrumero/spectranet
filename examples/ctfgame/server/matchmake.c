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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "ctfmessage.h"
#include "ctfserv.h"

uchar matchflags=0;

void setPlayerTeam(Player *p, uchar team) {
  // Maximum of 2 teams. 0=blue, 1=red, 2=no team
  if(team > 2) return;

  p->team=team;
	orderTeams();
  updateAllMatchmakers();
}

// A simple routine to put player numbers in order within the teams.
void orderTeams() {
	int teampos[3];
	int i;
	Player *p;

	memset(teampos, 0, sizeof(teampos));

	for(i=0; i<MAXCLIENTS; i++) {
		p=getPlayer(i);
		if(p) {
			p->playernum=teampos[p->team];
			teampos[p->team]++;
		}
	}
}

void updateAllMatchmakers() {
  ssize_t msgsz;
  uchar *msg=makeMatchMakeMsgs(&msgsz);
  sendToMatchmakers(msg, msgsz);
  free(msg);
}

void updateMatchmaker(int clientid) {
  ssize_t msgsz;
  uchar *msg=makeMatchMakeMsgs(&msgsz);
  sendMessageBuf(clientid, msg, msgsz);
  free(msg);
}

// Send a matchmake message with the current players and teams
// to any player that is matchmaking.
uchar *makeMatchMakeMsgs(ssize_t *msgsz) {
  int i;
  Player *p;
  MatchmakeMsg mmsg;
  uchar *mmptr, *mmbuf;

  mmbuf=(uchar *)malloc(MAXCLIENTS * sizeof(MatchmakeMsg) + MAXCLIENTS + 3);

	// preload with one message - tell the client to clear the player
	// list on its screen
  mmbuf[0]=1;
	mmbuf[1]=CLRPLAYERLIST;

  mmptr=&mmbuf[2];

  for(i=0; i<MAXCLIENTS; i++) {
    p=getPlayer(i);
    if(p) {
      *mmptr++=MATCHMAKEMSG;
      mmsg.team=p->team;
      mmsg.playernum=p->playernum;
      strlcpy(mmsg.playername, p->name, MAXNAME);
      mmbuf[0]++;
      memcpy(mmptr, &mmsg, sizeof(MatchmakeMsg));
      mmptr+=sizeof(MatchmakeMsg);
    }
  }
  *msgsz = mmptr-mmbuf;
  return mmbuf;
}

// broadcast the message to everyone in matchmaking
void sendToMatchmakers(void *mmbuf, ssize_t msgsz) {
  int i;
  Player *p;
  for(i=0; i<MAXCLIENTS; i++) {
    p=getPlayer(i);
    if(p && p->flags & MATCHMAKING) {
      sendMessageBuf(i, mmbuf, msgsz);
    }
  }
}
