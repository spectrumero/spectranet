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
#include <stdio.h>
#include <string.h>
#include <math.h>

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

// Object property table. This could be loaded from a file instead.
ObjectProperties objprops[] = {
	{0, 40, 4, 4, 3, 18, 100, 100, 1, 20, -1, 1, 1},		// Player's tank
	{100, 320, 0, 0, 0, 0, 10, 1, 0, 100, 20, 3, 1}		// Player's missile
};

int acostbl[]={4, 4, 3, 3, 2, 2, 1, 0};
int acostbl2[]={0, 1, 2, 2, 3, 3, 4, 4};

// Master object list
// While a linked list would be more memory efficient (and
// not have a hard limit), the array position makes for
// a simple 8 bit object id which the client can very
// rapidly look up (in other words, it makes the code much
// simpler)
Object *objlist[MAXOBJS];

// Player list
Player *players[MAXCLIENTS];

// Frame counter. This is mainly used for testing and
// debugging.
unsigned long frames;
unsigned long testend;

// Set all object entries to null, clear viewports etc.
void initObjList() {
	memset(objlist, 0, sizeof(objlist));
	memset(players, 0, sizeof(players));
	frames=0;
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
	int i;
	for(i=0; i < MAXOBJS; i++) {
		if(objlist[i] == NULL) {
			objlist[i]=obj;
			return;
		}
	}
	fprintf(stderr, "addObject: Object list is full!\n");
}

// Remove an object from the list (not: does not free the object
// from memory)
int deleteObject(Object *obj) {
	int i;
	for(i=0; i < MAXOBJS; i++) {
		if(objlist[i] == obj) {
			objlist[i]=NULL;
			return;
		}
	}
	fprintf(stderr, "deleteObject: object not found\n");
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

	p=(Player *)malloc(sizeof(Player));
	players[clientid]=p;
	if(!p) {
		perror("makeNewPlayer: malloc");
		return NULL;
	}

	memset(p, 0, sizeof(Player));
	strlcpy(p->name, playerName, MAXNAME);

	return p;
}

void removePlayer(int clientid) {
	int i;
	Object *obj;

	for(i = 0; i < MAXOBJS; i++) {
		obj=objlist[i];
		if(obj && obj->owner == clientid) {
			obj->flags = VANISHED;
			obj->owner = -1;
		}
	}
	
	free(players[clientid]);
	players[clientid]=NULL;
}

// startPlayer creates the initial starting spot for a player
// and the start message.
void startPlayer(int clientid) {
	MapXY spawn;
	Player *player=players[clientid];
	fprintf(stderr, "startPlayer for client %d\n", clientid);
	spawnPlayer(clientid, player);

	// Tell the client to initialize. The client will use the MapXY
	// to figure out where the viewport should be. The client will
	// then respond by telling the server the viewport.
	addInitGameMsg(clientid, &spawn);
	sendMessage(clientid);
}

// Spawn a player
void spawnPlayer(int clientid, Player *p) {
	MapXY spawn;
	Object *po=(Object *)malloc(sizeof(Object));
	memset(po, 0, sizeof(Object));

	// TODO: something real
	spawn.mapx=100;
	spawn.mapy=100;
	po->x=spawn.mapx*16;
	po->y=spawn.mapy*16;
	po->ttl=-1;
	po->ammo=STARTAMMO;
	po->owner=clientid;
	po->destructFunc=destroyPlayerObj;
	po->type=PLAYER;
	po->armour=objprops[PLAYER].armour;
	po->hp=objprops[PLAYER].hitpoints;
	po->damage=objprops[PLAYER].damage;

	addObject(po);
	p->playerobj=po;
	p->vpcframes=0;
}

// Get a player by id.
Player *getPlayer(int clientid) {
	return players[clientid];
}

// Send all the updates that should be sent to each client.
void makeUpdates() {
	int clientid;
	Player *p;

	doObjectUpdates();

	for(clientid=0; clientid < MAXCLIENTS; clientid++) {
		p=players[clientid];
		if(p) {
			makeSpriteUpdates(clientid);

			// Player updates finished, reset flags that should be
			// reset at the end of the frame.
			p->flags &= RESETFLAGS;
		}
	}

	sendClientMessages();
	cleanObjects();
	frames++;
}

