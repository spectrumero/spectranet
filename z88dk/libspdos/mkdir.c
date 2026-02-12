#include <fcntl.h>

int mkdir(char *name) __naked
{
#asm
    include "spectranet.asm"
    
    pop     bc
    pop     hl
    push    hl
    push    bc
    
    push    ix
    ; VFS MKDIR: HL = directory name
    call    MKDIR
    pop     ix
    
    jr      c,error
    ld      hl,0
    ret
    
error:
    ld      hl,-1
    ret
#endasm
}

