#include <fcntl.h>

int opendir(char *name) __naked
{
#asm
    include "spectranet.asm"
    
    pop     bc
    pop     hl
    push    hl
    push    bc
    
    push    ix
    ; VFS OPENDIR: HL = directory name
    call    OPENDIR
    pop     ix
    
    jr      c,error
    ld      h,0
    ld      l,a     ; return directory handle
    ret
    
error:
    ld      hl,-1
    ret
#endasm
}

