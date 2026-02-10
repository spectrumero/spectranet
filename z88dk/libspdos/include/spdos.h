#ifndef SPDOS_H
#define SPDOS_H

#include <fcntl.h>
#include <sys/types.h>

/* DOS-compatible filesystem functions forwarding to Spectranet VFS */

/* Undefine system macros that conflict with our function declarations */
#ifdef mkdir
#undef mkdir
#endif
#ifdef rmdir
#undef rmdir
#endif

/* File operations */
int open(const char *name, int flags, mode_t mode);
int close(int handle);
ssize_t read(int handle, void *buf, size_t len);
ssize_t write(int handle, void *buf, size_t len);
int readbyte(int fd);
int writebyte(int handle, int c);
long lseek(int fd, long posn, int whence);

/* Directory operations */
int mkdir(char *name);
int rmdir(char *name);
int chdir(char *name);
char *getcwd(char *buf, size_t buflen);

/* File management */
int rename(const char *s, const char *d);
int remove(char *name);
int unlink(char *name);

/* Directory reading */
int opendir(char *name);
int readdir(int dirhandle, void *buf);
int closedir(int dirhandle);

/* File status */
/* File mode constants (Spectranet VFS) */
#ifndef S_IFDIR
#define S_IFDIR 0x4000
#endif
#ifndef S_IFREG
#define S_IFREG 0x8000
#endif

/* Mount operations (Spectranet-specific) */
/**
 * Mount a filesystem at the specified mount point.
 * Note: if the mount point is already in use, the mount will fail.
 * To use a different mount point, you must first unmount the filesystem
 * using umount().
 * 
 * @param mount_point Mount point number (0-3)
 * @param password Password string (can be NULL for anonymous access)
 * @param user_id User ID string (can be NULL for anonymous access)
 * @param path Mount source path (e.g., "/home/tnfs" or "ram")
 * @param hostname Hostname or server address (e.g., "remote.domain" or NULL)
 * @param protocol Protocol name (e.g., "tnfs", "xfs", "https")
 * 
 * @return 0 on success, -1 on error
 * 
 * @example
 * // Mount TNFS filesystem
 * mount(0, NULL, NULL, "/home/tnfs", "remote.domain", "tnfs");
 * 
 * // Mount XFS RAM filesystem
 * mount(0, NULL, NULL, "ram", NULL, "xfs");
 * 
 * // Mount with authentication
 * mount(0, "mypassword", "myuser", "/home/tnfs", "remote.domain", "tnfs");
 */
int mount(int mount_point, char* password, char* user_id, char* path, char* hostname, char *protocol);
int umount(int mount_point);

/* File status */
int stat(const char *path, struct stat *buf);
/* Check if a path is a directory */
int isdir(const char *path);


int setmountpoint(int mount_point);
int getmountpoint(void);

#endif /* SPDOS_H */

