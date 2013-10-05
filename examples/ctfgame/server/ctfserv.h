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

#include <sys/types.h>
#include <sys/time.h>
#include "ctfmessage.h"

#ifdef UNIX
#include <netinet/in.h>
#endif

#ifdef USECURSES
#include <curses.h>
#endif

#ifdef WIN32
#include <windows.h>
#include <winsock2.h>
typedef int socklen_t;
#endif

#ifndef uchar
#define uchar  unsigned char
#endif
#ifndef bool
#define bool  unsigned char
#endif
#ifndef TRUE
#define TRUE  1
#endif
#ifndef FALSE
#define FALSE 0
#endif

#define GAMETICK  43000    // game tick length in microseconds
#define FRAMESPERSEC	1000000/GAMETICK
#define MSGBUFSZ  256      // Size of message buffers
#define MAXROWS    1024    // Maximum map rows
#define  MAXCOLS    1024
#define MAXMAPMSG  1024

#define MAXHP    100    // Max player hitpoints
#define MAXAMMO  20    // Max player ammo

#define REBOUND    8        // Push rebound factor in 1/16ths map pixel
#define MAX_PUSH  40      // Maximum push velocity fudge factor

#define STARTAMMO  10

#define PLYRTANKID  0
#define WEAPONID  1
#define XPLODEID  2
#define FLAGID    3
#define FUELID    4
#define AMMOID    5

// Structures
typedef struct _vector {
    int dir;        // 0-15, 0 = north
    int velocity;    // in 1/16ths of a map pixel
} Vector;

typedef struct _object {
    int owner;    // id of owning player
    int team;      // id of owning team
    int type;      // object's type id (maps to sprite on the client + ObjProperty)
    uchar colour;  // Object colour
    int size;      // collision size in pixels
    int prevx;    // previous X location
    int prevy;    // previous Y location
    int x;        // Map X position in 1/16ths pixel
    int y;        // Map Y position in 1/16ths pixel
    Vector commanded;  // Commanded vector (via wheels/tracks/etc)
    Vector actual;  // Actual vector of the object
    Vector push;  // How we are getting pushed
    int dirChgCount;  // Frames until direction change applied
    int damage;    // how much damage dealt on collision
    int armour;    // how much armour against collision damage
    // (0 means always destroyed on collision)
    int hp;        // Number of hitpoints remaining
    int ammo;      // Ammo remaining
    int cooldown;  // Gun cooldown time remaining in frames
    int ttl;      // Time to live in frames (-1 = forever)
    int flying;    // Object flies (can't collide with owner) for this many frames
    int destructValue;	// Value when destroyed
    uchar flags;  // various object flags
    uchar ctrls;  // What controls are being applied
    int mapColFudge;  // Map collision fudge frames
    void *extras;  // Extra attributes
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
    int initVelocity;    // Initial velocity in 1/16ths map pixels per frame
    int maxVelocity;    // Maximum velocity in 1/16ths map pixels per frame
    int maxAccel;        // Maximum acceleration, in 1/16ths map pixels per frame
    int maxBrake;        // Maximum braking in map 1/16th pixels per frame
    int turnSpeed;      // Turn speed, in frames needed per direction change
    int gunCooldown;    // Gun cooldown time in frames
    int mass;            // Object's initial mass
    int hitpoints;      // Object's initial hitpoints
    int armour;          // Object's initial armour
    int damage;          // Base damage to deal on collision
    int ttl;            // Initial TTL (-1 = forever)
    int pushdecay;      // How much the push vector decays per frame
    int velqty;          // How many units to correct per correction
    int destructValue;	// Points awarded to the destroyer
} ObjectProperties;

// Additional Object flags (see object flags in ctfmessage.h)
#define UPDATESB  0x80  // Update scorebord for object's owner
#define OBJRESET  0xF0  // Flags that won't get reset each frame

