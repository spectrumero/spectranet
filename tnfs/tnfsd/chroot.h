#ifndef CHROOT_H
#define CHROOT_H

#ifdef ENABLE_CHROOT
/* Allows the tnfsd to assume a new uid and root */
void chroot_tnfs(const char *user, const char *group, const char *newroot);

/* Emit scary warning if run as root */
void warn_if_root(void);
#endif

#endif

