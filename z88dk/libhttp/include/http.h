#ifndef _HTTP
#define _HTTP
/* A simple HTTP library.
 *
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
#define GET		0
#define POST		1
#ifndef NULL
#define NULL ((void *)0)
#endif

#define PROTO_HTTP	0
#define PROTO_FTP	1
#define STR_PROTO_HTTP	"http"
#define STR_PROTO_FTP	"ftp"
#define URI_PROTOSEP	"://"
#define URI_USERPWSEP	"@"
#define URI_USERSEP	":"
#define URI_HOSTLOCSEP	"/"
#define DEFAULT_LOC	"/"

#ifndef ENOMEM
#define ENOMEM	-255
#endif

#define TIMEOUT		5000
#define EHTTP_BADPROTO	-1
#define EHTTP_BADUSERPW -2
#define EHTTP_BADURI	-3
#define EHTTP_NOHOST	-4
#define EHTTP_SOCKFAIL	-5
#define EHTTP_DNSFAIL	-6
#define EHTTP_CONNFAIL	-7
#define EHTTP_READFAIL	-8
#define EHTTP_HDRERR	-9
#define EHTTP_HDRNOTFOUND -10
#define EHTTP_BUFTOOSMALL -11
#define EHTTP_WRITEFAIL -12
#define EHTTP_NOHDREND -13
#define EHTTP_NOTHTTP	-14
#define EHTTP_NOCHUNKSIZE	-15
#define EHTTP_CONNRESET	-16
#define EHTTP_TIMEOUT 	-17
#define HDR_END		1

#define USER_AGENT	"User-Agent: ZXSpectrumHTTP/1.0\x0D\x0A"
#define ACCEPT_HDR	"Accept: */*\x0D\x0A"
#define AUTH_HDR	"Authorization: Basic "
#define CONTENT_HDR	"Content-Type: application/x-www-form-urlencoded\x0D\x0A"
#define CONTLEN_HDR	"Content-Length"
#define XFERENC_HDR	"Transfer-Encoding"
#define XFER_CHUNKED	"chunked"
#define HDR_SEP		"\x0D\x0A\x0D\x0A"
#define LINE_END		"\x0D\x0A"
#define HDR_KEYVALSEP	": "

typedef struct _uri
{
	int proto;
	char *host;
	int port;
	char *location;
	char *user;
	char *passwd;
} URI;

typedef struct _formdata
{
	char *param;
	char *data;
	struct _formdata *next;
} Formdata;

typedef struct _headerdata
{
	char *hname;
	char *hdata;
	struct _headerdata *next;
} Headerdata;


extern Formdata *formhead;
extern Formdata *formtail;
extern Headerdata *headerhead;
extern Headerdata *headertail;
extern char *headers;
extern char headersread;
extern char *hdrbuf;
extern char chunked;
extern long dataleft;
extern char *bufptr;
extern int bufleft;
extern char *headerbuf;

extern int __LIB__	request(int type, URI *uri);
extern int __LIB__	addStdHeaders(char *hdrbuf, URI *uri, int bufsz);
extern int __LIB__	readHeaders(int sockfd, int *httpcode);
extern int __LIB__	readData(int sockfd, char *buf, int bufsz);
extern char __LIB__ *getHeaders(int sockfd, int *remainsz, int *result);
extern char __LIB__ *getSingleHeader(char *hdrbuf, int *result);
extern Headerdata __LIB__ *getheader(char *header);
extern void __LIB__	freeheaders();
extern void __LIB__	addFormData(char *param, char *data);
extern void __LIB__	freeFormData();
extern int __LIB__	readResponse(char *buf, int bufsz);
extern int __LIB__	parseURI(URI *parsed, char *uri);
extern int __LIB__	parseProto(char *proto, int protosz);
extern void __LIB__	freeUriElements(URI *uri);
extern int __LIB__	allocateUriElements
				(URI *uri, int proto, char *host,
				 char *loc, char *user, char *pw);
extern int __LIB__	postsize();
extern void __LIB__ __CALLEE__ base64enc(char *dst, char *src, unsigned int sz);
extern int __LIB__	htrecv(int sockfd, char *buf, int buflen, int to);
extern int __LIB__	htpoll(int sockfd, int to);



#endif
