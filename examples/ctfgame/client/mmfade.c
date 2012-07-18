// The MIT License
// 
// Copyright (c) 2012 Dylan Smith
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
#include <stdlib.h>

#define ATTRSTART 22528
#define	ATTRLEN	767

// An attribute based "fadeout" sort-of effect.
// The difference between this version (in the matchmaker) and the
// version in the client is that this expects interrupts to be
// enabled already.
void fadeOut() {
#asm
	ld b, 8
	ld a, b
.fadeloop
	dec a
	push bc
	halt
	halt
	halt
	ld hl, ATTRSTART
	ld de, ATTRSTART+1
	ld bc, ATTRLEN
	ld (hl), a
	ldir
	pop bc
	djnz fadeloop
#endasm
}

