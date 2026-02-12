#include <fcntl.h>

char *getcwd(char *buf, size_t buflen) __naked
{
#asm
    include "spectranet.asm"
    
    pop     bc
    pop     de      ; buflen (ignored)
    pop     hl      ; buf
    push    hl
    push    de
    push    bc
    
    push    hl      ; save buf for return value
    push    ix
    ; VFS GETCWD: DE = pointer to buffer
    ex      de,hl   ; DE = buf
    call    GETCWD
    pop     ix
    pop     hl      ; return buf pointer
    
    jr      c,error
    ; Return buf pointer in HL
    ret
    
error:
    ld      hl,0    ; return NULL on error
    ret
#endasm
}

