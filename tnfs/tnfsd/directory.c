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

#ifdef WIN32
#define PATH_SEP '\\'
#else
#define PATH_SEP '/'
#endif

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
		if (s->dhandles[i].handle == NULL)
		{
			snprintf(path, MAX_TNFSPATH, "%s/%s/%s",
					 root, s->root, databuf);
			normalize_path(s->dhandles[i].path, path, MAX_TNFSPATH);
			if ((dptr = opendir(s->dhandles[i].path)) != NULL)
			{
				s->dhandles[i].handle = dptr;

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
		s->dhandles[*databuf].handle == NULL)
	{
		hdr->status = TNFS_EBADF;
		tnfs_send(s, hdr, NULL, 0);
		return;
	}

	entry = readdir(s->dhandles[*databuf].handle);
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
		s->dhandles[*databuf].handle == NULL)
	{
		hdr->status = TNFS_EBADF;
		tnfs_send(s, hdr, NULL, 0);
		return;
	}

	closedir(s->dhandles[*databuf].handle);

	s->dhandles[*databuf].handle = NULL;
	s->dhandles[*databuf].path[0] = '\0';
	dirlist_free(s->dhandles[*databuf].entry_list);
	s->dhandles[*databuf].current_entry = s->dhandles[*databuf].entry_list = NULL;
	s->dhandles[*databuf].entry_count = 0;

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
	uint32_t pos;

	// databuf holds our directory handle
	// followed by 4 bytes for the new position
	if (datasz != 5 ||
		*databuf > MAX_DHND_PER_CONN ||
		s->dhandles[*databuf].handle == NULL)
	{
		hdr->status = TNFS_EBADF;
		tnfs_send(s, hdr, NULL, 0);
		return;
	}

	pos = tnfs32uint(databuf + 1);
#ifdef DEBUG
	fprintf(stderr, "tnfs_seekdir to pos %u\n", pos);
#endif
	// We handle this differently depending on whether we've pre-loaded the directory or not
	if(s->dhandles[*databuf].entry_list == NULL)
	{
		seekdir(s->dhandles[*databuf].handle, (long)pos);
	}
	else
	{
		s->dhandles[*databuf].current_entry = dirlist_get_node_at_index(s->dhandles[*databuf].entry_list, pos);
	}

	hdr->status = TNFS_SUCCESS;
	tnfs_send(s, hdr, NULL, 0);
}

void tnfs_telldir(Header *hdr, Session *s, unsigned char *databuf, int datasz)
{
	int32_t pos;

	// databuf holds our directory handle: check it
	if (datasz != 1 ||
		*databuf > MAX_DHND_PER_CONN ||
		s->dhandles[*databuf].handle == NULL)
	{
		hdr->status = TNFS_EBADF;
		tnfs_send(s, hdr, NULL, 0);
		return;
	}

	// We handle this differently depending on whether we've pre-loaded the directory or not
	if(s->dhandles[*databuf].entry_list == NULL)
	{
		pos = telldir(s->dhandles[*databuf].handle);
	}
	else
	{
		pos = dirlist_get_index_for_node(s->dhandles[*databuf].entry_list, s->dhandles[*databuf].current_entry);
	}

#ifdef DEBUG
	fprintf(stderr, "tnfs_telldir returning %d\n", pos);
#endif

	hdr->status = TNFS_SUCCESS;
	uint32tnfs((unsigned char *)&pos, (uint32_t)pos);

	tnfs_send(s, hdr, (unsigned char *)&pos, sizeof(pos));
}

/* Read a directory entry and provide extended results */
void tnfs_readdirx(Header *hdr, Session *s, unsigned char *databuf, int datasz)
{
	/*
	We're returning:
	flags - 1 byte: Flags providing additional information about the file (see below)
	size  - 4 bytes: Unsigned 32 bit little endian size of file in bytes
	mtime - 4 bytes: Modification time in seconds since the epoch, little endian
	ctime - 4 bytes: Creation time in seconds since the epoch, little endian
	entry - X bytes: Zero-terminated string providing directory entry path
*/
	directory_entry reply = {
		.flags = 0,
		.size = 0,
		.mtime = 0,
		.ctime = 0,
		.entrypath = {'\0'}};

	int replyheaderlen = sizeof(uint8_t) + (sizeof(uint32_t) * 3);

	// databuf holds our directory handle: check it
	if (datasz != 1 ||
		*databuf > MAX_DHND_PER_CONN ||
		s->dhandles[*databuf].handle == NULL)
	{
		hdr->status = TNFS_EBADF;
		tnfs_send(s, hdr, NULL, 0);
		return;
	}

	dir_handle *dh = &s->dhandles[*databuf];
	directory_entry *entry;

	if (dh->current_entry)
	{
		entry = &dh->current_entry->entry;

		reply.flags = entry->flags;
		uint32tnfs((unsigned char *)&reply.size, entry->size);
		uint32tnfs((unsigned char *)&reply.mtime, entry->mtime);
		uint32tnfs((unsigned char *)&reply.ctime, entry->ctime);

		int pathlen = strlcpy(reply.entrypath, entry->entrypath, MAX_FILENAME_LEN);
		hdr->status = TNFS_SUCCESS;

		// Point to the next entry
		dh->current_entry = dh->current_entry->next;

		tnfs_send(s, hdr, (unsigned char *)&reply, replyheaderlen + pathlen + 1);
	}
	else
	{
		hdr->status = TNFS_EOF;
		tnfs_send(s, hdr, NULL, 0);
	}
}

