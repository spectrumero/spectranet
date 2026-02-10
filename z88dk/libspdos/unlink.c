#include <fcntl.h>

int unlink(char *name) __naked
{
#asm
    include "spectranet.asm"
    
    pop     bc
    pop     hl
    push    hl
    push    bc
    
    push    ix
    ; VFS UNLINK: HL = filename
    call    UNLINK
    pop     ix
    
    jr      c,error
    ld      hl,0
    ret
    
error:
    ld      hl,-1
    ret
#endasm
}

