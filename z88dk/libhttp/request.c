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
#include <netdb.h>
#include <stdio.h>
#include <string.h>
#include <malloc.h>

Formdata *formhead=NULL; 
Formdata *formtail=NULL; 

char headersread=0;

#define HDRBUFSZ	512

int request(int type, URI *uri)
{
	int sockfd, bytes;
	struct sockaddr_in remoteaddr;
	struct hostent *he;
	char *authstring;
	char hdrbuf[HDRBUFSZ];
	char csizebuf[8];
	char tmpbuf[120];
	Formdata *fptr;

	headersread=0;

	he=gethostbyname(uri->host);
	if(!he) return EHTTP_DNSFAIL;

	sockfd=socket(AF_INET, SOCK_STREAM, 0);
	if(sockfd < 0) return EHTTP_SOCKFAIL;

	/* TODO: implement arbitrary ports for http */
	remoteaddr.sin_port=htons(uri->port);
	remoteaddr.sin_addr.s_addr=he->h_addr;
	if(connect(sockfd, &remoteaddr, sizeof(struct sockaddr_in)) < 0)
	{
		sockclose(sockfd);
		return EHTTP_CONNFAIL;
	}

	if(type == GET)
	{
		sprintf(hdrbuf, "GET %s HTTP/1.1\x0D\x0A", uri->location);
		addStdHeaders(hdrbuf, uri, HDRBUFSZ);
		strlcat(hdrbuf, LINE_END, HDRBUFSZ);
		bytes=send(sockfd, hdrbuf, strlen(hdrbuf), 0);
		if(bytes < 0)
			return EHTTP_WRITEFAIL;
	}
	else
	{
		sprintf(hdrbuf, "POST %s HTTP/1.1\x0D\x0A", uri->location);
		addStdHeaders(hdrbuf, uri, HDRBUFSZ);

		/* make up the Content-Length header */
		/* TODO: Proper addition of headers, not this hideous
		 * function */
		strlcat(hdrbuf, CONTLEN_HDR, HDRBUFSZ);
		strlcat(hdrbuf, ": ", HDRBUFSZ);
		sprintf(csizebuf, "%d\x0D\x0A", postsize());
		strlcat(hdrbuf, csizebuf, HDRBUFSZ);

		strlcat(hdrbuf, CONTENT_HDR, HDRBUFSZ);
		strlcat(hdrbuf, LINE_END, HDRBUFSZ);

		/* send what we have now. The reason being is that
		 * POST headers can be rather long, with many options */
/*		bytes=send(sockfd, hdrbuf, strlen(hdrbuf), 0);
		if(bytes < 0)
			return EHTTP_WRITEFAIL; */
		
		/* now the form data */
		fptr=formhead;
		while(fptr)
		{
			/*
			sprintf(hdrbuf, "%s=%s\x0D\x0A",
					fptr->param,
					fptr->data);
			printf("SENDING: %s", hdrbuf);
			bytes=send(sockfd, hdrbuf, strlen(hdrbuf), 0);
			if(bytes < 0)
				return EHTTP_WRITEFAIL;*/
			if(fptr->next)
			{
				sprintf(tmpbuf, "%s=%s&",
					fptr->param,
					fptr->data);
			}
			else
			{
				sprintf(tmpbuf, "%s=%s\x0D\x0A",
					fptr->param,
					fptr->data);
			}
			strlcat(hdrbuf, tmpbuf, HDRBUFSZ);
			fptr=fptr->next;
		}
		bytes=send(sockfd, hdrbuf, strlen(hdrbuf), 0);
		if(bytes < 0)
			return EHTTP_WRITEFAIL; 
	}
	return sockfd;
}

int addStdHeaders(char *hdrbuf, URI *uri, int bufsz)
{
	char *authstr, *auth64buf;
	int authlen;
	if(uri->user)
	{
		authlen=strlen(uri->user)+strlen(uri->passwd)+2;
		authstr=(char *)malloc(authlen);
		if(!authstr) return ENOMEM;

		sprintf(authstr, "%s:%s", uri->user, uri->passwd);
		auth64buf=(char *)malloc(authlen+(authlen/2));
		if(!auth64buf) return ENOMEM;

		base64enc(auth64buf, authstr, authlen-1);
		strlcat(hdrbuf, AUTH_HDR, bufsz);
		strlcat(hdrbuf, auth64buf, bufsz);
		strlcat(hdrbuf, LINE_END, bufsz);
		free(authstr);
		free(auth64buf);
	}
		
	strlcat(hdrbuf, USER_AGENT, bufsz);
	strlcat(hdrbuf, ACCEPT_HDR, bufsz);
	strlcat(hdrbuf, "Host: ", bufsz);
	strlcat(hdrbuf, uri->host, bufsz);
	strlcat(hdrbuf, LINE_END, bufsz);
	return 0;
}

