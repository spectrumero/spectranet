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
#include <unistd.h>

#include "tnfs.h"
#include "config.h"
#include "directory.h"
#include "tnfs_file.h"
#include "datagram.h"
#include "errortable.h"
#include "bsdcompat.h"
#include "endian.h"

char root[MAX_ROOT]; /* root for all operations */
char dirbuf[MAX_FILEPATH];

int tnfs_setroot(char *rootdir)
{
	if (strlen(rootdir) > MAX_ROOT)
		return -1;

	strlcpy(root, rootdir, MAX_ROOT);
	return 0;
}

/* validates a path points to an actual directory */
int validate_dir(Session *s, const char *path)
{
	char fullpath[MAX_TNFSPATH];
	struct stat dirstat;
	get_root(s, fullpath, MAX_TNFSPATH);

	/* relative paths are always illegal in tnfs messages */
	if (strstr(fullpath, "../") != NULL)
		return -1;

	normalize_path(fullpath, fullpath, MAX_TNFSPATH);
#ifdef DEBUG
	fprintf(stderr, "validate_dir: Path='%s'\n", fullpath);
#endif

	/* check we have an actual directory */
	if (stat(fullpath, &dirstat) == 0)
	{
		if (S_ISDIR(dirstat.st_mode))
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
	if (s->root == NULL)
	{
		snprintf(buf, bufsz, "%s/", root);
	}
	else
	{
		snprintf(buf, bufsz, "%s/%s/", root, s->root);
	}
}

/* normalize paths, remove multiple delimiters 
 * the new path at most will be exactly the same as the old
 * one, and if the path is modified it will be shorter so
 * doing "normalize_path(buf, buf, sizeof(buf)) is fine */
void normalize_path(char *newbuf, char *oldbuf, int bufsz)
{
	/* normalize the directory delimiters. Windows of course
	 * has problems with multiple delimiters... */
	int count = 0;
	int slash = 0;
#ifdef WIN32
	char *nbstart = newbuf;
#endif

	while (*oldbuf && count < bufsz - 1)
	{
		/* ...convert backslashes, too */
		if (*oldbuf != '/')
		{
			slash = 0;
			*newbuf++ = *oldbuf++;
		}
		else if (!slash && (*oldbuf == '/' || *oldbuf == '\\'))
		{
			*newbuf++ = '/';
			oldbuf++;
			slash = 1;
		}
		else if (slash)
		{
			oldbuf++;
		}
	}

	/* guarantee null termination */
	*newbuf = 0;

	/* remove a standalone trailing slash, it can cause problems
	 * with Windows, except for cases of "C:/" where it is
	 * mandatory */
#ifdef WIN32
	if (*(newbuf - 1) == '/' && strlen(nbstart) > 3)
		*(newbuf - 1) = 0;
#endif
}

/* Open a directory */
void tnfs_opendir(Header *hdr, Session *s, unsigned char *databuf, int datasz)
{
	DIR *dptr;
	char path[MAX_TNFSPATH];
	unsigned char reply[2];
	int i;

	if (*(databuf + datasz - 1) != 0)
	{
#ifdef DEBUG
		fprintf(stderr, "Invalid dirname: no NULL\n");
#endif
		/* no null terminator */
		hdr->status = TNFS_EINVAL;
		tnfs_send(s, hdr, NULL, 0);
		return;
	}

#ifdef DEBUG
	fprintf(stderr, "opendir: %s\n", databuf);
#endif

	/* find the first available slot in the session */
	for (i = 0; i < MAX_DHND_PER_CONN; i++)
	{
		if (s->dhnd[i] == NULL)
		{
			snprintf(path, MAX_TNFSPATH, "%s/%s/%s",
					 root, s->root, databuf);
			normalize_path(s->dpaths[i], path, MAX_TNFSPATH);
			if ((dptr = opendir(s->dpaths[i])) != NULL)
			{
				s->dhnd[i] = dptr;

				/* send OK response */
				hdr->status = TNFS_SUCCESS;
				reply[0] = (unsigned char)i;
				tnfs_send(s, hdr, reply, 1);
			}
			else
			{
				hdr->status = tnfs_error(errno);
				tnfs_send(s, hdr, NULL, 0);
			}

			/* done what is needed, return */
			return;
		}
	}

	/* no free handles left */
	hdr->status = TNFS_EMFILE;
	tnfs_send(s, hdr, NULL, 0);
}

/* Read a directory entry */
void tnfs_readdir(Header *hdr, Session *s, unsigned char *databuf, int datasz)
{
	struct dirent *entry;
	char reply[MAX_FILENAME_LEN];

	if (datasz != 1 ||
		*databuf > MAX_DHND_PER_CONN ||
		s->dhnd[*databuf] == NULL)
	{
		hdr->status = TNFS_EBADF;
		tnfs_send(s, hdr, NULL, 0);
		return;
	}

	entry = readdir(s->dhnd[*databuf]);
	if (entry)
	{
		strlcpy(reply, entry->d_name, MAX_FILENAME_LEN);
		hdr->status = TNFS_SUCCESS;
		tnfs_send(s, hdr, (unsigned char *)reply, strlen(reply) + 1);
	}
	else
	{
		hdr->status = TNFS_EOF;
		tnfs_send(s, hdr, NULL, 0);
	}
}

/* Close a directory */
void tnfs_closedir(Header *hdr, Session *s, unsigned char *databuf, int datasz)
{
	if (datasz != 1 ||
		*databuf > MAX_DHND_PER_CONN ||
		s->dhnd[*databuf] == NULL)
	{
		hdr->status = TNFS_EBADF;
		tnfs_send(s, hdr, NULL, 0);
		return;
	}

	closedir(s->dhnd[*databuf]);
	s->dhnd[*databuf] = 0;
	s->dpaths[*databuf][0] = '\0';
	hdr->status = TNFS_SUCCESS;
	tnfs_send(s, hdr, NULL, 0);
}

/* Make a directory */
void tnfs_mkdir(Header *hdr, Session *s, unsigned char *buf, int bufsz)
{
	if (*(buf + bufsz - 1) != 0 ||
		tnfs_valid_filename(s, dirbuf, (char *)buf, bufsz) < 0)
	{
		hdr->status = TNFS_EINVAL;
		tnfs_send(s, hdr, NULL, 0);
	}
	else
	{
#ifdef WIN32
		if (mkdir(dirbuf) == 0)
#else
		if (mkdir(dirbuf, 0755) == 0)
#endif
		{
			hdr->status = TNFS_SUCCESS;
			tnfs_send(s, hdr, NULL, 0);
		}
		else
		{
			hdr->status = tnfs_error(errno);
			tnfs_send(s, hdr, NULL, 0);
		}
	}
}

/* Remove a directory */
void tnfs_rmdir(Header *hdr, Session *s, unsigned char *buf, int bufsz)
{
	if (*(buf + bufsz - 1) != 0 ||
		tnfs_valid_filename(s, dirbuf, (char *)buf, bufsz) < 0)
	{
		hdr->status = TNFS_EINVAL;
		tnfs_send(s, hdr, NULL, 0);
	}
	else
	{
		if (rmdir(dirbuf) == 0)
		{
			hdr->status = TNFS_SUCCESS;
			tnfs_send(s, hdr, NULL, 0);
		}
		else
		{
			hdr->status = tnfs_error(errno);
			tnfs_send(s, hdr, NULL, 0);
		}
	}
}

void tnfs_seekdir(Header *hdr, Session *s, unsigned char *databuf, int datasz)
{
	int32_t pos;

	if (datasz != 1 ||
		*databuf > MAX_DHND_PER_CONN ||
		s->dhnd[*databuf] == NULL)
	{
		hdr->status = TNFS_EBADF;
		tnfs_send(s, hdr, NULL, 0);
		return;
	}

	// Seekdir's API is brain damaged, it has no way to return an error.
	// perhaps a subsequent call to telldir might be prudent?

	pos = (int32_t)tnfs32uint(databuf + 2);
	seekdir(s->dhnd[*databuf], pos); // Returns no value.

	hdr->status = TNFS_SUCCESS;
	tnfs_send(s, hdr, NULL, 0);
}

void tnfs_telldir(Header *hdr, Session *s, unsigned char *databuf, int datasz)
{
	int32_t pos;

	if (datasz != 1 ||
		*databuf > MAX_DHND_PER_CONN ||
		s->dhnd[*databuf] == NULL)
	{
		hdr->status = TNFS_EBADF;
		tnfs_send(s, hdr, NULL, 0);
		return;
	}

	pos = telldir(s->dhnd[*databuf]);

	tnfs_send(s, hdr, (unsigned char *)&pos, sizeof(pos));
}

/* Read a directory entry and provide extended results */
void tnfs_readdirx(Header *hdr, Session *s, unsigned char *databuf, int datasz)
{
	struct dirent *entry;
	/*
	We're returning:
	flags - 1 byte: Flags providing additional information about the file (see below)
	size  - 4 bytes: Unsigned 32 bit little endian size of file in bytes
	mtime - 4 bytes: Modification time in seconds since the epoch, little endian
	ctime - 4 bytes: Creation time in seconds since the epoch, little endian
	entry - X bytes: Zero-terminated string providing directory entry path
*/
	struct _readdirx_ent
	{
		uint8_t flags;
		uint32_t size;
		uint32_t mtime;
		uint32_t ctime;
		char entrypath[MAX_FILENAME_LEN];
	} __attribute__((packed));

	int replyheaderlen = sizeof(uint8_t) + (sizeof(uint32_t) * 3);

	struct _readdirx_ent reply = {
		.flags = 0,
		.size = 0,
		.mtime = 0,
		.ctime = 0,
		.entrypath = {'\0'}};

	// databuf holds our directory handle: check it
	if (datasz != 1 ||
		*databuf > MAX_DHND_PER_CONN ||
		s->dhnd[*databuf] == NULL)
	{
		hdr->status = TNFS_EBADF;
		tnfs_send(s, hdr, NULL, 0);
		return;
	}

	struct stat statinfo;
	char statpath[MAX_TNFSPATH];
	entry = readdir(s->dhnd[*databuf]);
	if (entry)
	{

#ifdef WIN32
#define PATH_SEP '\\'
#else
#define PATH_SEP '/'
#endif
		snprintf(statpath, sizeof(statpath), "%s%c%s", s->dpaths[*databuf], PATH_SEP, entry->d_name);
		
		// Try to get the additional details we want to include
		if (stat(statpath, &statinfo) == 0)
		{
			uint32tnfs((unsigned char *)&reply.size, statinfo.st_size);
			uint32tnfs((unsigned char *)&reply.mtime, statinfo.st_mtime);
			uint32tnfs((unsigned char *)&reply.ctime, statinfo.st_ctime);

			if (S_ISDIR(statinfo.st_mode))
			{
				reply.flags |= TNFS_DIRENTRY_DIR;
			}
		}

		int pathlen = strlcpy(reply.entrypath, entry->d_name, MAX_FILENAME_LEN);
		hdr->status = TNFS_SUCCESS;

		tnfs_send(s, hdr, (unsigned char *)&reply, replyheaderlen + pathlen + 1);
	}
	else
	{
		hdr->status = TNFS_EOF;
		tnfs_send(s, hdr, NULL, 0);
	}
}

/* Open a directory with additional options */
void tnfs_opendirx(Header *hdr, Session *s, unsigned char *databuf, int datasz)
{
	DIR *dptr;
	char path[MAX_TNFSPATH];
	unsigned char reply[2];
	int i;

	if (*(databuf + datasz - 1) != 0)
	{
#ifdef DEBUG
		fprintf(stderr, "Invalid dirname: no NULL\n");
#endif
		/* no null terminator */
		hdr->status = TNFS_EINVAL;
		tnfs_send(s, hdr, NULL, 0);
		return;
	}

#ifdef DEBUG
	fprintf(stderr, "opendir: %s\n", databuf);
#endif

	/* find the first available slot in the session */
	for (i = 0; i < MAX_DHND_PER_CONN; i++)
	{
		if (s->dhnd[i] == NULL)
		{
			snprintf(path, MAX_TNFSPATH, "%s/%s/%s",
					 root, s->root, databuf);
			normalize_path(path, path, MAX_TNFSPATH);
			if ((dptr = opendir(path)) != NULL)
			{
				s->dhnd[i] = dptr;

				/* send OK response */
				hdr->status = TNFS_SUCCESS;
				reply[0] = (unsigned char)i;
				tnfs_send(s, hdr, reply, 1);
			}
			else
			{
				hdr->status = tnfs_error(errno);
				tnfs_send(s, hdr, NULL, 0);
			}

			/* done what is needed, return */
			return;
		}
	}

	/* no free handles left */
	hdr->status = TNFS_EMFILE;
	tnfs_send(s, hdr, NULL, 0);
}
