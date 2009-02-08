/* usercmd.c
 *
 * Processes commands typed by the user.
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
#include <stdlib.h>
#include <string.h>
#include "irc.h"

char outbuf[384];
int parseUserCmd(char *cmd)
{
	if(!cmd) return 1;		/* nothing to do */
	if(!strlen(cmd)) return 1;	/* still nothing to do */

	if(*cmd == '/')
	{
		return parseSlashCmd(cmd+1);
	}

	/* if no slash, it's just a normal chat message */
	if(!strlen(chan))
		mainprint("*** You're not in a channel!");
	else
	{
		strcpy(outbuf, "PRIVMSG ");
		strlcat(outbuf, chan, sizeof(outbuf));
		strlcat(outbuf, " :", sizeof(outbuf));
		strlcat(outbuf, cmd, sizeof(outbuf));

		sendIrcMsg(outbuf, sizeof(outbuf));
		nickprint(nick, NICKTYPE_OURS);
		mainprint(cmd);
	}

	return 1;
}

int parseSlashCmd(char *cmd)
{
	char *param1;
	char *param2;

	if(!strncmp(cmd, "quit", 4))
	{
		return 0;
	}
	
	if(!strncmp(cmd, "me", 2))
	{
		if(!strlen(chan))
		{
			mainprint("You are not in a channel.");
			return 1;
		}
		strlcpy(outbuf, "PRIVMSG ", sizeof(outbuf));
		strlcat(outbuf, chan, sizeof(outbuf));
		strlcat(outbuf, " :\001ACTION ", sizeof(outbuf));
		strlcat(outbuf, cmd+3, sizeof(outbuf));
		strlcat(outbuf, "\001", sizeof(outbuf));
		sendIrcMsg(outbuf, sizeof(outbuf)-2);
		
		/* echo what we did in red */
		printk("\x10\x32");
		strlcpy(outbuf, nick, sizeof(outbuf));
		strlcat(outbuf, cmd+2, sizeof(outbuf));
		mainprint(outbuf);
		printk("\x10\x30");

		return 1;
	}

	if(!strncmp(cmd, "msg", 3))
	{
		param1=strtok(cmd+4, " ");
		param2=strtok(NULL, "\n");

		strlcpy(outbuf, "PRIVMSG ", sizeof(outbuf));

		/* recipient */
		strlcat(outbuf, param1, sizeof(outbuf));
		strlcat(outbuf, " :", sizeof(outbuf));

		/* message */
		strlcat(outbuf, param2, sizeof(outbuf));

		/* echo in magenta */
		printk("\x10\x33");
		mainprint(outbuf);
		printk("\x10\x30");
		
		/* send to server */
		sendIrcMsg(outbuf, sizeof(outbuf)-2);
		return 1;
	}

	/* user commands come from the keyboard input buffer */
	sendIrcMsg(cmd, INPUTSZ-2);
	return 1;
}

