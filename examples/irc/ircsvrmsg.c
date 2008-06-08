/* ircsvrmsg.c
 *
 * Processes messages received from the server.
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

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "irc.h"

void parseIrcMessage(char *msg)
{
	char *ptr=msg;
	while(*ptr != ' ')
	{
		if(!*ptr)
			return;	/* never had enough tokens */
		ptr++;
	}
	ptr++;

	/* Find out what kind of message */
	if(*ptr >= '0' && *ptr <= '9')
	{
		parseNumResponse(ptr);
	}
	else
	{
		parseOtherResponse(ptr);
	}
}

/* Parse a numeric message, i.e. one that has a 3-digit response code */
void parseNumResponse(char *msg)
{
	unsigned int msgcode;
	char *code;
	char *svrnick;
	char *rest=msgcode;
	
	/* find last : before strtok sticks nulls everywhere */
	rest++;
	while(*rest != ':' && *rest)
	{
		rest++;
	}
	rest++;
	code=strtok(msg, " ");
	svrnick=strtok(NULL, " ");
	
	/* Is there at least a code? */
	if(!code)
		return;

	msgcode=atoi(code);

	/* If our nick isn't registered we tend to first find out
	   from a random server message */
	if(!nick[0])
	{
		strcpy(nick, svrnick);
		setStatusLine(nick, chan);
	}
	mainprint(rest);
}

/* Parse other messages, such as NOTICE etc. */
void parseOtherResponse(char *msg)
{
	char *ptr=msg;
	while(*ptr != ' ')
	{
		if(!*ptr)
			return;		/* oops, nothing to do */
		ptr++;
	}
	*ptr=0;
	ptr++;	/* points to the start of the message body */

	/* This is a very simple and inefficient parser, but this client
	   as yet doesn't understand much more. A table-based one may 
	   be better if this client is expanded */
	mainprint(ptr);
}