// Perform updates on objects, move them, collide them, blow them up
// etc.
void doObjectUpdates() {
	int i;
	Object *obj;

	for(i=0; i<MAXOBJS; i++) {
		obj=objlist[i];
		if(obj) {
			if(obj->ttl == 0) {
				obj->flags |= DESTROYED;
				continue;
			}

			if(obj->flying)
				obj->flying--;

			processObjectControl(obj, &objprops[obj->type]);
			processPush(obj);
			if(obj->actual.velocity != 0)
				moveObject(obj);
			if(obj->cooldown > 0)
				obj->cooldown--;
			if(obj->ttl > 0)
				obj->ttl--;
		}
	}
	collisionDetect();

	// Check destruction flags, and run any destruction functions
	for(i=0; i<MAXOBJS; i++) {
		obj=objlist[i];
		if(obj && (obj->flags & DESTROYED) && obj->destructFunc)
			obj->destructFunc(obj);
	}
}

// processPush adds the push vector to create the actual.
void processPush(Object *obj) {
	obj->actual=addVector(&obj->commanded, &obj->push);
	if(obj->push.velocity != 0)
		obj->push.velocity -= objprops[obj->type].pushdecay;
}

// This function updates the XY position of the object, and its former
// XY position.
void moveObject(Object *obj) {
	int dx=vectbl[obj->actual.dir].dx;
	int dy=vectbl[obj->actual.dir].dy;
	
	int abspx, abspy, absx, absy;

	dx *= (obj->actual.velocity >> 4);
	dy *= (obj->actual.velocity >> 4);

	obj->prevx=obj->x;
	obj->prevy=obj->y;
	obj->x += dx;
	obj->y += dy;

	absx=obj->x >> 4;
	absy=obj->y >> 4;
	abspx=obj->prevx >> 4;
	abspy=obj->prevy >> 4;

	if(obj->x < 0) {
		obj->x = 0;
		obj->actual.velocity = 0;
	}
	if(obj->y < 0) {
		obj->y = 0;
		obj->actual.velocity = 0;
	}

	// Only set the move flag if the object has moved across a map
	// pixel boundary.
	if(absx != abspx || absy != abspy) {	
		//printf("Moving object: x = %d y = %d prevx = %d prevy = %d\n",
			//obj->x >> 4, obj->y >> 4, obj->prevx >> 4, obj->prevy >> 4);
		obj->flags |= HASMOVED;
	}

	// TEST CODE
//	if(frames >= testend)
//		obj->velocity=0;
}

// Make the sprite messages to update each player's display.
void makeSpriteUpdates(int clientid) {
	int objid;
	Object *obj;
	Player *player=players[clientid];

	if(player->vpcframes)
		player->vpcframes--;

	// First check for viewport changes. If the player's object
	// was moved out of view when we moved stuff around, then just
	// send a change viewport message.
	if(player->playerobj && !objIsInView(player->playerobj, &player->view)) {
		// vpcframes is just to stop us sending multiple viewport changes
		// since the client is quite slow at processing them.
		if(player->vpcframes == 0) {
			addChangeViewportMsg(clientid, 
					player->playerobj->x >> 4,
					player->playerobj->y >> 4);
			player->vpcframes = 5;
		}
		return;
	}

	for(objid=0; objid < MAXOBJS; objid++) {
		obj=objlist[objid];

		// We'll send a message if the object is within the player's viewport,
		// but only if the object moved or was destroyed or left the viewport.
		if(obj != NULL) {
			if(objIsInView(obj, &player->view)) {
				if(obj->flags & DESTROYED) {
					makeDestructionMsg(clientid, objid, KILLED);
				}
				else { // if((obj->flags & HASMOVED) || (player->flags & NEWVIEWPORT)) {
					makeSpriteMsg(clientid, &player->view, obj, objid);
				}
			}
			else if(objWasInView(obj, &player->view)) {
				makeDestructionMsg(clientid, objid, OFFSCREEN);
			}
		}
	}
}

int makeSpriteMsg(int clientid, Viewport *view, Object *obj, uchar objid) {
	SpriteMsg sm;

	//printf("Adding spritemessage\n");

	sm.x=(obj->x >> 4) - view->tx;
	sm.y=(obj->y >> 4) - view->ty;
	sm.objid=objid;
	sm.rotation=obj->commanded.dir;
	sm.id=obj->type;
	return addSpriteMsg(clientid, &sm);
}

