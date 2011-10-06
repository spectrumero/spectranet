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

// Store information on and manipulate, collide, create and destroy
// objects in the game.
#include <stdlib.h>
#include <string.h>

#include "ctfserv.h"
#include "ctfmessage.h"

// Rotation/direction lookup table. Clockwise from north, with
// 16 steps around the circle.
struct mvlookup vectbl[] = {
	{0, -16}, {6, -15}, {11, -11}, {15, -6},
	{16, 0}, {15, 6}, {11, 11}, {6, 15},
	{0, 16}, {-6, 15}, {-11, 11}, {-15, 6},
	{-16, 0}, {-15, -6}, {-11, -11}, {-6, -15}
};

Object *objlist;
Object *objtail;
Player *players[MAXCLIENTS];

// Set all object entries to null, clear viewports etc.
void initObjList() {
	objlist=NULL;
	objtail=NULL;
	memset(players, 0, sizeof(players));
}

// Compare two viewports to see if they are the same.
bool viewPortEquals(Viewport *lhs, Viewport *rhs) {
	if(lhs->tx == rhs->tx &&
		 lhs->ty == rhs->ty &&
		 lhs->bx == rhs->bx &&
		 lhs->by == rhs->by)
		return TRUE;
	return FALSE;
}

// Add an object to the list of objects currently in the game.
void addObject(Object *obj) {
	obj->next=NULL;
	if(objlist == NULL) {
		objlist=obj;
		objtail=obj;
	} else {
		objtail->next=obj;
		objtail=obj;
	}
}

// Remove an object from the list (not: does not free the object
// from memory)
int deleteObject(Object *obj) {
	Object *cur, *prev;

	// If the only entry zero out the list.
	if(objlist == objtail) {
		objlist = NULL;
		objtail = NULL;
	} else if(objlist == obj) {
		// this is the first entry
		objlist=obj->next;
	} else {
		cur=objlist->next;
		prev=objlist;

		// this object is somewhere else in the list
		while(cur) {
			if(cur == obj) {
				prev->next=cur->next;
				if(cur == objtail)
					objtail=prev;
				break;
			}
			prev=cur;
			cur=cur->next;
		}
	}
}

// This is called before the game starts. We just initialize
// the player object and return it, where the id can be sent back
// to the client. The user on the client can then select various
// things like their team etc.
// When the game is started, the various bits of data in the 
// Player struct will be filled in, adn the player's object also
// filled in with things like initial X and Y positions and
// the object added to the object list.
// Returns a NULL pointer if a player couldn't be added.
Player *makeNewPlayer(int clientid, char *playerName) {
	int playeridx;
	Player *p;
	Object *tank;

	p=(Player *)malloc(sizeof(Player));
	tank=(Object *)malloc(sizeof(Object));
	players[clientid]=p;
	if(!p || !tank) {
		perror("makeNewPlayer: malloc");
		return NULL;
	}

	memset(p, 0, sizeof(Player));
	memset(tank, 0, sizeof(Object));
	strlcpy(p->name, playerName, MAXNAME);
	p->playerobj=tank;

	return p;
}

