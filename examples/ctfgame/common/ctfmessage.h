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
#define uint16_t	u16_t
#endif

#define CTFPORT		32767

// Messages from server to client
#define	SPRITEMSG			0x01
#define RMSPRITEMSG		0x02
#define MESSAGEMSG		0x03
#define SCOREBOARD		0x04

// Client initiated messages
#define HELLO		0x40				// Initial contact with server
#define VIEWPORT	0x42			// Set viewport
#define JOIN		0x43				// Join game
#define JOINACK 0x44				// Acknowledge join
#define START		0x45				// Start game
#define STARTACK 0x46				// Acknowledge start
#define BYE			0x47				// Close connection
#define SERVERKILL	0xFF		// Testing message to halt the server when
														// the client gets an invalid msg

// Server replies to synchronous messages
#define ACK			0x41				// Acknowledgment
#define BYEACK	0x48				// Acknowledge close
#define MAPMSG	0x49				// Map data message

// Some message contents
#define	ACKOK		0x00
#define	ACKTOOMANY	0x01
#define UNABLE	0x02

// Various sizes
#define	MAXNAME	16
#define MAXOBJS	48

#ifndef uchar
#define uchar		unsigned char
#endif

typedef struct _spritemsg {
	uchar	objid;
	uchar	x;
	uchar	y;
	uchar	rotation;
	uchar	id;
	uchar colour;
} SpriteMsg;

// Sprite ID defines
#define PLAYER	0	// Player's tank
#define FOTON		1	// Photon cnnon
#define XPLODE	2	// Explosion
#define FUEL		3	// Fuel tank
#define AMMO		4	// Ammo recharge

typedef struct _rmspritemsg {
	uchar objid;
	uchar reason;
} RemoveSpriteMsg;

#define OFFSCREEN	0
#define KILLED	1

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
	uint16_t	mapx;
	uint16_t	mapy;
} MapXY;

// A message to put messages on the client's screen.
#define MAXSTATUSMSG 42
typedef struct _messageMsg {
	uchar	msgsz;	// Maximum 42 chars
	uchar message[MAXSTATUSMSG];
} MessageMsg;

// Message containing a number to put on the
// status bar of the client. The message id indicates
// which one it actually is.
typedef struct _numbermsg {
	uchar numtype;
	uchar message[5];
} NumberMsg;

#define AMMOQTY	0
#define HITPOINTQTY	1
#define REDSCORE	2
#define BLUESCORE	3
#define PLYRSCORE	4

// Control messages from the client. The controls being activated
// are specified in a bitfield. The message is very short, just the
// message id followed by a byte with the appropriate bits set.
//
// Control flags are the same as for the z88dk to save cycles on
// the client.
#define CONTROL	0x80	// Message ID
#define ROTLEFT 0x04
#define ROTRIGHT 0x08
#define ACCELERATE 0x01
#define BRAKE 0x02
#define FIRE 0x80

#endif
