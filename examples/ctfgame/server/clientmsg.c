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

// Handle messages from the client.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ctfmessage.h"
#include "ctfserv.h"

void processControlInput(int clientid, uchar msg) {
	Object *po=getPlayer(clientid)->playerobj;

	// The message pointer is at the actual control byte.
	if(msg & ROTLEFT)
		po->dir--;
	if(msg & ROTRIGHT)
		po->dir++;
	if(msg & ACCEL)
		po->velocity++;
	if(msg & BRAKE)
		po->velocity--;

	if(po->velocity < 0)
		po->velocity=0;

	// TEST CODE
	if(po->velocity > 2)
		po->velocity=2;

	// direction can only be 0-15
	po->dir &= 0x0F;
}

