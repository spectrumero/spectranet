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

#include <sys/socket.h>
#include <sys/types.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "ctfmessage.h"
#include "ctfserv.h"

int sockfd;
char msgbuf[256];

// Client list
struct sockaddr_in *cliaddr[MAXCLIENTS];

// Make the socket.
// Returns -1 if the socket could not be created
// Returns -2 if bind() fails
int makeSocket() {
	struct sockaddr_in locaddr;
	sockfd=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if(sockfd < 0) return -1;

	locaddr.sin_family=AF_INET;
	locaddr.sin_port=htons(CTFPORT);
	locaddr.sin_addr.s_addr=htonl(INADDR_ANY);
	if(bind(sockfd, (struct sockaddr *)&locaddr, sizeof(locaddr)) == -1)
		return -2;

	// zero out client pointers
	memset(cliaddr, 0, sizeof(cliaddr));

	return 0;
}

// Effectively the main game loop. Uses select() to wait for
// messages and time the game loop in a rudimentary fashion.
// (A more complex game would need a more complex way of timing
// the game play, but here we just use the timeout on select() to
// time the actual game progress).
//
// Note this code is unashamedly Unix oriented, but it should port
// to Windows with minimal modifications (possibly no modifications)
// since Windows at least implements the select syscall for sockets.
// It should run straight out of the box on anything Unixy (Mac, Linux,
// BSD etc.)
int messageLoop() {
	fd_set fds;
	struct timeval timeout;
	int rc;

	// select() should return immediately if there's nothing for
	// us to process.
	timeout.tv_sec=0;		
	timeout.tv_usec=1;

	while(1) {
		// Set up the set of file descriptors
		FD_ZERO(&fds);
		FD_SET(sockfd, &fds);
		rc=select(sockfd+1, &fds, NULL, NULL, &timeout);

		if(rc < 0) {
			perror("select");
			return rc;
		}
		
		if(FD_ISSET(sockfd, &fds)) {	
			rc=getMessage();
			if(rc < 0) {
				return rc;
			}
		}
	
		printf(".");
		fflush(stdout);	
		
		// wait for GAMETICK microseconds.
		usleep(GAMETICK);
	}
	return 0;
}

// Receive a message from the socket and dispatch it.
int getMessage() {
	struct sockaddr_in rxaddr;
	ssize_t bytes;
	ssize_t bytesleft;
	char *msgptr;
	socklen_t addrlen=sizeof(rxaddr);

	memset(msgbuf, 0, sizeof(msgbuf));
	bytes=recvfrom(sockfd, msgbuf, sizeof(msgbuf), 0,
			(struct sockaddr *)&rxaddr, &addrlen);
	if(bytes < 0) {
		perror("recvfrom");
		return bytes;
	}

	msgptr=msgbuf;
	if(*msgptr == HELLO) {
		// New connection
		addNewClient(msgptr, &rxaddr);
	} else {
		// Find the client connection
		while((bytesleft=bytes-(msgptr-msgbuf)) > 0) {

		}	
	}
	
	return bytes;
}

// Add a new client.
int addNewClient(char *hello, struct sockaddr_in *client) {
	int i;
	char ackbuf[2];
	ackbuf[0]=ACK;

	// Find a new slot
	for(i=0; i<MAXCLIENTS; i++) {
		if(cliaddr[i] == NULL) {
			cliaddr[i]=(struct sockaddr_in *)malloc(sizeof(struct sockaddr_in));
			memcpy(cliaddr[i], client, sizeof(struct sockaddr_in));

			// send the acknowledgement
			ackbuf[1]=ACKOK;
			if(sendto(sockfd, ackbuf, sizeof(ackbuf), 0,
						(struct sockaddr *)client, sizeof(struct sockaddr_in)) < 0) {
				perror("sendto");
				return -1;
			}

			return 0;
		}
	}

	// If we get here, we've run out of client slots.
	// Reply "no can do"
	ackbuf[1]=ACKTOOMANY;
	if(sendto(sockfd, ackbuf, sizeof(ackbuf), 0,
				(struct sockaddr *)client, sizeof(struct sockaddr_in)) < 0) {
		perror("sendto");
		return -1;
	}
	return 0;
}

// Find the client's address in the list and remove it.
void removeClient(struct sockaddr_in *client) {
	int i;
	for(i=0; i<MAXCLIENTS; i++) {
		if(client->sin_addr.s_addr == cliaddr[i]->sin_addr.s_addr &&
			 client->sin_port == cliaddr[i]->sin_port) {
			free(cliaddr[i]);
			cliaddr[i]=NULL;
			return;
		}
	}

	fprintf(stderr, "erk, unable to find client %s:%d\n",
			inet_ntoa(client->sin_addr), ntohs(client->sin_port));
}