typedef struct _player {
    Object *playerobj;    // Player's tank
    char name[MAXNAME];    // Player name
    int team;              // Team number
    int score;            // Player score
    int lives;            // Player lives - start at 0 for infinite
    uchar flags;          // Player flags
    Viewport view;        // What bit of the map the player sees
    int vpcframes;        // Frames since last viewport change msg
    int spawntime;        // If dead, time until respawn in frames
    uchar playernum;    // The player number decided at the matchup screen
    int clientid;       // So we can look up the client id from a player object.
    uchar goals;        // Flags captured
} Player;

#define RUNNING     0x01  // Player's client is ready for messages
#define NEWVIEWPORT 0x02  // Player's viewport changed
#define DEAD        0x04  // Player is dead
#define MATCHMAKING 0x08  // Player is in the matchmaking screen
#define PLYRREADY		0x10	// Player is ready to start
#define SCORESCRN		0x20	// Player is looking at the score screen
#define SPECTATOR       0x40    // Player is a spectator
// note, updatesb flag is 0x80
#define RESETFLAGS  0xfd  // Bits set to 0 get reset on each frame

// Structure to implement a straightforward lookup table
// for working out new X and Y values from a direction and velocity
struct mvlookup {
    int dx;
    int dy;
};

// Player ping. The server periodically sends a 'ping' packet
// to the client if a client message hasn't been sent in a while
// to make sure the client is still alive. This structure holds
// the data of when we last pinged.
struct _ping {
    int frames;     // Frames since last ping
    int rspmiss;    // How many responses have been missed
} Ping;

#define MAXRSPMISS  4   // Maximum responses in a row that may be missed
#define PINGFRAMES  60  // How many frames between pings

// Map tile structure.
// Each tile is 8x8 map pixels. Coordinates are stored in map tile
// units.
// Note that the Y position is the row in the array.
typedef struct _maptile {
    uchar tile;            // Tile identity
    uchar flags;          // Tile flag
    uint16_t x;            // X position in tile coordinates
    struct _maptile *next;
} Maptile;

#define COLLIDABLE  0x01  // Tile can be crashed into
#define SPAWNPOINT  0x02  // Tile is a spawn point
#define ISFLAG      0x04  // Tile is a capturable flag

// Power-up spawn points
typedef struct _pwrspawn {
    int x;                // X position (1/16ths map px)
    int y;                // Y position
    int cooldown;          // How long until the object is respawn
    int type;              // object type to spawn here
} PowerSpawn;

// Player spawn point
typedef struct _plyrspawn {
    MapXY loc;
    uchar dir;		// As used in a Vector struct
} PlayerSpawn;

#define MAXPWRSPAWNS  20
#define MAXPWRCOOLDOWN    720    // 60 seconds
#define MINPWRCOOLDOWN    240    // 20 seconds
#define FUELINC        50
#define AMMOINC        10

// Spectrum compatible colour definitions
#define BLACK          0x00
#define BLUE           0x01
#define RED            0x02
#define MAGENTA        0x03
#define GREEN          0x04
#define CYAN           0x05
#define YELLOW         0x06
#define WHITE          0x07
#define BRIGHT         0x40
#define FLASH          0x80

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
void broadcastStatusMsg(char *str);

// Game message functions
int addInitGameMsg(int clientno, MapXY *xy);
int addSpriteMsg(int clientno, SpriteMsg *msm);
int addSpriteMsg16(int clientno, SpriteMsg16 *msm);
int addDestructionMsg(int clientno, RemoveSpriteMsg *rm);

// Object functions
Player *makeNewPlayer(int clientid, char *playerName, uchar flags);
void initObjList(bool firstInit);
Player *getPlayer(int clientid);
Player *getDeadPlayer(int id);
int makeSpriteMsg(int clientid, Player *player, Object *obj, uchar objid);
int makeDestructionMsg(int clientid, uchar objid, uchar reason);
void fireWeapon(Object *firer);
bool isPlayerObject(Object *obj);

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
MapXY spawnPlayer(int clientid, Player *p);
Vector addVector(Vector *v1, Vector *v2);
Object *newObject(int objtype, int owner, int x, int y);
void flagCollision(Object *lhs, Object *rhs);
void createFlags();
void placeFlag(int team, int x, int y);
void flagCaptured(Object *capturer);
int usecdiff(struct timeval *now, struct timeval *then);
void resetGame();

