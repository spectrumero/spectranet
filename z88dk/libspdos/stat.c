#include <fcntl.h>
#include <sys/stat.h>
#include "spdos.h"

int stat(const char* path, struct stat* buf) __naked
{
#asm
    include "../../include/spectranet.inc"
    
    push    ix
    ld      ix,4
    add     ix,sp
    
    ; Stack: [saved IX][ret][buf][path]
    ; Parameters: buf at (ix+0), path at (ix+2)
    ; Note: Parameters are pushed right-to-left, so path (rightmost) is pushed first,
    ;       then buf (leftmost) is pushed second, making buf at lower offset
    
    ; Get buf pointer (first parameter)
    ld      e,(ix+0)
    ld      d,(ix+1)
    
    ; Get path pointer (second parameter)
    ld      l,(ix+2)
    ld      h,(ix+3)
    
    ; STAT: HL = path, DE = buffer for stat info
    ; Returns: C set on error, Z set on error, C reset and Z reset on success
    call    STAT
    
    jr      c,stat_error
    jr      z,stat_error
    
    ; Success - stat info is now in buffer pointed to by DE
    ; The caller can access it via the buf pointer
    ld      hl,0
    jr      stat_end
    
stat_error:
    ld      hl,-1
    
stat_end:
    pop     ix
    ret
#endasm
}

// Helper function to check if a path is a directory
int isdir(const char* path)
{
    // Allocate buffer for stat info (256 bytes as per VFS spec)
    static unsigned char statbuf[256];
    struct stat* st = (struct stat*)statbuf;
    
    if (stat(path, st) < 0) {
        return 0;
    }
    
    // Check if directory bit is set in mode
    // STAT_MODE is at offset 0, little-endian 16-bit value
    unsigned short mode = *(unsigned short*)statbuf;
    return (mode & S_IFDIR) != 0;
}
