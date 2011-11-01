// The MIT License
// 
// Copyright (c) 2011 Dylan Smith
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

// Receive and transmit messages.
//
#include <sys/socket.h>
#include <sys/types.h>
#include <sprites/sp1.h>
#include <netdb.h>
#include <sockpoll.h>
#include <string.h>
#include <stdio.h>

#include "ctf.h"
#include "ctfmessage.h"

int sockfd;		// The socket handle.
uchar sendbuf[256];	// Send buffer
uchar rxbuf[1024];	// Messages are received here.
struct sockaddr_in remoteaddr;	// Server's address

// Connect to the server
// Return codes:
// -1 Could not look up host
// -2 Could not create socket
// -3 sendto() failed
// -4 recvfrom() failed
// -5 Server full
int initConnection(char *host, char *player) {
	struct hostent *he;
	int rc;

	// Hello message when connecting to the server.
	sendbuf[0]=HELLO;
	strlcpy(&sendbuf[1], player, MAXNAME);

	he=gethostbyname(host);
	if(!he) return -1;

	remoteaddr.sin_family=AF_INET;
	remoteaddr.sin_port=htons(CTFPORT);
	remoteaddr.sin_addr.s_addr=he->h_addr;

	// Look up the host.
	sockfd=socket(AF_INET, SOCK_DGRAM, 0);
	if(sockfd < 0) return -2;

	// Send the hello message.
	rc=sendSyncMsg(MAXNAME+1);
	if(rc < 0) return rc;

	if(*(rxbuf+1) == ACKTOOMANY)
		return -5;
	return 0;
}

int startGame(MapXY *xy) {
	int rc;
	uchar *bufptr;

	// The game start message is just a single byte.
	sendbuf[0]=START;
	rc=sendSyncMsg(1);
	if(rc < 0)
		return rc;

	// Only one message should ever come back, advance the
	// buffer pointer to its start.
	bufptr=rxbuf+1;
	if(*bufptr++ != STARTACK)
		return NACK;

	memcpy(xy, bufptr, sizeof(MapXY));
	return rc;
}

int sendSyncMsg(int txbytes) {
	struct sockaddr_in rxaddr;
	int addrlen;
	int bytes=0;
	if(sendto(sockfd, sendbuf, txbytes, 0, &remoteaddr, sizeof(remoteaddr)) < 0)
		return TXERROR;
	
	if((bytes=recvfrom(sockfd, rxbuf, sizeof(rxbuf), 0, &rxaddr, &addrlen)) < 0)
		return RXERROR;
	return bytes;
}

int sendMsg(int txbytes) {
	if(sendto(sockfd, sendbuf, txbytes, 0, &remoteaddr, sizeof(remoteaddr)) < 0)
		return TXERROR;
	return 0;
}

int sendControlMsg(uchar dirs) {
	sendbuf[0]=CONTROL;
	sendbuf[1]=dirs;
	return sendMsg(2);
}

// The game loop is based on sending and receiving messages to the
// server, so once the game is in progress we loop around here until
// the game is over.
// A negative return code means an error:
// -1 Poll error
int messageloop() {
	struct sockaddr_in rxaddr;
	char p;
	char spriteMsgs;
	int rc;
	int addrsz;
	uchar numMsgs;
	uchar msgType;
	char *msgptr;
	spriteMsgs=FALSE;

	// tell the server that the message loop is running
	sendbuf[0] = CLIENTRDY;
	sendMsg(1);

	while(1) {
		p=poll_fd(sockfd);
		if(p == 128) return -1;
		if(p != POLLIN) {
			getInput();
			updateMsgArea();
		 	continue;
		}

		// Messages are ready. Read them.
		rc=recvfrom(sockfd, rxbuf, sizeof(rxbuf), 0, &rxaddr, &addrsz);
		msgptr=rxbuf;
		numMsgs=*msgptr++;
		while(numMsgs) {
			msgType=*msgptr++;

			switch(msgType) {
				case SPRITEMSG:
					manageSprite((SpriteMsg *)msgptr);
					msgptr+=sizeof(SpriteMsg);
					spriteMsgs=TRUE;
					break;
				case RMSPRITEMSG:
					removeSprite((RemoveSpriteMsg *)msgptr);
					msgptr+=sizeof(RemoveSpriteMsg);
					spriteMsgs=TRUE;
					break;
				case VIEWPORT:
					switchViewport((MapXY *)msgptr);
					msgptr+=sizeof(MapXY);
					break;
				case MAPMSG:
					// Map messages must be the only (or last) message
					// Make sure anything else gets dropped.
					drawMap(msgptr);
					numMsgs=1;
					break;					
				case MESSAGEMSG:
					setMsgArea((MessageMsg *)msgptr);
					msgptr+=sizeof(MessageMsg);
					break;
				case SCOREBOARD:
					updateScoreboard((NumberMsg *)msgptr);
					msgptr+=sizeof(NumberMsg);
					break;
				case FLAGALERT:
					flagAlert(*msgptr);
					msgptr++;
					break;
				default:
					sendbuf[0]=SERVERKILL;
					zx_border(RED);
					return sendMsg(1);
			}

			numMsgs--;
		}

		if(spriteMsgs) {
			sp1_UpdateNow();
			spriteMsgs=FALSE;
		}
	}
}

// disconnect from the game, and inform the server that we've gone
int disconnect() {
	int rc, i;
	sendbuf[0]=BYE;
  rc=sendSyncMsg(1);

	sockclose(sockfd);
	return rc;
}

// Send a viewport message.
int sendViewportMsg(Viewport *vp) {
	int bytes;

	sendbuf[0]=VIEWPORT;
	memcpy(&sendbuf[1], vp, sizeof(Viewport));
	return sendMsg(sizeof(Viewport) + 1);
}