// Communication functions
int addMessage(int clientno, unsigned char msgid, void *msg, ssize_t msgsz);
int sendMessage(int clientno);
int addInitGameMsg(int clientno, MapXY *xy);
int addChangeViewportMsg(int clientno, int x, int y);
int addSpriteMsg(int clientno, SpriteMsg *msm);
int addDestructionMsg(int clientno, RemoveSpriteMsg *rm);
void addAmmoMsg(Object *obj);
void addHitpointMsg(Object *obj);
void broadcastTeamScoreMsg(int team);
void addTeamScoreMsg(int clientid, int team);
void updateScoreboard(Object *obj);
void updateSpectatorScoreboard();
void doPing();

// Physics functions
void processObjectControl(Object *obj, ObjectProperties *props);
void processPush(Object *obj);
void shoveObject(Object *obj, Object *with);
void dealDamage(Object *obj1, Object *obj2);
void setMaxWallCollisionDmg(int d);

// Map functions
int loadMap(const char *filename);
void processMapCmd(const char *cmd);
Maptile *buildMapRow(char *txtrow, int y);
int sendMapMsg(int clientid, Viewport *vp);
bool detectMapCollision(Object *pbj);
PlayerSpawn getSpawnpoint(Player *p);
MapXY getFlagpoint(int team);
bool detectTouchingFlagpoint(Object *obj);
int maxPlayersPerTeam();

// Powerup functions
void initPowerupList();
void addPowerup(MapXY location, int tiletype);
int getCooldown();
void updatePowerSpawns();
void spawnPowerup();
void resetPowerupSpawn(Object *pwrup);
void powerupTouched(Object *powerup, Object *with);

// Status messages
void broadcastCrash(Object *crasher);
void broadcastFlagDrop(Player *dropper);
void broadcastDeath(Object *killed, Object *killedBy);
void broadcastFlagSteal(Object *stealer);
void broadcastFlagCapture(Object *capturer);
void broadcastFlagReturn(Object *returner);
void broadcastTimeRemaining(int minutes);

void updateAllFlagIndicators();
void updateFlagIndicators(int clientid, Player *p);
void cancelFlagIndicators(int team);

void broadcastPlayerIdMsg();

// Matchmaking
void setPlayerTeam(Player *p, uchar team);
void updateAllMatchmakers();
void updateMatchmaker(int clientid);
uchar *makeMatchMakeMsgs(ssize_t *msgsz);
void sendToMatchmakers(void *mmbuf, ssize_t msgsz);
void orderTeams();
uchar isGameStartable();
void tryToStopMatchmaking();
void setMinPlayers(int p);

// Scoreboard and match end.
void addPlayerScoreMsg(int clientid);
void addLivesMsg(int clientid);
int getTeamscore(int team);
void endMatch();
void broadcastEndMatch();
void runOutOfPlayers();
void outOfLives(Player *p);

// Server scoreboard.
#ifdef USECURSES
WINDOW *mkwin(int height, int width, int starty, int startx);
#endif
void addPlayerName(int team, char *name, int winner);
void printMessage(const char *msg, ...);
void printError(const char *fmt, ...);
void newScore(bool write);
void endScore();
void addTeamScore(int team, int score, int winner);
void setupScreen();
void shutdownScoreboard();
void loadScores();

// For testing
unsigned long getframes();
void debugMsg(uchar *msg, int bytes);

// Object destruction functions
void destroyPlayerObj(Object *obj);
void awardDestructionPoints(Object *awardTo, Object *destroyed);

// Game options
void usage(char *cmd);
void setMaxLives(int l);
void setTimeLimit(int seconds);

#endif
