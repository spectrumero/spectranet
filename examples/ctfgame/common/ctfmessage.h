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

#define CTFPORT		32767
#define MAKESPRITE	0x00
#define	MOVESPRITE	0x01

#define HELLO		0x40
#define ACK			0x41
#define	ACKOK		0x00
#define	ACKTOOMANY	0x01


#ifndef uchar
#define uchar		unsigned char
#endif

typedef struct _mksprite {
	uchar	objid;
	uchar	x;
	uchar	y;
	uchar	rotation;
	uchar	id;
} MakeSpriteMsg;

typedef struct _mvsprite {
	uchar	objid;
	uchar	x;
	uchar	y;
	uchar	rotation;
} MoveSpriteMsg;

// Control messages from the client. The controls being activated
// are specified in a bitfield. The message is very short, just the
// message id followed by a byte with the appropriate bits set.
#define CONTROL	0x80	// Message ID
#define ROTLEFT 0x01
#define ROTRIGHT 0x02
#define ACCEL 0x04
#define BRAKE 0x08
#define FIRE 0x10

#endif
