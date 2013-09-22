#ifndef MESSAGE_H
#define MESSAGE_H
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

#include <sys/types.h>
#ifndef NOSTDINT
#include <stdint.h>
#endif

// u16_t is a z88dk type
#ifdef NOSTDINT
#define uint16_t  u16_t
#endif

#define CTFPORT    32767

// Messages from server to client
#define SPRITEMSG               0x01
#define RMSPRITEMSG             0x02
#define MESSAGEMSG              0x03
#define SCOREBOARD              0x04
#define FLAGALERT               0x05
#define MATCHMAKEMSG            0x06
#define PINGMSG                 0x07
#define CLRPLAYERLIST						0x08	// Clear player list
#define MMSTARTABLE							0x09	// Match is or is not startable
#define MMEXIT									0x0A	// Client should exit matchmaking
#define ENDGAMESCORE						0x0B	// End game and show scores
#define SPRITEMSG16             0x0C    // 16 bit sprite msg
#define PLAYERIDMSG             0x0D    // Player id for spectators

// Client initiated messages
#define HELLO    0x40        // Initial contact with server
#define SPECHELLO 0x41      // Spectator initial contact
#define VIEWPORT 0x42      // Set viewport
#define JOIN     0x43        // Join game
#define JOINACK  0x44        // Acknowledge join
#define START    0x45        // Start game
#define STARTACK 0x46        // Acknowledge start
#define BYE      0x47        // Close connection
#define CLIENTRDY  0x48      // Client message loop is started
#define TEAMREQUEST 0x49    // Request a team for a player
#define MMSTART   0x4A      // Start matchmaking
#define MMSTOP    0x4B      // Stop matchmaking
#define MMREADY 	0x4C			// Player is ready to start
#define SERVERKILL 0xFF    // Testing message to halt the server when
// the client gets an invalid msg

// Server replies to synchronous messages
#define ACK     0x41        // Acknowledgment
#define BYEACK  0x48        // Acknowledge close
#define MAPMSG  0x49        // Map data message

// Some message contents
#define  ACKOK      0x00
#define  ACKTOOMANY 0x01
#define UNABLE      0x02

// Various sizes
#define  MAXNAME  16
#define MAXOBJS  48
#define MAXCLIENTS  16

#ifndef uchar
#define uchar    unsigned char
#endif

// Viewport size
#define VPXPIXELS 224
#define VPYPIXELS 184

typedef struct _spritemsg {
    uchar  objid;
    uchar  x;
    uchar  y;
    uchar  rotation;
    uchar  id;
    uchar colour;
} SpriteMsg;

typedef struct _spritemsg16 {
    uchar   objid;
    uchar   ownerid;
    unsigned short x;
    unsigned short y;
    uchar   rotation;
    uchar   id;
    uchar   colour;
} SpriteMsg16;

typedef struct _playeridmsg {
    uchar   ownerid;
    uchar   ownername[MAXNAME];
} PlayerIdMsg;

// Sprite ID defines
#define PLAYER  0  // Player's tank
#define FOTON    1  // Photon cnnon
#define XPLODE  2  // Explosion
#define FLAG    3
#define FUEL    4  // Fuel tank
#define AMMO    5  // Ammo recharge

typedef struct _rmspritemsg {
    uchar objid;
    uchar reason;
} RemoveSpriteMsg;

#define OFFSCREEN  0
#define KILLED  1

typedef struct _maptilemsg {
    uchar tile;
    uchar x;
    uchar y;
} MaptileMsg;

// The viewport defines the portion of a map a player can
// see. The X and Y values are absolute map pixels.
typedef struct _viewport {
    uint16_t tx;   // top left X pixel
    uint16_t ty;   // top left Y pixel
    uint16_t bx;   // bottom right X pixel
    uint16_t by;   // bottom right Y pixel
} Viewport;

// MapXY defines a message with an absolute map XY
typedef struct _mapxy {
    uint16_t  mapx;
    uint16_t  mapy;
} MapXY;

// A message to put messages on the client's screen.
#define MAXSTATUSMSG 42
typedef struct _messageMsg {
    uchar  msgsz;  // Maximum 42 chars
    uchar message[MAXSTATUSMSG];
} MessageMsg;

// Message containing a number to put on the
// status bar of the client. The message id indicates
// which one it actually is.
typedef struct _numbermsg {
    uchar numtype;
    uchar message[5];
} NumberMsg;

#define AMMOQTY  0
#define HITPOINTQTY  1
#define BLUESCORE  2
#define REDSCORE  3
#define PLYRSCORE  4
#define LIVES	5

// Matchmaking message
// Team is 0 or 1, or 0xFF for "not in a team yet"
typedef struct _matchmake {
    uchar team;
    uchar playernum;	// in this context, means player within team
    uchar flags;
    char playername[MAXNAME];
} MatchmakeMsg;

// Match making instruction
typedef struct _matchmakeinst {
    uchar team;
    uchar playernum;
    uchar flags;
} MatchmakeInst;

#define MM_READY  1   // Player is ready  
#define MM_JOINTEAM	2	// Player wants to join this team

// Game end data message
typedef struct _gameend {
    uchar reason;
    uchar winner;		// Set if the receiving player is a winner
    char bluecapture[4];
    char redcapture[4];
} GameEnd;

// Reasons for the game end
#define TEAMWON	0
#define OUTOFLIVES	1

// Dead player message
typedef struct _playersummary {
    uint16_t score;
    uchar captures;
} PlayerSummary;

// Control messages from the client. The controls being activated
// are specified in a bitfield. The message is very short, just the
// message id followed by a byte with the appropriate bits set.
//
// Control flags are the same as for the z88dk to save cycles on
// the client.
#define CONTROL  0x80  // Message ID
#define ROTLEFT 0x04
#define ROTRIGHT 0x08
#define ACCELERATE 0x01
#define BRAKE 0x02
#define FIRE 0x80

// Team numbers
#define BLUETEAM	0
#define REDTEAM		1
#define NOTEAM		2

#endif
