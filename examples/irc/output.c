/* output.c
 * "Main window" output routines (lines 0-21). Since the console
 * print routine only scrolls for whole screenfuls, we keep track of
 * how much we've printed here too, so we can scroll at line 21. Also,
 * the scroll routine is a fast 'jump scroll' rather than the normal
 * ROM scroll routine (which also only does the whole screen).
 *
 * Copyright (c) 2008 Dylan Smith
 * 
 * The MIT License
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <stdio.h>
#include <string.h>
#include "irc.h"

uchar ypos;

/* mainclear clears the main window and resets the cursor position to the
 * top line */
void mainclear()
{
	ypos=0;

	/* clear the first 4k with a simple ldir, then clear the last
	   all-but-two lines */
#asm
	ld hl, 0x4000
	ld de, 0x4001
	ld bc, 0x0FFF
	ld (hl), 0
	ldir

	ld hl, 0x5000	; top of last third
	ld de, 0x5001
	ld b, 8
.loop			; the inner loop clears a line
	push bc
	push hl	
	push de
	ld bc, 191	; 6 lines worth
	ld (hl), 0
	ldir
	pop de
	pop hl
	pop bc
	inc h
	inc d
	djnz loop
#endasm
}

void mainprint(char *str)
{
	
}