int makeDestructionMsg(int clientid, uchar objid, uchar reason) {
	RemoveSpriteMsg rm;

	rm.objid=objid;
	rm.reason=reason;
	return addDestructionMsg(clientid, &rm);
}

bool objIsInView(Object *obj, Viewport *view) {
	// Remove the least significant 4 bits which are fractions of
	// a map position.
	int ox=obj->x >> 4;
	int oy=obj->y >> 4;

	if(ox >= view->tx && ox <= view->bx &&
			oy >= view->ty && oy <= view->by)
		return TRUE;
	return FALSE;
}

bool objWasInView(Object *obj, Viewport *view) {
	// Remove the least significant 4 bits which are fractions of
	// a map position.
	int ox=obj->prevx >> 4;
	int oy=obj->prevy >> 4;

	if(ox >= view->tx && ox <= view->bx &&
			oy >= view->ty && oy <= view->by)
		return TRUE;
	return FALSE;
}

// This is called at the end of the game update after
// all the clients have had their update messages sent.
void cleanObjects() {
	int i;
	Object *obj;
	for(i=0; i<MAXOBJS; i++) {
		obj=objlist[i];
		if(obj) {
			if(obj->flags & (VANISHED | DESTROYED)) {

				// if it's the player's tank that was destroyed
				// respawn the player, but only for DESTROYED (the
				// VANISHED flag meant the player went away)
				if(players[obj->owner]->playerobj == obj && obj->flags & DESTROYED) {
					spawnPlayer(obj->owner, players[obj->owner]);
				}
				objlist[i]=NULL;
				free(obj);
			}
			else {
				obj->flags &= OBJRESET;
			}
		}
	}
}

unsigned long getframes() {
	return frames;
}

// Optimization note. Keep a list of valid indexes to reduce the amount
// of iterations.
void collisionDetect() {
	int i, j;
	Object *obj;

	// First check the map
	for(i=0; i<MAXOBJS; i++) {
		if(objlist[i] && !(objlist[i]->flags & NOCOLLIDE) &&
				detectMapCollision(objlist[i])) {
			obj=objlist[i];
			printf("%ld: Map collision: Object %d\n", frames, i);

			// Destroy it immediately and stop it from moving.
			obj->flags |= DESTROYED;
			obj->actual.velocity = 0;
		}
	}

	for(i=0; i<MAXOBJS-1; i++) {
		for(j=i+1; j<MAXOBJS; j++) {
			if(!objlist[i])
				break;
			if(objlist[j] && collidesWith(objlist[i], objlist[j])) {
				printf("%ld: Collision! Object %d with object %d\n", frames, i, j);
				shoveObject(objlist[i], objlist[j]);
				dealDamage(objlist[i], objlist[j]);
			}
		}
	}
}

// Very very simple collision detection.
// This will ultimately be replaced with doing the separating axis
// theorem on bounding boxes but for now we'll just see if a square
// 16 pixels on each side interesects.
bool collidesWith(Object *lhs, Object *rhs) {

	// If an object is "flying" it will miss its owner.
	if(lhs->owner == rhs->owner) {
		if(lhs->flying)
			return FALSE;
		if(rhs->flying)
			return FALSE;
	}

	// note: X and Y in 16ths of map pixels so the basic sprite is
	// 256 units by 256 units.
	if(abs(lhs->x - rhs->x) < 256 &&
		 abs(lhs->y - rhs->y) < 256)
		return TRUE;
	return FALSE;
}

// Have an object shoot something.
void fireWeapon(Object *firer) {
	ObjectProperties op;
	Object *missile;
	if(firer->cooldown != 0 || firer->ammo == 0)
		return;

	op=objprops[WEAPONID];
	missile=(Object *)malloc(sizeof(Object));	
	memset(missile, 0, sizeof(Object));
	addObject(missile);

	missile->owner=firer->owner;
	missile->type=WEAPONID;
	missile->commanded.dir=firer->commanded.dir;
	missile->actual.dir=missile->commanded.dir;
	missile->actual.velocity=firer->actual.velocity+op.initVelocity;
	missile->commanded.velocity=missile->actual.velocity;
	missile->x=firer->x;
	missile->y=firer->y;
	missile->flags |= NEWOBJ;
	missile->hp = op.hitpoints;
	missile->armour = op.armour;
	missile->damage = op.damage;
	missile->ttl = op.ttl;
	missile->flying = 5;

	printf("Missile dir: %d Velocity %d\n", missile->actual.dir, missile->actual.velocity);
	printf("Object dir: %d Velocity %d\n", firer->actual.dir, firer->actual.velocity);

	firer->ammo--;
	firer->cooldown=objprops[firer->type].gunCooldown;
}

