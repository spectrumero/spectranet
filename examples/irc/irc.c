/* irc.c
 * The main routine for the IRC client.
 *
 * Copyright (c) 2008 Dylan Smith
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
#include <sys/types.h>
#include <sys/socket.h>
#include <sockpoll.h>
#include <netdb.h>
#define __MAIN__C
#include "irc.h"

char nick[24];		/* user's nickname */
char server[32];	/* server to use */
char chan[32];		/* channel joined */
char tempbuf[128];	/* some storage */
int ircfd=0;		/* socket file descriptor */

void setupConnection();	/* get init. connection parameters */
char *kbinput();	/* get keyboard input only */
void connToServer();	/* Connect to the selected server */
void inputLoop();	/* The main connected input loop */
void extractIrcMessages(char *buf, unsigned int size);
	
main()
{
//	char dbg[256];
//	int i;
	char *kbentry;

	/* clear screen, general initialization */
	putchar(12);	/* clear screen */
	setStatusLine("No nickname", "No channel");
	inputinit();
	mainclear();

//	for(i=0; i<11; i++)
//	{
//		sprintf(dbg, "%d: Mary had a little lamb, the doctors were astounded. And everywhere that mary went, Gynaecologists surrounded", i);
//		mainprint(dbg);
//	}

	/* Set up initial connection params */
	setupConnection();

	connToServer();
	if(ircfd)
	{
		inputLoop();
	}
//	while(1)
//	{
//		kbentry=kbinput();
//		if(kbentry && !strcmp(kbentry, "x"))
//		{
//			break;
//		}
//	}

	inputexit();
}

/* Init server settings */
void setupConnection()
{
	char *str;

	resetinput();
	while(1)	/* until valid nick */
	{
		mainprint("Please enter your nick (max 24 chars):");
		str=kbinput();
		if(strlen(str) > sizeof(nick))
		{
			mainprint("Nickname too long.");
		}
		else
		{
			strcpy(nick, str);
			mainprint(nick);
			break;
		}
	}

	resetinput();
	while(1)	/* until valid server */
	{
		mainprint("Please enter a server to connect to:");
		str=kbinput();
		if(strlen(str) > sizeof(server))
		{
			mainprint("Server name too long.");
		}
		else
		{
			strcpy(server, str);
			mainprint(server);
			break;
		}
	}
}

/* This function simply gets keyboard entry, used for when we aren't
 * connected to a server */
char *kbinput()
{
	char *kb;
	while(1)
	{
		kb=checkKey();
		if(kb)
			break;
	}
	return kb;
}

/* Connects to the specified server in the server[] array and sets the
 * global ircfd socket handle */
void connToServer()
{
	int rc;
	struct hostent *he;
	struct sockaddr_in servaddr;
	char connmsg[256];

	sprintf(tempbuf, "*** Looking up %s...", server);
	mainprint(tempbuf);

	he=gethostbyname(server);
	if(!he)
	{
		mainprint("--- Could not resolve host");
		return;
	}	

	sprintf(tempbuf, "*** Connecting to %s...", server);
	mainprint(tempbuf);
	ircfd=socket(AF_INET, SOCK_STREAM, 0);		
	if(ircfd < 0) return;

	servaddr.sin_port=6667;
	servaddr.sin_addr.s_addr=he->h_addr;
	if(connect(ircfd, &servaddr, sizeof(sockaddr_in)) < 0)
	{
		sockclose(ircfd);
		ircfd=0;
		mainprint("--- Failed to connect to host");
		return;
	}
	mainprint("*** Connected.");	
	setStatusLine("Not registered", "No channel");

	/* Identify to the server */
	sprintf(connmsg, "NICK %s\r\nUSER %s %s %s: Spectranet\r\n",
		nick, nick, nick, server);

	/* The server must confirm the nick */
	memset(nick, 0, sizeof(nick));
	memset(chan, 0, sizeof(chan));

	rc=send(ircfd, connmsg, strlen(connmsg), 0);
	if(rc < 0)
		mainprint("--- ERROR: send failed!");
}

/* inputLoop reads input from the keyboad and the IRC socket
 * and dispatches the result to its appropriate function */
void inputLoop()
{
	char netinput[NETBUFSZ]; /* network input buffer */
	int rc;
	char *kb;		/* pointer to keyboard buffer */
	resetinput();

	while(1)
	{
		/* only poll the socket if it's open and connected */
		if(ircfd)
		{
			rc=poll_fd(ircfd);
			if(rc & POLLIN)
			{
				memset(netinput, 0, NETBUFSZ);
				rc=recv(ircfd, netinput, NETBUFSZ-1,
					0);
				if(rc < 0)
				{
					mainprint("--- ERROR: recv failed!");
					return;
				}
				extractIrcMessages(netinput, rc);
			}
		}

		/* keyboard input ready? */
		kb=checkKey();
		if(kb)
		{
			if(!parseUserCmd(kb))
			{
				/* user is done if this returns 0 */
				sockclose(ircfd);
				return;
			}
			resetinput();
		}
	}
}

/* Extracts IRC messages (since there may be several in a receive buffer) and assembles
 * fragmented messages, then sends them to the parser */
void extractIrcMessages(char *buf, unsigned int rxsz)
{
	char *msg, *ptr;
	unsigned int count=0;

	msg=buf;
	ptr=buf;

	/* tokenize the incoming message by the terminating \n */
	while(*ptr && count < rxsz)
	{
		if(*ptr == 0x0A)
		{
			*ptr=0;
			parseIrcMessage(msg);
			msg=ptr+1;
		}
		*ptr++;
		count++;
	}
}

/* sendIrcMsg properly formats (well, puts 0x0D,0x0A on the end of) 
 * a message, and sends it. The caller must pass a buffer big enough
 * to do this. */
void sendIrcMsg(char *msg)
{
	int rc;
	strcat(msg, "\x0D\x0A");
	rc=send(ircfd, msg, strlen(msg), 0);
	if(rc < 0)
	{
		mainprint("*** ERROR: send() failed!");
	}
}

