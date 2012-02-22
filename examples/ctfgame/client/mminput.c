/* inputline.c
 * Put/remove/handle characters to be displayed in the input line.
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
#define __MMINPUT__C_
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <input.h>
#include <im2.h>

#include "matchmake.h"

#define KBUFSZ 8
#define INPUTSZ 140
#define COL_INK 55
#define COL_PAPER 49
#define COMPLETE_INK 6
#define COMPLETE_PAPER 0
#define ATTR_START 22528

char kbuf[KBUFSZ];	/* Circular keyboard buffer */
int bufoffset;		/* buffer offset */
int readoffset;		/* where we've got to reading the buffer */
char inputbuf[INPUTSZ];	/* static buffer to store user input */
int inputidx;		/* static input index */
int charpos;		/* current character position */

/* keyboard variable declarations for in_GetKey() */
uchar in_KeyDebounce=1;
uchar in_KeyStartRepeat=20;
uchar in_KeyRepeatPeriod=5;
uint in_KbdState;
uchar input_ready=0;
char debounce_enter=0;

/* dimensions of input box */
char startx=0;
char starty=0;
char width=0;
char height=0;
char curx;
char cury;
int length=0;
char ispasswd=0;

/* resetinput - resets the input routines */
void resetinput(char sx, char sy, char wid, char hgt, int len)
{
	input_ready=0;
	startx=sx;
	starty=sy;
	width=wid;
	height=hgt;
	length=len;
	debounce_enter=0;

	curx=sx;
	cury=sy;

	/* set 32 col mode */
	putchar(1);
	putchar(32);

	clearArea(COL_INK, COL_PAPER);

	/* clear down buffer */
	memset(inputbuf,0,sizeof(inputbuf));
	inputidx=0;
	in_GetKeyReset();
}

/* simple keyboard get routine */
char *kbinput(char ispw)
{
	char *kb;
	ispasswd=ispw;
	while(1)
	{
		kb=checkKey();
		if(kb)
			break;
	}
	return kb;
}

/* Clears the defined area to attr colours. This routine
 * is deliberately simple because I need it to be ready by the VCF! */
void clearArea(char ink, char paper)
{
	char x,y;
	putchar(16);
	putchar(ink);
	putchar(17);
	putchar(paper);

	for(y=starty; y < starty+height; y++)
	{
		putchar(22);
		putchar(y+32);
		putchar((startx*2)+32);
		for(x=0; x < width; x++)
		{
			putchar(32);
		}
	}

	/* put cursor in top left of the box */
	curx=startx;
	cury=starty;
}

void colourArea(char ink, char paper)
{
	int x,y;
	unsigned int addr;
	char attr=(paper << 3) | ink;

	for(y=starty; y < starty+height; y++)
	{
		addr=ATTR_START+(y*32)+startx;
		for(x=0; x < width; x++)
		{
			bpoke(addr, attr);
			addr++;
		}
	}

	/* put cursor in top left of the box */
	curx=startx;
	cury=starty;
}

/* moves the cursor to the current position */
void moveToCurrent()
{
	putchar(22);
	putchar(32+cury);
	putchar(32+(curx*2));
}

/* handlekey - deal with the last key press and put it on the screen */
void handleKey(uchar key)
{
	int rclidx;

	moveToCurrent();
	switch(key)
	{
		case 12:	/* delete */
			/* todo: deal with delete in the middle of a string */
			debounce_enter=1;
			if(inputidx == 0) break;	/* nothing to do */

			inputidx--;
			inputbuf[inputidx]=0;

			if(curx > startx)
			{
				curx--;
				printk("\x08_ ");
			}
			else
			{
				putchar(32);
				cury--;
				curx=startx+width-1;
				moveToCurrent();
				putchar('_');
			}
			break;
		case '\n':	/* enter */
			if(debounce_enter)
			{
				inputbuf[inputidx]=0;	/* null terminate */
				putchar(32); 		/* delete cursor */
				input_ready=1;
				colourArea(COMPLETE_INK, COMPLETE_PAPER);
			}
			else
				debounce_enter=1;
			break;
		default:	/* normal key */
			debounce_enter=1;
			if(inputidx >= sizeof(inputbuf) ||
			   inputidx >= length)
				break;	/* no more room in buffer */

			if(ispasswd)
				putchar('*');
			else
				putchar(key);

			if(curx >= startx+width-1)
			{
				curx=startx;
				cury++;
				moveToCurrent();
			}
			else
			{
				curx++;
			}

			inputbuf[inputidx++]=key;
			putchar('_');	/* The cursor */
	}
}

char *checkKey()
{
	uchar k;
//#asm
//	di
//#endasm
	if(readoffset != bufoffset)
	{
		k=*(kbuf+readoffset);
#asm
		ei
#endasm
		readoffset++;
		if(readoffset == KBUFSZ)
			readoffset=0;

		handleKey(k);
		if(k == '\n' && input_ready)
		{
			return inputbuf;
		}
	}
#asm
	ei
#endasm
	return NULL;
}

char getSingleKeypress()
{
	uchar k=0;
	while(1)
	{
		if(readoffset != bufoffset)
		{
#asm
			di
#endasm
			k=*(kbuf+readoffset);
			readoffset=bufoffset;
#asm
			ei
#endasm
			break;
		}
	}
	return k;
}

char keyReady() {
	if(readoffset != bufoffset)
		return 1;
	return 0;
}

/* The ISR handles filling the keyboard buffer, which is a circular
 * buffer. The keyboard handler in the 'main thread' should pick characters
 * off this buffer till it catches up */
M_BEGIN_ISR(isr)
{
	uchar k=in_GetKey();

	if(k)
	{
		*(kbuf+bufoffset)=k;

		bufoffset++;
		if(bufoffset == KBUFSZ)
			bufoffset=0;
	}
}
M_END_ISR


/* Initialization routine that should be called when the client starts */
void inputinit()
{
	/* IM2 keyboard polling routine setup - this from the
 	   example in the z88dk wiki documentation */
	#asm
	di
	#endasm
/*
	im2_Init(0xd300);
	memset(0xd300, 0xd4, 257);
	bpoke(0xd4d4, 195);
	wpoke(0xd4d5, isr);*/

	im2_Init(0xfd00);
	memset(0xfd00, 0xfe, 257);
	bpoke(0xfefe, 195);
	wpoke(0xfeff, isr);

	/* initialize the keyboard buffer */
	memset(kbuf, 0, sizeof(kbuf));
	bufoffset=0;
	readoffset=0;

	#asm
	ei
	#endasm
}

/* De-initialize IM2 etc. to return to BASIC. */
void inputexit()
{
	#asm
	di
	im 1
	ei
	#endasm
}