// Shove an object when collided with. We're not trying to be super
// accurate here, just to add an interesting game mechanic.
void shoveObject(Object *obj, Object *with) {
	Vector rel=with->actual;
	Vector cvec;
	Vector withvec;
	Vector objvec;

	// reverse the direction, to make the with object as if it
	// were stationary compared to the obj
	rel.dir += 8;
	rel.dir &= 0x0f;
	cvec=addVector(&obj->actual, &rel);
	cvec.velocity += REBOUND;

	// Fudge factor to prevent ridiculous velocities if a fast collision
	// causes objects to overlap
	if(cvec.velocity > MAX_PUSH)
		cvec.velocity = MAX_PUSH;

	with->push=cvec;

	cvec.dir+=8;
	cvec.dir&=0x0f;
	obj->push=cvec;
}

// Deal damage when objects have collided.
void dealDamage(Object *obj1, Object *obj2) {
	obj1->hp -= objprops[obj2->type].damage;
	obj2->hp -= objprops[obj1->type].damage;

	// If the armour value is 0, the object is instagibbed.
	// However, it will still do damage to what it hits. (Ammo has a
	// zero value here so missiles die as soon as they hit, but still
	// deal damage to what they hit)
	if(obj1->armour == 0 || obj1->hp < 1)
		obj1->flags |= (DESTROYED|EXPLODING);
	if(obj2->armour == 0 || obj2->hp < 1)
		obj2->flags |= (DESTROYED|EXPLODING);

}

// Add two vectors
// Needs some work...
Vector addVector(Vector *v1, Vector *v2) {
  Vector result;
  int dx, dy;
  double hyp;
  int tblentry;
  int dir;

  // remove the cases where one vector has a zero velocity component
  if(v1->velocity == 0) {
    result.dir=v2->dir;
    result.velocity=v2->velocity;
    return result;
  }

  if(v2->velocity == 0) {
    result.dir=v1->dir;
    result.velocity=v1->velocity;
    return result;
  }

  int dx1=vectbl[v1->dir].dx;
  int dy1=vectbl[v1->dir].dy;
  int dx2=vectbl[v2->dir].dx;
  int dy2=vectbl[v2->dir].dy;

  dx1 *= (v1->velocity >> 4);
  dy1 *= (v1->velocity >> 4);
  dx2 *= (v2->velocity >> 4);
  dy2 *= (v2->velocity >> 4);

  // Find out the total displacement given by the two vectors
  dx=dx1 + dx2;
  dy=dy1 + dy2;
  printf("dx = %d dy = %d\n", dx, dy);
  if(dx == 0 && dy == 0) {
    result.dir=0;
    result.velocity=0;
    return result;
  }

  // Find out the hypoteneuse
  hyp=sqrt(abs(dx * dx) + abs(dy * dy));
  tblentry = abs(rint((dy / hyp) * 7));

  if(dx >= 0 && dy <= 0)
    dir = acostbl[tblentry];
  else if(dx >= 0 && dy >= 0)
    dir = acostbl2[tblentry]+3;
  else if(dx <= 0 && dy >= 0)
    dir = acostbl[tblentry]+7;
  else
    dir = acostbl2[tblentry]+11;

  printf("hyp = %f tblentry = %d dir = %d\n", hyp, tblentry, dir);

  result.dir=dir;
  result.velocity=hyp;

  return result;
}

// OBJECT DESTROYED FUNCTIONS
// Destruction of player object.
void destroyPlayerObj(Object *obj) {

	// Turn the player into an explosion with a TTL of 15 frames
	obj->flags=NOCOLLIDE|EXPLODING;
	obj->type=XPLODE;
	obj->ttl=15;
	obj->destructFunc=NULL;
}

