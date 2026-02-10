#include <fcntl.h>

int rename(const char *s, const char *d) __naked
{
#asm
    include "spectranet.asm"
    
    pop     bc
    pop     de      ; destination
    pop     hl      ; source
    push    hl
    push    de
    push    bc
    
    push    ix
    ; VFS RENAME: HL = source path, DE = destination path
    call    RENAME
    pop     ix
    
    jr      c,error
    ld      hl,0
    ret
    
error:
    ld      hl,-1
    ret
#endasm
}

