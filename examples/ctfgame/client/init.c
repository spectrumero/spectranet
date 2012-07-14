/*
;The MIT License
;
;Copyright (c) 2011 Dylan Smith
;
;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:
;
;The above copyright notice and this permission notice shall be included in
;all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;THE SOFTWARE.
*/
#pragma output STACKPTR = 53248
#include <malloc.h>
#include <spectrum.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include "ctf.h"
#include "ctfmessage.h"

// Define the things we need for malloc
long heap;

// Used by the splib
void *u_malloc(uint size) {
	return malloc(size);
}

void u_free(void *addr) {
	free(addr);
}

// Program is started here.
main() {
	int rc;
	MapXY xy;
	SpriteMsg msg;
	int i;
	initConnection(wpeek(27000), (struct sockaddr_in *)27002);

#asm
	di
#endasm

	initInput();
	// initialize malloc.lib
	heap = 0L;
//	sbrk(48736,3999);
	sbrk(24000,8767);

	// Page in the Spectranet permanently
#asm
	call 0x3FF9
#endasm

	initSpriteLib();

	setupStatusAreas(PAPER_BLUE|INK_CYAN);
	rc=startGame(&xy);
	rc=findViewport(&xy);
	rc=messageloop();
	rc=disconnect(FALSE);

#asm
	call 0x007C
	ei
#endasm
}
