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

#include <http.h>
#include <sys/socket.h>
#include <string.h>
#include <malloc.h>
#include <stdlib.h>
#include <stdio.h> /* debug */

static Headerdata *headerhead=NULL;
static Headerdata *headertail=NULL;
static char *headerbuf=NULL;
static char chunked=0;
static long dataleft=0;
static int bufleft=0;
static char *bufptr=NULL;

int readData(int sockfd, char *buf, int bufsz)
{
	int result, bytestoget, bufbytestoget;
	int bytes=0, rcvbytes;

	/* deal with anything remaining in the header buf */
	if(bufleft)
	{
		if(bufleft > dataleft)
			bufbytestoget=dataleft;
		else
			bufbytestoget=bufleft;

		if(bufbytestoget > bufsz)
		{
			memcpy(buf, bufptr, bufsz);
			bufleft -= bufsz;
			dataleft -= bufsz;
			bufptr += bufsz;
			return bufsz;
		}
		else
		{
			memcpy(buf, bufptr, bufbytestoget);
			dataleft -= bufbytestoget;

			bufsz -= bufbytestoget;
			bytes += bufbytestoget;
			buf += bufbytestoget;
			bufleft=0;
		}
	}

 	/* only do anything if there's anything to do */
	if(dataleft < 1)
		return bytes;
	if(bufsz > dataleft)
		bytestoget=dataleft;
	else
		bytestoget=bufsz;


	rcvbytes=htrecv(sockfd, buf, bytestoget, TIMEOUT);
	if(rcvbytes < 1)
		return rcvbytes;

	dataleft -= rcvbytes;
	if(rcvbytes > 0)
		return rcvbytes+bytes;
	return EHTTP_READFAIL;
}

