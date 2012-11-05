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

#ifdef LANG_ES
#define STR_BLUE "azul"
#define STR_RED "roja"
#else
#define STR_BLUE "blue"
#define STR_RED "red"
#endif

// Broadcast messages
void broadcastCrash(Object *crasher) {
  Player *p=getPlayer(crasher->owner);
  if(crasher->flags & HASFLAG) {
    broadcastFlagDrop(p);
    return;
  }
#ifdef LANG_ES
  snprintf(bcast, MAXSTATUSMSG, "%s ha chocado y ha muerto.", p->name);
#else
  snprintf(bcast, MAXSTATUSMSG, "%s crashed and died.", p->name);
#endif
  broadcastStatusMsg(bcast);
}

void broadcastFlagDrop(Player *dropper) {
  char colour[5];
  if(dropper->team == 0) 
    strcpy(colour, STR_RED);
  else
    strcpy(colour, STR_BLUE);

#ifdef LANG_ES
  snprintf(bcast, MAXSTATUSMSG, "%s ha perdido la bandera %s", dropper->name, colour);
#else
  snprintf(bcast, MAXSTATUSMSG, "%s dropped the %s flag", dropper->name, colour);
#endif

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
#ifdef LANG_ES
    snprintf(bcast, MAXSTATUSMSG,
        "%s ha atropellado a %s", killer->name, p->name);
#else
    snprintf(bcast, MAXSTATUSMSG,
        "%s was run over by %s", p->name, killer->name);
#endif
    broadcastStatusMsg(bcast);
  } 
  else if(killer != NULL && killedBy->type == FOTON) {
#ifdef LANG_ES
    snprintf(bcast, MAXSTATUSMSG,
        "%s ha abatido a %s", killer->name, p->name);
#else
    snprintf(bcast, MAXSTATUSMSG,
        "%s was shot by %s", p->name, killer->name);
#endif
    broadcastStatusMsg(bcast);
  }
}

// Broadcast the flag steal
void broadcastFlagSteal(Object *stealer) {
  Player *p=getPlayer(stealer->owner);
  char colour[5];
  if(stealer->team == 0) 
    strcpy(colour, STR_RED);
  else
    strcpy(colour, STR_BLUE);

#ifdef LANG_ES
  snprintf(bcast, MAXSTATUSMSG, "¡%s tiene la bandera %s!",
      p->name, colour);
#else
  snprintf(bcast, MAXSTATUSMSG, "%s has taken the %s flag!",
      p->name, colour);
#endif

  broadcastStatusMsg(bcast);
}

// Broadcast the flag capture
void broadcastFlagCapture(Object *capturer) {
  Player *p=getPlayer(capturer->owner);
  char colour[5];
  if(capturer->team == 0) 
    strcpy(colour, STR_RED);
  else
    strcpy(colour, STR_BLUE);

#ifdef LANG_ES
  snprintf(bcast, MAXSTATUSMSG, "¡%s ha capturado la bandera %s!",
      p->name, colour);
#else
  snprintf(bcast, MAXSTATUSMSG, "%s has captured the %s flag!",
      p->name, colour);
#endif
  broadcastStatusMsg(bcast);
}

// Broadcast the flag return
void broadcastFlagReturn(Object *returner) {
  Player *p=getPlayer(returner->owner);
  char colour[5];
  if(returner->team == 0) 
    strcpy(colour, STR_BLUE);
  else
    strcpy(colour, STR_RED);

#ifdef LANG_ES
  snprintf(bcast, MAXSTATUSMSG, "%s ha rescatado la bandera %s.",
      p->name, colour);
#else
  snprintf(bcast, MAXSTATUSMSG, "%s has returned the %s flag.",
      p->name, colour);
#endif
  broadcastStatusMsg(bcast);
}

// Broadcast time remaining 
void broadcastTimeRemaining(int minutes) {
	if(minutes > 1) {
#ifdef LANG_ES
		snprintf(bcast, MAXSTATUSMSG, "Quedan %d minutos...",
				minutes);
#else
		snprintf(bcast, MAXSTATUSMSG, "%d minutes remaining...",
				minutes);
#endif
	}
	else {
#ifdef LANG_ES
		snprintf(bcast, MAXSTATUSMSG, "¡Corre! Queda muy poco tiempo");
#else
		snprintf(bcast, MAXSTATUSMSG, "Hurry! Time's running out!");
#endif
	}
	broadcastStatusMsg(bcast);
}

