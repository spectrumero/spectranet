// The MIT License
// 
// Copyright (c) 2013 Dylan Smith
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

// Spectator mode socket stuff

#ifdef UNIX
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <netdb.h>
#endif
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>

#include "ctfmessage.h"
#include "rxtx.h"
#include "gfx.h"

int sockfd;
uchar rxbuf[1024];
uchar sendbuf[256];
struct sockaddr_in remoteaddr;

void makeSocket(const char *host) {
    struct sockaddr_in locaddr;
    struct hostent *he;
    int i;
#ifdef WIN32
    WSADATA wsaData;
    if (WSAStartup(MAKEWORD(2, 0), &wsaData) != 0) 
        return;
#endif

    sockfd=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if(sockfd < 0) {
        perror("makeSocket");
        exit(-1);
    }

    he=gethostbyname(host);
    if(!he) {
        perror("gethostbyname");
        exit(-1);
    }

    bzero(&remoteaddr, sizeof(remoteaddr));
    remoteaddr.sin_family=AF_INET;
    remoteaddr.sin_port=htons(CTFPORT);
    bcopy((char *)he->h_addr, (char *)&remoteaddr.sin_addr.s_addr,
            he->h_length);

    sendbuf[0]=SPECHELLO;
    strncpy(&sendbuf[1], "Spectator", MAXNAME);
    sendSyncMsg(MAXNAME+1);
}

int sendSyncMsg(int txbytes) {
    struct sockaddr_in rxaddr;
    int addrlen;
    int bytes=0;

    if(sendto(sockfd, sendbuf, txbytes, 0, 
                (struct sockaddr *)&remoteaddr, sizeof(remoteaddr)) < 0)
    {
        perror("sendto");
        exit(-1);
    }

    if((bytes=recvfrom(sockfd, rxbuf, sizeof(rxbuf), 0, 
                    (struct sockaddr *)&rxaddr, &addrlen)) < 0)
    {
        perror("recvfrom");
        exit(-1);
    }

    return bytes;
}

void sendMsg(int txbytes) {
    if(sendto(sockfd, sendbuf, txbytes, 0, (struct sockaddr *)&remoteaddr, 
                sizeof(remoteaddr)) < 0) {
        perror("sendto");
        exit(-1);
    }
}

void messageLoop() {
    fd_set fds;
    int rc;

    // Send ready msg to server.
    sendbuf[0]=CLIENTRDY;
    sendMsg(1);

    while(1) {
        FD_ZERO(&fds);
        FD_SET(sockfd, &fds);
        rc=select(sockfd+1, &fds, NULL, NULL, NULL);

        if(rc < 0) {
            perror("select");
            exit(-1);
        }

        if(FD_ISSET(sockfd, &fds)) {
            rc=getMessage();
            if(rc < 0) {
                fprintf(stderr, "getMessage exited.\n");
                return;
            }
        }
    }
}

int getMessage() {
    struct sockaddr_in rxaddr;
    int addrsz;
    int rc;
    uchar *msgptr;
    uchar numMsgs;
    uchar msgType;
    bool updateScreen;

    rc=recvfrom(sockfd, rxbuf, sizeof(rxbuf), 0,
            (struct sockaddr *)&rxaddr, &addrsz);
    if(rc < 0) {
        perror("recvfrom");
        return -1;
    }

    msgptr=rxbuf;
    numMsgs=*msgptr++;
    updateScreen=FALSE;
    while(numMsgs) {
        msgType=*msgptr++;

        switch(msgType) {
            case SPRITEMSG:
//                manageSprite((SpriteMsg *)msgptr);
                msgptr+=sizeof(SpriteMsg);
                break;
            case SPRITEMSG16:
                if(!updateScreen) {
                    blitBackground();
                    updateScreen=TRUE;
                }
                manageSprite((SpriteMsg16 *)msgptr);
                msgptr+=sizeof(SpriteMsg16);
                break;
            case RMSPRITEMSG:
//                removeSprite((RemoveSpriteMsg *)msgptr);
                msgptr+=sizeof(RemoveSpriteMsg);
                break;
            case VIEWPORT:
//                switchViewport((MapXY *)msgptr);
                msgptr+=sizeof(MapXY);
                break;
            case MAPMSG:
                // Map messages must be the only (or last) message
                // Make sure anything else gets dropped.
//                drawMap(msgptr);
                numMsgs=1;
                break;					
            case MESSAGEMSG:
//                setMsgArea((MessageMsg *)msgptr);
                msgptr+=sizeof(MessageMsg);
                break;
            case SCOREBOARD:
//                updateScoreboard((NumberMsg *)msgptr);
                msgptr+=sizeof(NumberMsg);
                break;
            case FLAGALERT:
//                flagAlert(*msgptr);
                msgptr++;
                break;
            case PINGMSG:
                sendbuf[0]=PINGMSG;
                sendMsg(1);
                msgptr++;
                break;
            case ENDGAMESCORE:
//                gameOver((GameEnd *)msgptr);
                msgptr+=sizeof(GameEnd);
                break;
            case PLAYERIDMSG:
                handlePlayerIdMsg((PlayerIdMsg *)msgptr);
                msgptr+=sizeof(PlayerIdMsg);
                break;
            default:
                fprintf(stderr,"Unidentified message: %x\n", msgType);
                numMsgs=1;	// dump all other msgs
        }

        numMsgs--;

    }

    if(updateScreen) {
        doneDrawing(); 
    }

    return 0;
}

