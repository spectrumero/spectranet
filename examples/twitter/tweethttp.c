/* 
 * The MIT License
 *
 * Copyright (c) 2010 Dylan Smith
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
 *
*/

#define RXBUFSZ 256

#include <http.h>
#include <sys/socket.h>
#include <stdlib.h>
#include <stdio.h>
#include "tweet.h"

int dotweet(char *user, char *passwd, char *tweet)
{
	URI tweetUri;
	int sockfd, rc, httpcode;
	int bytes, totalbytes=0;
	char rxbuf[RXBUFSZ];
	char status[32];
	char host[32];
	getAPIHost(host);

	tweetUri.proto=PROTO_HTTP;
	tweetUri.host=host;
    tweetUri.port=80;
	tweetUri.location="/1/statuses/update.json?source=twitterandroid";
	tweetUri.user=user;
	tweetUri.passwd=passwd;
	addFormData("status", tweet);

	ui_status(0, "Requesting...");
	sockfd=request(POST, &tweetUri);
	freeFormData();
	ui_status(0, "Request sent.");
	if(sockfd > 0)
	{
		rc=readHeaders(sockfd, &httpcode);
		ui_status(0, "Processing headers");
		if(rc < 0)
		{
			ui_status(rc, "Request failed");
			freeheaders();
			sockclose(sockfd);
			return rc;
		}
		while((bytes=readData(sockfd, rxbuf, RXBUFSZ-1)) > 0)
		{
			totalbytes+=bytes;
			sprintf(status, "Reading %d bytes...", totalbytes);
			ui_status(0, status);
		}
	}
	sockclose(sockfd);
	freeheaders();
	ui_status(httpcode, NULL);
	if(httpcode == 200)
		rc=0;
	else
		rc=-1;
	return rc;
}

// Get the hostname of the Twitter API (the twitter proxy in effect)
#define PAGEIN		0x3ff9
#define PAGEOUT		0x007c
#define OPEN		0x3eb1
#define READ		0x3ec9
#define CLOSE		0x3ed2

void __FASTCALL__ getAPIHost(char *buf) {
#asm
        call PAGEIN
        push hl
        ld hl, _serverfile
        ld de, O_RDONLY
        ld bc, 0x00
        call OPEN
        jr c, none
        pop de                  ; buffer to fill
        push de
        ld bc, 32		; max. 32 bytes
        push af
        call READ
        jr c, closenone
        pop af
        call CLOSE
.fixstring
        pop hl
        ld b, 32
.fixloop
        ld a, (hl)
        cp 0x20
        jr nc, nochange
        ld (hl), 0

.nochange
        inc hl
        djnz fixloop

        jr done

.closenone
        pop af
        call CLOSE
.none
        pop hl
        ld (hl), 0              ; ensure we have an empty string

.done
        call PAGEOUT
#endasm
}

#asm
._serverfile    defb 's','e','r','v','e','r','.','i','p',0
#endasm

