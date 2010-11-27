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

#define HDRBUFSZ	1400

int readHeaders(int sockfd, int *httpcode)
{
	char *end, *httpcodestr;
	int result;

	dataleft=0;
	chunked=0;
	*httpcode=0;
	bufptr=getHeaders(sockfd, &bufleft, &result);

	/* getHeaders should return zero if all OK */
	if(result != 0)
		return result;

	/* find out bytes remaining if encoding is chunked */
	/* TODO: deal with this if the buffer gets cut in half */
	if(chunked)
	{
		if((end=strstr(bufptr, LINE_END)))
		{
			*end=0;
			dataleft=strtol(bufptr, NULL, 16);
			bufleft -= (end-bufptr)+2;
			bufptr=end+2;
		}
		else
		{
			return EHTTP_NOCHUNKSIZE;
		}
	}

	/* set HTTP code */
	httpcodestr=strstr(headerbuf, " ");
	if(!httpcodestr)
		return EHTTP_NOTHTTP;
	*(httpcodestr+4)=0;
	*httpcode=atoi(httpcodestr);
	return 0;
}

char *getHeaders(int sockfd, int *remainsz, int *result)
{
	int bytes, hremain;
	char *hdrptr, *hend;
	
	if(headerbuf == NULL)
	{
		headerbuf=(char *)malloc(HDRBUFSZ);
		if(!headerbuf)
		{
			*result=ENOMEM;
			return NULL;
		}
	}
	hdrptr=headerbuf;
	hremain=HDRBUFSZ-1;

	while(1)
	{
		bytes=htrecv(sockfd, hdrptr, hremain, TIMEOUT);
		if(bytes < 1)
		{
			*result=bytes;
			return NULL;
		}
		hdrptr+=bytes;
		*hdrptr=0;
		hremain-=bytes;

		/* could be more efficient but for the sake of simplicity
		 * if the header end is split over two packets just check
		 * the whole thing */
		if(strstr(headerbuf, HDR_SEP))
		{
			break;
		}
		if(hremain < 1)
		{
			*result=EHTTP_NOHDREND;
			return NULL;
		}
	}

	/* put a NULL at the first separator, and advance the header
	 * pointer to this point, so the HTTP/1.1 200 etc is passed */
	hdrptr=strstr(headerbuf, LINE_END);
	if(!hdrptr)
	{
		*result=EHTTP_NOTHTTP;
		return NULL;
	}

	*hdrptr=0;
	hdrptr+=2;	/* advance past the \n\r */

	/* iterate through all the headers we have */
	while(hdrptr=getSingleHeader(hdrptr, result))
	{
		/* If hdrptr is valid no errors have (yet)
		 * occurred */
		if(*result == HDR_END)
		{
				/* all headers have been processed */
				headersread=1;
				*result=0;
				*remainsz=strlen(hdrptr);
				return hdrptr;
		}
		else if(*result)
		{
			/* headers probably won't fit in the buffer */
			*result=EHTTP_HDRERR;
			return NULL;
		}
	}

	/* ran out of data without all the headers */
	*result=EHTTP_HDRERR;
	return NULL;
}

char *getSingleHeader(char *hdrbuf, int *result)
{
	char *sep, *end;
	Headerdata *hdr;

	/* first see if there's a header to get */
	if((end=strstr(hdrbuf, LINE_END)))
	{
		if(end == hdrbuf)
		{
			*result=HDR_END;
			return hdrbuf+2;
		}

		sep=strstr(hdrbuf, HDR_KEYVALSEP);
		if(sep)
		{
			hdr=(Headerdata *)malloc(sizeof(Headerdata));
			if(!hdr)
			{
				*result=ENOMEM;
				return NULL;
			}

			hdr->hname=hdrbuf;
			*sep=NULL;
			hdr->hdata=sep+2;
			*end=NULL;


			/* a couple of headers that always must
			 * be examined */
			if(!strcmp(hdr->hname, CONTLEN_HDR))
			{
				dataleft=strtol(hdr->hdata, NULL, 0);
			}
			if(!strcmp(hdr->hname, XFERENC_HDR) &&
			   !strcmp(hdr->hdata, XFER_CHUNKED))
			{
				chunked=1;
			}
				
			headertail->next=hdr;
			headertail=hdr;
			
			*result=0;
			return end+2; 
		}
	}
	*result=EHTTP_NOHDREND;
	return hdrbuf;
}

