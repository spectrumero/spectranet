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

/* This function should be allowed to do all the printing, so scrolling
 * can happen at the right place. TODO: word wrap, slow scroll */
void mainprint(char *str)
{
	char *ptr=str;

	/* find new ypos after the string has printed */
	ypos+=(strlen(str)/64)+1;
	if(ypos > 21)
	{
		quickscroll();
	}
	putchar(0x16);
	putchar(32+ypos);
	putchar(0x20);
	while(*ptr)
	{
		/* make sure that we don't display weird characters
		   that the irc server is wont to send - 0x70 = printable
                   character mask */
		if(*ptr & 0x70)
		{
			putchar(*ptr);
		}
		ptr++;
	}	
}

void quickscroll()
{
#asm
	ld hl, 0x4800		; scroll first 2/3rds
	ld de, 0x4000
	ld bc, 0x0800
	ldir

	; scroll last 6 lines up to previous 3rd
	ld hl, 0x5000	; top of last third
	ld de, 0x4800
	ld b, 8
.scrollloop
	push bc
	push hl	
	push de
	ld bc, 192	; 6 lines worth
	ldir
	pop de
	pop hl
	pop bc
	inc h
	inc d
	djnz scrollloop
	ld hl, 0x5000	; clear the bottom 3rd
	ld de, 0x5001
	ld c, 191
	call lineclear
	ld hl, 0x48C0	; last two lines of 2nd 3rd
	ld de, 0x48C1
	ld c, 63
	call lineclear
	jr cleardone
.lineclear
	ld b, 8
.clearloop
	push bc
	push hl	
	push de
	ld b, 0		; num of bytes to clear in C
	ld (hl), 0
	ldir
	pop de
	pop hl
	pop bc
	inc h
	inc d
	djnz clearloop
	ret
.cleardone
#endasm

	ypos=14;	/* new line to print from */
}
