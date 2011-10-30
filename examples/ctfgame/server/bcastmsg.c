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

#include <string.h>
#include <stdio.h>

#include "ctfserv.h"
#include "ctfmessage.h"

char bcast[MAXSTATUSMSG];

// Broadcast messages
void broadcastCrash(Object *crasher) {
	Player *p=getPlayer(crasher->owner);
	if(crasher->flags & HASFLAG) {
		broadcastFlagDrop(p);
		return;
	}

	snprintf(bcast, MAXSTATUSMSG, "%s crashed and died.", p->name);
	broadcastStatusMsg(bcast);
}

void broadcastFlagDrop(Player *dropper) {
	char colour[5];
	if(dropper->team == 0) 
		strcpy(colour, "red");
	else
		strcpy(colour, "blue");

	snprintf(bcast, MAXSTATUSMSG, "%s dropped the %s flag", dropper->name, colour);
	broadcastStatusMsg(bcast);
}

// This tries to ascertain the reason for death and send the appropriate
// message. 'killed' should be a player object.
void broadcastDeath(Object *killed, Object *killedBy) {
	Player *killer=NULL;
	Player *p=getPlayer(killed->owner);

	if(killed->flags & HASFLAG) {
		broadcastFlagDrop(p);
		return;
	}

	if(killedBy->owner >= 0)
		killer=getPlayer(killedBy->owner);

	if(isPlayerObject(killedBy)) {
		snprintf(bcast, MAXSTATUSMSG,
				"%s was run over by %s", p->name, killer->name);
		broadcastStatusMsg(bcast);
	} 
	else if(killer != NULL && killedBy->type == FOTON) {
		snprintf(bcast, MAXSTATUSMSG,
				"%s was shot by %s", p->name, killer->name);
		broadcastStatusMsg(bcast);
	}
}

