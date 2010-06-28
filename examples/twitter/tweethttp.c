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

	tweetUri.proto=PROTO_HTTP;
	tweetUri.host="api.twitter.com";
	tweetUri.location="/1/statuses/update.json";
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

