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
	struct ircmsg im;
	struct irccmd ic;

	/* parse msgs in format :something cmd params :message */
	if(*msg == ':')
	{
		im.prefix=strtok(msg+1, " ");
		im.command=strtok(NULL, " ");
		im.param=strtok(NULL, " ");
		im.msg=strtok(NULL, "\x0d");

		/* if param is the last member, an 0x0D tends to be left
		   on the end */
		chomp(im.param);

		if(*(im.command) >= '0' && *(im.command) <= '9')
		{
			parseNumResponse(&im);
			return;
		}
		parseOtherResponse(&im);
	}
	else
	{
		ic.command=strtok(msg, " ");
		ic.param=strtok(NULL, "\x0d");
		parseServerCmd(&ic);
	}
}

/* Parse a numeric message, i.e. one that has a 3-digit response code */
void parseNumResponse(struct ircmsg *im)
{
	/* If our nick isn't registered we tend to first find out
	   from a random server message */
	if(!nick[0])
	{
		strcpy(nick, im->param);
		setStatusLine(nick, chan);
	}
	if(im->msg && strlen(im->msg) > 2)
	{
		mainprint((im->msg+1));
	}
}

/* Parse other messages, such as NOTICE etc. */
void parseOtherResponse(struct ircmsg *im)
{
	char *str;

	if(!im->param) return;	/* nothing to do! */

	/* This is a very simple and inefficient parser, but this client
	   as yet doesn't understand much more. A table-based one may 
	   be better if this client is expanded */
	if(!strcmp(im->command, "PRIVMSG"))
	{
		/* extract the sender's nick */
		str=strtok(im->prefix, "!");
		nickprint(str, 0);
		mainprint(im->msg+1);
		return;
	}
		
	if(!strcmp(im->command, "JOIN"))
	{
		strcpy(chan, (im->param)+1);
		setStatusLine(nick, chan);
		return;
	}

	/* display anything not handled */
	if(im->msg && strlen(im->msg) > 2)
	{
		mainprint((im->msg)+1);
	}
}

/* Parse commands the server sends to us */
void parseServerCmd(struct irccmd *ic)
{
	char replybuf[64];
	if(!ic->command)
		return;		/* nothing to do */

	/* Another quick and dirty parser */
	if(!strcmp(ic->command, "PING"))
	{
		sprintf(replybuf, "PONG %s", nick);
		sendIrcMsg(replybuf);
		return;
	}

	/* if we don't know how to handle it, just print it */
	mainprint(ic->command);
	if(ic->param) mainprint(ic->param);
}

/* chomp: do pretty much what the perl chomp function does */
void chomp(char *str)
{
	if(str)
	{
		while(*str)
		{	
			if(*str == 0x0D) *str=0;
			str++;
		}
	}
}
	