/* Returns errno on failure, otherwise zero */
int _load_directory(dir_handle *dirh)
{
	struct dirent *entry;
	struct stat statinfo;
	char statpath[MAX_TNFSPATH];

	// Free any existing entries
	dirlist_free(dirh->entry_list);
	dirh->entry_count = 0;

	if ((dirh->handle = opendir(dirh->path)) == NULL)
		return errno;

	while ((entry = readdir(dirh->handle)) != NULL)
	{
		// Create a new directory_entry_node to add to our list
		directory_entry_list_node *node = calloc(1, sizeof(directory_entry_list_node));

		// Copy the name into the node
		strlcpy(node->entry.entrypath, entry->d_name, MAX_FILENAME_LEN);

		// Try to stat the file and copy that data into the node
		snprintf(statpath, sizeof(statpath), "%s%c%s", dirh->path, PATH_SEP, entry->d_name);
		if (stat(statpath, &statinfo) == 0)
		{
			node->entry.size = statinfo.st_size;
			node->entry.mtime = statinfo.st_mtime;
			node->entry.ctime = statinfo.st_ctime;

			if (S_ISDIR(statinfo.st_mode))
			{
				node->entry.flags |= TNFS_DIRENTRY_DIR;
			}
		}

		// Add this node to our list
		dirlist_push(&(dirh->entry_list), node);
		dirh->entry_count++;

#ifdef DEBUG
		fprintf(stderr, "_load_directory added \"%s\" %u\n", node->entry.entrypath, node->entry.size);
#endif
	}
#ifdef DEBUG
		fprintf(stderr, "_load_directory count = %hu\n", dirh->entry_count);
#endif
		dirlist_sort(&dirh->entry_list);
#ifdef DEBUG
		fprintf(stderr, "POST SORT LIST:\n");
		directory_entry_list _dl = dirh->entry_list;
		while(_dl)
		{
			fprintf(stderr, "\t%s\n", _dl->entry.entrypath);
			_dl = _dl->next;
		}
#endif
	dirh->current_entry = dirh->entry_list;

	return 0;
}

/* Open a directory with additional options */
void tnfs_opendirx(Header *hdr, Session *s, unsigned char *databuf, int datasz)
{
	char path[MAX_TNFSPATH];
	unsigned char reply[5];
	int i;
	uint8_t result;

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
	fprintf(stderr, "opendirx: %s\n", databuf);
#endif

	/* find the first available slot in the session */
	for (i = 0; i < MAX_DHND_PER_CONN; i++)
	{
		if (s->dhandles[i].handle == NULL)
		{
			snprintf(path, MAX_TNFSPATH, "%s/%s/%s",
					 root, s->root, databuf);
			normalize_path(s->dhandles[i].path, path, MAX_TNFSPATH);

			result = _load_directory(&(s->dhandles[i]));
			if (result == 0)
			{
				/* send OK response */
				hdr->status = TNFS_SUCCESS;
				reply[0] = (unsigned char)i;
				uint32tnfs(reply + 1, s->dhandles[i].entry_count);
				tnfs_send(s, hdr, reply, 5);
			}
			else
			{
				hdr->status = tnfs_error(result);
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

void dirlist_push(directory_entry_list *dlist, directory_entry_list_node *node)
{
	if (dlist == NULL || node == NULL)
		return;

	// This entry becomes the head, any current head becomes the second node
	node->next = *dlist;
	*dlist = node;
}

/* Returns poitner to node at index given or NULL if no such index */
directory_entry_list_node * dirlist_get_node_at_index(directory_entry_list dlist, uint32_t index)
{
	uint32_t i = 0;
	while (dlist && i++ < index)
		dlist = dlist->next;

	return dlist;
}

/* Returns poitner to node at index given or NULL if no such index */
uint32_t dirlist_get_index_for_node(directory_entry_list dlist, directory_entry_list_node *node)
{
	uint32_t i = 0;
	while (dlist)
	{
		if(dlist == node)
			break;
		dlist = dlist->next;
		i++;
	}

	return i;
}

/* Free the linked list of directory entries */
void dirlist_free(directory_entry_list dlist)
{
	while (dlist)
	{
		directory_entry_list_node *next = dlist->next;
		free(dlist);
		dlist = next;
	}
}

directory_entry_list _mergesort_merge(directory_entry_list list_left, directory_entry_list list_right)
{
	if(list_left == NULL)
		return list_right;
	if(list_right == NULL)
		return list_left;

	directory_entry_list result;
	if(strcmp(list_left->entry.entrypath, list_right->entry.entrypath) < 0)
	{
		result = list_left;
		result->next = _mergesort_merge(list_left->next, list_right);
	}
	else
	{
		result = list_right;
		result->next = _mergesort_merge(list_left, list_right->next);
	}

	return result;
}

directory_entry_list _mergesort_get_middle(directory_entry_list head)
{
    if(head == NULL)
		return head;

	directory_entry_list slow, fast;
	slow = fast = head;

    while(fast->next != NULL && fast->next->next != NULL)
    {
        slow = slow->next;
        fast = fast->next->next;
    }
    return slow;
}

void _mergesort(directory_entry_list *headP)
{
	directory_entry_list head = *headP;

	if(head == NULL || head->next == NULL)
		return;

	directory_entry_list list_left;
	directory_entry_list list_right;
	directory_entry_list list_mid;

	// Split the list into two separate lists
	list_left = head;
	list_mid = _mergesort_get_middle(head);
	list_right = list_mid->next;
	list_mid->next = NULL;

	// Merge the two lists
	_mergesort(&list_left);
	_mergesort(&list_right);
	*headP =  _mergesort_merge(list_left, list_right);
}

/* Merge sort on a singly-linked list */
void dirlist_sort(directory_entry_list *dlist)
{
	_mergesort(dlist);
}
