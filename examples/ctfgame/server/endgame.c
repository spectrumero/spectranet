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
	Player *p, *dead;

	// setup server scoreboard for a new match score
	newScore(true);

	snprintf(geMsg.bluecapture, 4, "%d", getTeamscore(BLUETEAM));
	snprintf(geMsg.redcapture, 4, "%d", getTeamscore(REDTEAM));
	geMsg.reason=TEAMWON;

	if(getTeamscore(BLUETEAM) == getTeamscore(REDTEAM)) {
		winner=NOTEAM;
	}
	else { 
		winner = (getTeamscore(BLUETEAM) > getTeamscore(REDTEAM)) 
			? BLUETEAM : REDTEAM;
	}

#ifdef LANG_ES
	printMessage("**** Fin de la partida ****");
#else
	printMessage("**** Game Over ****");
#endif

	switch(winner) {
		case BLUETEAM:
#ifdef LANG_ES
			printMessage("Ha ganado el equipo azul");
#else
			printMessage("Blue team wins!");
#endif

			break;
		case REDTEAM:
#ifdef LANG_ES
			printMessage("Ha ganado el equipo rojo");
#else
			printMessage("Red team wins!");
#endif
			break;
		default:
#ifdef LANG_ES
			printMessage("Tenemos un empate");
#else
			printMessage("Game ended in a draw");
#endif
	}

	addTeamScore(BLUETEAM, getTeamscore(BLUETEAM), winner);
	addTeamScore(REDTEAM, getTeamscore(REDTEAM), winner);

	for(i=0; i<MAXCLIENTS; i++) {
		p=getPlayer(i);
		dead=getDeadPlayer(i);

		if(p) {
			// The client is just told if it's a winner or not, not
			// the actual winning team id.
			if(winner != NOTEAM) {
				geMsg.winner = (p->team == winner) ? 1 : 0;
			}
			else {
				geMsg.winner = NOTEAM;
			}
			addMessage(i, ENDGAMESCORE, &geMsg, sizeof(geMsg));
			addPlayerName(p->team, p->name, winner);
		}

		// Dead players are no longer connected, so we just
		// update the score board.
		if(dead) {
			addPlayerName(dead->team, dead->name, winner);
		}
	}
	endScore();
}

void runOutOfPlayers() {
	Player *dead;
	int i;

	// Update the scoreboard with the data that existed when
	// the last player carked it.
	int bscore=getTeamscore(BLUETEAM);
	int rscore=getTeamscore(REDTEAM);
	int winner;

	newScore(true);

#ifdef LANG_ES
	printMessage("**** Fin de la partida ****");
#else
	printMessage("**** Game Over ****");
#endif

	if(bscore == rscore) {
#ifdef LANG_ES
		printMessage("Tenemos un empate");
#else
		printMessage("We have a draw!");
#endif
		winner=NOTEAM;
	}
	else {
		winner = bscore > rscore ? BLUETEAM : REDTEAM;
		if(winner == BLUETEAM)
#ifdef LANG_ES
			printMessage("Ha ganado el equipo azul");
#else
			printMessage("Blue team wins!");
#endif
		else
#ifdef LANG_ES
			printMessage("Ha ganado el equipo rojo");
#else
			printMessage("Red team wins!");
#endif
	}

  addTeamScore(BLUETEAM, getTeamscore(BLUETEAM), winner);
  addTeamScore(REDTEAM, getTeamscore(REDTEAM), winner);

	for(i=0; i<MAXCLIENTS; i++) {
		dead=getDeadPlayer(i);
		if(dead)
			addPlayerName(dead->team, dead->name, winner);
	}
	endScore();
}

// Add the out of lives message. When the client acknowledges
// then the player gets taken out of the game.
void outOfLives(Player *p) {
	GameEnd geMsg;

	snprintf(geMsg.bluecapture, 4, "%d", getTeamscore(BLUETEAM));
	snprintf(geMsg.redcapture, 4, "%d", getTeamscore(REDTEAM));
	geMsg.reason=OUTOFLIVES;

	printMessage("%s ran out of lives", p->name);
	addMessage(p->clientid, ENDGAMESCORE, &geMsg, sizeof(geMsg));
	p->flags=SCORESCRN | DEAD;

}

