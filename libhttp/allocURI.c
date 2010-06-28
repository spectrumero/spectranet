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

#include <malloc.h>
#include <http.h>

int allocateUriElements(URI *uri, 
		int proto, char *host, char *loc, char *user, char *pw)
{
	int sz;

	memset(uri, 0, sizeof(URI));
	uri->proto=proto;
	if(host)
	{
		sz=strlen(host)+1;
		uri->host=(char *)malloc(sz);
		if(!uri->host)
			return ENOMEM;
		strlcpy(uri->host, host, sz);
	}
	if(loc)
	{
		sz=strlen(loc)+1;
		uri->location=(char *)malloc(sz);
		if(!uri->location)
		{
			freeUriElements(uri);
			return ENOMEM;
		}
	}
	if(user)
	{
		sz=strlen(user)+1;
		uri->user=(char *)malloc(sz);
		if(!uri->user)
		{
			freeUriElements(uri);
			return ENOMEM;
		}
	}
	if(pw)
	{
		sz=strlen(pw)+1;
		uri->passwd=(char *)malloc(sz);
		if(!uri->passwd)
		{
			freeUriElements(uri);
			return ENOMEM;
		}
	}
	return 0;
}

