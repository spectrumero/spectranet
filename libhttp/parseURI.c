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
 * Simple URI parser
*/
#include <malloc.h>
#include <string.h>
#include <http.h>

int parseURI(URI *parsed, char *uri)
{
	char *strptr, *passptr;
	int sz, usersz, passsz;

	/* check for something to parse */
	if(strlen(uri) == 0)
		return EHTTP_BADURI;

	/* initialize URI structure */
	memset(parsed, 0, sizeof(URI));

	/* search for a host, put in the default if not present */
	if((strptr=strstr(uri, URI_PROTOSEP)))
	{
		parsed->proto=parseProto(uri, (int)(strptr-uri));
		if(parsed->proto < 0)
			return parsed->proto;
		uri=strptr+sizeof(URI_PROTOSEP)-1;
	}
	else
	{
		parsed->proto=PROTO_HTTP;
	}

	/* look for the user/passwd separator */
	if((strptr=strstr(uri, URI_USERPWSEP)))
	{
		passptr=strstr(uri, URI_USERSEP);
		if(!passptr)
		{
			/* parse error - no user/pw separator */
			return EHTTP_BADUSERPW;
		}
		usersz=(int)(passptr-uri)+1;
		passsz=(int)(strptr-passptr);
		parsed->user=(char *)malloc(usersz);
		parsed->passwd=(char *)malloc(passsz);
		if(!parsed->user || !parsed->passwd)
			return ENOMEM;
		strlcpy(parsed->user, uri, usersz);
		strlcpy(parsed->passwd, passptr+1, passsz);
		uri=strptr+1;
	}

	/* at this point we should have at least a host, look for
	 * a separator between host and the remainder */
	if((strptr=strstr(uri, URI_HOSTLOCSEP)))
	{
		if(strptr > uri)
		{
			sz=(int)(strptr-uri)+1;
			parsed->host=(char *)malloc(sz);
			if(!parsed->host)
				return ENOMEM;
			strlcpy(parsed->host, uri, sz);
			uri=strptr;
		}
		else
		{
			/* freeUriElements(parsed); */
			return EHTTP_NOHOST;
		}
	}

	/* the remainder should go into the location */
	sz=strlen(uri);
	if(sz)
	{
		parsed->location=(char *)malloc(sz+1);
		if(!parsed->location)
			return ENOMEM;
		strlcpy(parsed->location, uri, sz+1);
	}
	else
	{
		parsed->location=(char *)malloc(sizeof(DEFAULT_LOC));
		if(!parsed->location)
			return ENOMEM;
		strlcpy(parsed->location, DEFAULT_LOC, sizeof(DEFAULT_LOC));
	}
	return 0;
}

