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
int minPlayers;

void setPlayerTeam(Player *p, uchar team) {
#ifdef MM_DEBUG
	printf("DEBUG: setting player team for %s, team=%d\n",
			p->name, team);
#endif
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

void setMinPlayers(int p) {
  minPlayers=p;
}

uchar isGameStartable() {
	int i;
	Player *p;
	int count=0;

	for(i=0; i<MAXCLIENTS; i++) {
		p=getPlayer(i);
		if(p) {
			if(!(p->flags & PLYRREADY))
				return 0;		// Someone isn't ready
			if(p->team > 1 && !(p->flags & SPECTATOR) )
				return 0;		// Someone's not yet on a team
			count++;
		}
	}

	// Need at least 2 ready players 
	if(count < minPlayers)
		return 0;
	return 1;
}

// If the game is startable, signal to all matchmakers that they
// should leave matchmaking and join the game.
void tryToStopMatchmaking() {
	char buf[2];
	int i;
	Player *p;
	
	if(isGameStartable()) {
		buf[0]=1;	// 1 message
		buf[1]=MMEXIT;

		for(i=0; i<MAXCLIENTS; i++) {
			p=getPlayer(i);
			if(p && p->flags & MATCHMAKING) {
				// Reset all flags so the player can enter the limbo between
				// leaving matchmaking and starting the game.
				// Leave the PLYRREADY flag set so that late joiners
				// can join.
				p->flags=PLYRREADY;
				sendMessageBuf(i, buf, 2);
			}
            else if(p && p->flags & SPECTATOR) {
                sendMessageBuf(i, buf, 2);
            }
		}
	}
}

// Send a matchmake message with the current players and teams
// to any player that is matchmaking.
uchar *makeMatchMakeMsgs(ssize_t *msgsz) {
  int i;
  Player *p;
  MatchmakeMsg mmsg;
  uchar *mmptr, *mmbuf;

  mmbuf=(uchar *)malloc(MAXCLIENTS * sizeof(MatchmakeMsg) + MAXCLIENTS + 5);

	// preload with one message - tell the client to clear the player
	// list on its screen, and whether the game is startable
  mmbuf[0]=2;
	mmbuf[1]=CLRPLAYERLIST;
	mmbuf[2]=MMSTARTABLE;
	mmbuf[3]=isGameStartable();

  mmptr=&mmbuf[4];

  for(i=0; i<MAXCLIENTS; i++) {
    p=getPlayer(i);
    if(p) {
      *mmptr++=MATCHMAKEMSG;
      mmsg.team=p->team;
      mmsg.playernum=p->playernum;
			mmsg.flags=0;
			if(p->flags & PLYRREADY)
				mmsg.flags = MM_READY;

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
