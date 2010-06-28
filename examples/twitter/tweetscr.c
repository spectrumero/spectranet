/*
 * The MIT License
 *
 * Copyright (c) 2010 Dylan Smith
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
 *
*/

/* Load the Twitter logo SCR image.
 * This is done in asm because the Spectranet filesystem hasn't yet
 * been integrated with the z88dk fcntl. */

#include <tweet.h>

void tweet_loadscr()
{
#asm
DEFC OPEN = 0x3EB1
DEFC READ = 0x3EC9
DEFC VCLOSE = 0x3ED2
DEFC PAGEIN = 0x3FF9
DEFC PAGEOUT = 0x007C
DEFC O_RDONLY = 0x01

	call PAGEIN
	ld hl, str_scrfilename
	ld d, 0				; no flags
	ld e, O_RDONLY			; and read only
	call OPEN
	jr c, exitload

	push af				; save the filehandle
	ld de, 16384			; framebuffer start
	ld bc, 6912			; and length
	call READ

	pop af
	call VCLOSE
.exitload
	call PAGEOUT
#endasm
}

#asm
.str_scrfilename
	defm "twitter.scr"
	defb 0
#endasm


