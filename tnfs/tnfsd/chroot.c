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
 * Drops root privileges and chroots to the given directory.
 *
 * */

#ifdef ENABLE_CHROOT
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <pwd.h>
#include <grp.h>

#include "chroot.h"

void chroot_tnfs(const char *user, const char *group, const char *newroot)
{
	struct passwd *pwd;
	struct group *grp;

	/* Get the UID and GID of passed user and group */
	pwd=getpwnam(user);
	if(pwd == NULL)
	{
		perror("getpwnam");
		exit(-1);
	}

	grp=getgrnam(group);
	if(grp == NULL)
	{
		perror("getgrnam");
		exit(-1);
	}

	/* Do the chroot */
	if(chroot(newroot) == -1)
	{
		perror("chroot");
		exit(-1);
	}

	/* drop the group privileges first */
	if(setgid(grp->gr_gid) == -1)
	{
		perror("setgid");
		exit(-1);
	}

	/* Finally drop user privileges */
	if(setuid(pwd->pw_uid) == -1)
	{
		perror("setuid");
		exit(-1);
	}
}

void warn_if_root(void)
{
	if((getuid() == 0) | (getgid() == 0))
		fprintf(stderr, "WARNING: running as root.\nConsider running tnfsd jailed with -u user -g group\n");
}
#endif

