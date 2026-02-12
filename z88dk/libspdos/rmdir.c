#include <fcntl.h>

int rmdir(char *name) __naked
{
#asm
    include "spectranet.asm"
    
    pop     bc
    pop     hl
    push    hl
    push    bc
    
    push    ix
    ; VFS RMDIR: HL = directory name
    call    RMDIR
    pop     ix
    
    jr      c,error
    ld      hl,0
    ret
    
error:
    ld      hl,-1
    ret
#endasm
}

