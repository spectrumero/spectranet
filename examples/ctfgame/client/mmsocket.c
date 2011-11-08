/*
;The MIT License
;
;Copyright (c) 2011 Dylan Smith
;
;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:
;
;The above copyright notice and this permission notice shall be included in
;all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;THE SOFTWARE.
*/
#include <sys/socket.h>
#include <sys/types.h>
#include <netdb.h>
#include <sockpoll.h>
#include <string.h>
#include <spectrum.h>

#include "matchmake.h"
#include "ctfmessage.h"

int sockfd;
uchar sendbuf[256];
uchar rxbuf[1024];
struct sockaddr_in remoteaddr;

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


int messageloop() {
  struct sockaddr_in rxaddr;
  char *msgptr;
  int addrsz;
  int rc;
  int p;
  uchar numMsgs;
  uchar msgType;

  while(1) {
    p=poll_fd(sockfd);
    if(p == 128) return -1;

    if(p != POLLIN) {
      getMatchmakeInput();
      continue;
    }

    rc = recvfrom(sockfd, rxbuf, sizeof(rxbuf), 0, &rxaddr, &addrsz);
    msgptr=rxbuf;
    numMsgs=*msgptr++;
    while(numMsgs) {
      switch(msgType) {
        case MATCHMAKEMSG:
          displayMatchmake((MatchmakeMsg *)msgptr);
          msgptr+=sizeof(MatchmakeMsg);
          break;
        case MESSAGEMSG:
          displayStatus((MessageMsg *)msgptr);
          msgptr+=sizeof(MessageMsg);
          break;
        default:
          sendbuf[0]=SERVERKILL;
          zx_border(RED);
          return sendMsg(1);
      }

      numMsgs--;
    }
  }
}

