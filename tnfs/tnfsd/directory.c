/* The MIT License
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
 * TNFS daemon datagram handler
 *
 * */

#include <stdio.h>
#include <dirent.h>
#include <sys/stat.h>
#include <string.h>
#include <errno.h>

#include "tnfs.h"
#include "config.h"
#include "directory.h"
#include "datagram.h"
#include "errortable.h"

char root[MAX_ROOT];	/* root for all operations */

int tnfs_setroot(char *rootdir)
{
	if(strlen(rootdir) > MAX_ROOT)
		return -1;

	strlcpy(root, rootdir, MAX_ROOT);
	return 0;
}	

/* validates a path points to an actual directory */
int validate_dir(Session *s, const char *path)
{
	char fullpath[MAX_PATH];
	struct stat dirstat;
	get_root(s, fullpath, MAX_PATH);
#ifdef DEBUG
	fprintf(stderr, "validate_dir: Path='%s'\n", fullpath);
#endif

	/* relative paths are always illegal in tnfs messages */
	if(strstr(fullpath, "../") != NULL)
		return -1;

	/* check we have an actual directory */
	if(stat(fullpath, &dirstat) == 0)
	{
		if(dirstat.st_mode & S_IFDIR)
		{
#ifdef DEBUG
			fprintf(stderr, "validate_dir: Directory OK\n");
#endif
			return 0;
		}
	}

	/* stat failed */
	return -1;
}

/* get the root directory for the given session */
void get_root(Session *s, char *buf, int bufsz)
{
	snprintf(buf, bufsz, "%s/%s/", root, s->root);
}

/* Open a directory */
void tnfs_opendir(Header *hdr, Session *s, unsigned char *databuf, int datasz)
{
	DIR *dptr;
	char path[MAX_PATH];
	unsigned char reply[2];
	int i;

	if(*(databuf+datasz-1) != 0)
	{
#ifdef DEBUG
		fprintf(stderr,"Invalid dirname: no NULL\n");
#endif
		/* no null terminator */
		hdr->status=TNFS_ENOENT;
		tnfs_send(s, hdr, NULL, 0);
		return;
	}

#ifdef DEBUG
	fprintf(stderr, "opendir: %s\n", databuf);
#endif

	/* find the first available slot in the session */
	for(i=0; i<MAX_DHND_PER_CONN; i++)
	{
		if(s->dhnd[i]==NULL)
		{
			snprintf(path, MAX_PATH, "%s/%s/%s", 
					root, s->root, databuf);
			if((dptr=opendir(path)) != NULL)
			{
				s->dhnd[i]=dptr;

				/* send OK response */
				hdr->status=TNFS_SUCCESS;
				reply[0]=(unsigned char)i;
				tnfs_send(s, hdr, reply, 1);
			}
			else
			{
				hdr->status=tnfs_error(errno);
				tnfs_send(s, hdr, NULL, 0);
			}
			
			/* done what is needed, return */
			return;
		}
	}

	/* no free handles left */
	hdr->status=TNFS_EMFILE;
	tnfs_send(s, hdr, NULL, 0);
}

/* Read a directory entry */
void tnfs_readdir(Header *hdr, Session *s, unsigned char *databuf, int datasz)
{
	struct dirent *entry;
	char reply[MAX_FILENAME_LEN];

	fprintf(stderr, "datasz=%d *databuf=%d\n", datasz, *databuf);
	if(datasz != 1 || 
	  *databuf > MAX_DHND_PER_CONN || 
	  s->dhnd[*databuf] == NULL)
	{
		hdr->status=TNFS_EBADF;
		tnfs_send(s, hdr, NULL, 0);
		return;
	}

	entry=readdir(s->dhnd[*databuf]);
	if(entry)
	{
		strlcpy(reply, entry->d_name, MAX_FILENAME_LEN);
		hdr->status=TNFS_SUCCESS;
		tnfs_send(s, hdr, (unsigned char *)reply, strlen(reply)+1);
	}
	else
	{
		hdr->status=TNFS_EOF;
		tnfs_send(s, hdr, NULL, 0);
	}
}

/* Close a directory */
void tnfs_closedir(Header *hdr, Session *s, unsigned char *databuf, int datasz)
{
        if(datasz != 1 || 
          *databuf > MAX_DHND_PER_CONN || 
          s->dhnd[*databuf] == NULL)         
        {                                    
                hdr->status=TNFS_EBADF;           
                tnfs_send(s, hdr, NULL, 0);  
		return;
	}

	closedir(s->dhnd[*databuf]);
	s->dhnd[*databuf]=0;
	hdr->status=TNFS_SUCCESS;
	tnfs_send(s, hdr, NULL, 0);
}

