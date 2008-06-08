/* statusline.c
 * Handles the status line for the IRC client.
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

void setStatusLine(char *nickname, char *channel)
{
	char tmpnick[15];
	char tmpchan[32];

	strncpy(tmpnick, nickname, 14);
	strncpy(tmpchan, channel, 31);

	/* set cursor position to print the status line */
	/* paper blue, ink white, bright 1 */
	printk("\x16\x36\x20\x10\x37\x11\x31\x13\x01 ");
	printk("                                                             ");
	printk("\x16\x36\x21[%s]\x16\x36\x3F[%s]", nick, chan);
	printk("\x10\x30\x11\x37\x13");
	putchar(0);
}

