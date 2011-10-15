#ifndef CTFSERV_H
#define CTFSERV_H
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
//

#include <netinet/in.h>
#include <sys/types.h>
#include "ctfmessage.h"

#ifndef uchar
#define uchar	unsigned char
#endif
#ifndef bool
#define bool	unsigned char
#endif
#ifndef TRUE
#define TRUE	1
#endif
#ifndef FALSE
#define FALSE 0
#endif

#define GAMETICK	40000		// game tick length in microseconds
#define MAXCLIENTS	16
#define MSGBUFSZ	256			// Size of message buffers
#define MAXROWS		1024		// Maximum map rows
#define	MAXCOLS		1024
#define MAXMAPMSG	1024

// Structures
typedef struct _object {
	int owner;		// id of owning player
	int type;			// object's type id (maps to sprite on the client + ObjProperty)
	int size;			// collision size in pixels
	int prevx;		// previous X location
	int prevy;		// previous Y location
	int x;				// Map X position in 1/16ths pixel
	int y;				// Map Y position in 1/16ths pixel
	int dir;			// direction in 16 points around the compass
	int dirChgCount;	// Frames until direction change applied
	int velocity;	// velocity in 1/16th pixels per frame
	int damage;		// how much damage dealt on collision
	int armour;		// how much armour against collision damage
								// (0 means always destroyed on collision)
	int hp;				// Number of hitpoints remaining
	uchar flags;	// various object flags
	uchar ctrls;	// What controls are being applied
	// This member is a pointer to a function that should get called
	// on collision detection. Set to null for no action, otherwise
	// the function pointer contained here will be called.
	void (*collisionFunc)(struct _object *optr, struct _object *with);
	
	// This member specifies a function that will be called when
	// the object is destroyed in addition to the usual actions (removal
	// from object lists etc). If it's set to null, just the default
	// actions will be done.
	void (*destructFunc)(struct _object *optr);
} Object;

typedef struct _objprops {
	int initVelocity;		// Initial velocity in 1/16ths map pixels per frame
	int maxVelocity;		// Maximum velocity in 1/16ths map pixels per frame
	int maxAccel;				// Maximum acceleration, in 1/16ths map pixels per frame
	int maxBrake;				// Maximum braking in map 1/16th pixels per frame
	int turnSpeed;			// Turn speed, in frames needed per direction change
} ObjectProperties;

// Object flags
#define HASMOVED	0x01	// Object has moved since the last frame
#define NEWOBJ		0x02	// Object was created this frame
#define DESTROYED	0x04	// Object was destroyed this frame
#define VANISHED	0x08	// Object was destroyed because the owner disappeared

typedef struct _player {
	Object *playerobj;		// Player's tank
	char name[MAXNAME];		// Player name
	int team;							// Team number
	int score;						// Player score
	int lives;						// Player lives - start at 0 for infinite
	uchar flags;					// Player flags
	Viewport view;				// What bit of the map the player sees
} Player;

#define HASFLAG		0x01	// Player is carrying the flag
#define NEWVIEWPORT 0x02	// Player's viewport changed
#define RESETFLAGS	0x01	// Bits set to 0 get reset on each frame

// Structure to implement a straightforward lookup table
// for working out new X and Y values from a direction and velocity
struct mvlookup {
	int dx;
	int dy;
};

// Map tile structure.
// Each tile is 8x8 map pixels. Coordinates are stored in map tile
// units.
// Note that the Y position is the row in the array.
typedef struct _maptile {
	uchar tile;						// Tile identity
	uchar flags;					// Tile flag
	uint16_t x;						// X position in tile coordinates
	struct _maptile *next;
} Maptile;

#define COLLIDABLE	0x01	// Tile can be crashed into
#define SPAWNPOINT	0x02	// Tile is a spawn point
#define ISFLAG			0x04	// Tile is a capturable flag

// Function prototypes
// Socket handling functions
int makeSocket();
int messageLoop();
int getMessage();
void removeClient(int clientno);
void removePlayer(int clientno);
int findClient(struct sockaddr_in *client);
int sendMessage(int clientno);
int sendMessageBuf(int clientno, char *buf, ssize_t bufsz);

// Game message functions
int addInitGameMsg(int clientno, MapXY *xy);
int addSpriteMsg(int clientno, SpriteMsg *msm);
int addDestructionMsg(int clientno, RemoveSpriteMsg *rm);

// Object functions
void initObjList();
Player *getPlayer(int clientid);
int makeSpriteMsg(int clientid, Viewport *view, Object *obj, uchar objid);
int makeDestructionMsg(int clientid, uchar objid, uchar reason);

// Game loop functions
void doObjectUpdates();
void moveObject(Object *obj);
void makeUpdates();
void makeSpriteUpdates(int clientid);
bool objIsInView(Object *obj, Viewport *view);
bool objWasInView(Object *obj, Viewport *view);
void cleanObjects();
void collisionDetect();
bool collidesWith(Object *lhs, Object *rhs);
void spawnPlayer(Player *p);

// Communication functions
int addMessage(int clientno, unsigned char msgid, void *msg, ssize_t msgsz);
int sendMessage(int clientno);
int addInitGameMsg(int clientno, MapXY *xy);
int addChangeViewportMsg(int clientno, int x, int y);
int addSpriteMsg(int clientno, SpriteMsg *msm);
int addDestructionMsg(int clientno, RemoveSpriteMsg *rm);

// Physics functions
void processObjectControl(Object *obj, ObjectProperties *props);

// Map functions
int loadMap(const char *filename);
Maptile *buildMapRow(char *txtrow);
int sendMapMsg(int clientid, Viewport *vp);
bool detectMapCollision(Object *pbj);

// For testing
unsigned long getframes();
void debugMsg(uchar *msg, int bytes);

#endif
