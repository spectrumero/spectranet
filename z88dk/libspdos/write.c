#include <fcntl.h>

ssize_t write(int handle, void *buf, size_t len) __naked
{
#asm
    include "spectranet.asm"

    push    ix
    
    ld      ix,4
    add     ix,sp
    
    ; Get len
    ld      c,(ix+0)
    ld      b,(ix+1)
    
    ; Get buf
    ld      l,(ix+2)
    ld      h,(ix+3)

    ; Get handle
    ld      a,(ix+4)
    
    ; VFS WRITE: A=handle, HL=buf, BC=size
    call    WRITE

    pop     ix
    
    ; BC contains bytes written on success
    jr      c,error
    ld      h,b
    ld      l,c
    ret
    
error:
    ld      hl,-1
    ret
#endasm
}

