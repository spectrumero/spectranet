#include <fcntl.h>

int chdir(char *name) __naked
{
#asm
    include "spectranet.asm"
    
    pop     bc
    pop     hl
    push    hl
    push    bc
    
    push    ix
    ; VFS CHDIR: HL = directory name
    call    CHDIR
    pop     ix
    
    jr      c,error
    ld      hl,0
    ret
    
error:
    ld      hl,-1
    ret
#endasm
}

