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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "ctfmessage.h"
#include "ctfserv.h"

// endMatch puts each player into SCORESCRN status and frees all the
// game objects.
void endMatch() {
	int i;
	Player *p;

	for(i=0; i<MAXCLIENTS; i++) {
		p=getPlayer(i);
		if(p) 
			p->flags = SCORESCRN;
	}
}

void broadcastEndMatch() {
	GameEnd geMsg;
	int i;
	int winner;

	// setup server scoreboard for a new match score
	newScore(true);

	snprintf(geMsg.bluecapture, 4, "%d", getTeamscore(BLUETEAM));
	snprintf(geMsg.redcapture, 4, "%d", getTeamscore(REDTEAM));

	winner = (getTeamscore(BLUETEAM) > getTeamscore(REDTEAM)) 
		? BLUETEAM : REDTEAM;
	printMessage("**** Game Over ****");
	if(winner == BLUETEAM) 
		printMessage("Blue team wins!");
	else
		printMessage("Red team wins!");

	addTeamScore(BLUETEAM, getTeamscore(BLUETEAM), winner);
	addTeamScore(REDTEAM, getTeamscore(REDTEAM), winner);

	for(i=0; i<MAXCLIENTS; i++) {
		Player *p=getPlayer(i);
		if(p) {
			geMsg.winner = (p->team == winner) ? 1 : 0;
			addMessage(i, ENDGAMESCORE, &geMsg, sizeof(geMsg));
			addPlayerName(p->team, p->name, winner);
		}
	}
	endScore();
}

