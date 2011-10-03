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
#include <netdb.h>
#include <sockpoll.h>
#include <string.h>

#include "ctf.h"
#include "message.h"

int sockfd;		// The socket handle.
char msgbuf[256];	// Messages are received here.
struct sockaddr_in remoteaddr;	// Server's address

// Connect to the server
// Return codes:
// -1 Could not look up host
// -2 Could not create socket
// -3 sendto() failed
// -4 recvfrom() failed
int initConnection(char *host, char *player) {
	struct hostent *he;
	struct sockaddr_in rxaddr;
	char buf[32];
	int addrlen;

	// Hello message when connecting to the server.
	buf[0]=HELLO;
	strlcpy(&buf[1], player, sizeof(buf)-1);

	he=gethostbyname(host);
	if(!he) return -1;

	remoteaddr.sin_family=AF_INET;
	remoteaddr.sin_port=htons(CTFPORT);
	remoteaddr.sin_addr.s_addr=he->h_addr;

	// Look up the host.
	sockfd=socket(AF_INET, SOCK_DGRAM, 0);
	if(sockfd < 0) return -2;

	// Send the hello message.
	if(sendto(sockfd, buf, sizeof(buf), 0, &remoteaddr, sizeof(remoteaddr)) < 0)
		return -3;

	// Get the acknowledgement. (TODO, implement a timeout)
	// TODO check the data received was from the same address
	if(recvfrom(sockfd, buf, sizeof(buf), 0, &rxaddr, &addrlen) < 0)
		return -4;

	return 0;
}

// The game loop is based on sending and receiving messages to the
// server, so once the game is in progress we loop around here until
// the game is over.
// A negative return code means an error:
// -1 Poll error
int messageloop() {
	struct sockaddr_in rxaddr;
	char p;
	int rc;
	int addrsz;
	uchar numMsgs;
	uchar msgType;
	char *msgptr;

	while(1) {
		p=poll_fd(sockfd);
		if(p == 128) return -1;
		if(p != POLLIN) {
	//		doUserInput();
		 	continue;
		}

		// Messages are ready. Read them.
		rc=recvfrom(sockfd, msgbuf, sizeof(msgbuf), 0, &rxaddr, &addrsz);
		msgptr=msgbuf;
		numMsgs=*msgptr++;

		while(numMsgs) {
			msgType=*msgptr++;

			switch(msgType) {
				case MAKESPRITE:
					putSprite((MakeSpriteMsg *)msgptr);
					msgptr+=sizeof(MakeSpriteMsg);
					break;
				case MOVESPRITE:
					moveSprite((MoveSpriteMsg *)msgptr);
					msgptr+=sizeof(MoveSpriteMsg);
					break;
				default:
					return -2;
			}

			numMsgs--;
		}
	}
}

