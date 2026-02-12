#include <fcntl.h>

ssize_t read(int handle, void *buf, size_t len) __naked
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
    ex      de,hl   ; DE = buf (for VFS)
    
    ; Get handle
    ld      a,(ix+4)
    
    ; VFS READ: A=handle, DE=buf, BC=len
    call    READ
    ; BC contains bytes read on success or EOF
    ; Check carry flag - but EOF may set carry even though bytes were read
    jr      nc,success
    ; Carry is set - check if BC > 0 (EOF with data) or BC == 0 (error)
    ld      a,b
    or      c       ; Check if BC is zero
    jr      z,error ; BC == 0 means error
    ; BC > 0 means EOF with data - treat as success
success:
    pop     ix
    ld      h,b
    ld      l,c
    ret
    
error:
    pop     ix
    ld      hl,-1
    ret
#endasm
}

